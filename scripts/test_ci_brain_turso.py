import argparse
import copy
import json
import io
import os
import sqlite3
import tempfile
import unittest
import urllib.error
from pathlib import Path
from unittest.mock import patch, MagicMock

import scripts.ci_brain as cb


class TestCiBrainTurso(unittest.TestCase):
    def test_execute_request_formato_y_tipos(self):
        req_sin_args = cb.execute_request("SELECT 1;")
        self.assertEqual(
            req_sin_args,
            {
                "type": "execute",
                "stmt": {
                    "sql": "SELECT 1;",
                    "args": [],
                    "want_rows": False,
                },
            },
        )

        args = [42, "texto", True, None, 3.14]
        req_con_args = cb.execute_request("INSERT INTO test VALUES (?, ?, ?, ?, ?)", args)
        self.assertEqual(req_con_args["type"], "execute")
        self.assertEqual(req_con_args["stmt"]["sql"], "INSERT INTO test VALUES (?, ?, ?, ?, ?)")
        self.assertFalse(req_con_args["stmt"]["want_rows"])
        self.assertEqual(
            req_con_args["stmt"]["args"],
            [
                {"type": "integer", "value": "42"},
                {"type": "text", "value": "texto"},
                {"type": "integer", "value": "1"},
                {"type": "null"},
                {"type": "float", "value": 3.14},
            ],
        )

    @patch("urllib.request.urlopen")
    def test_turso_pipeline_envia_payload_y_cabeceras(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"results": [{"type": "ok"}]}).encode("utf-8")
        mock_response.__enter__.return_value = mock_response
        mock_urlopen.return_value = mock_response

        endpoint = "https://example.turso.io/v2/pipeline"
        token = "test-token-123"
        solicitudes = [{"type": "execute", "stmt": {"sql": "SELECT 1;", "args": [], "want_rows": False}}]

        cb.turso_pipeline(endpoint, token, solicitudes)

        mock_urlopen.assert_called_once()
        req = mock_urlopen.call_args[0][0]

        self.assertEqual(req.full_url, endpoint)
        self.assertEqual(req.get_method(), "POST")
        self.assertEqual(req.headers["Authorization"], "Bearer test-token-123")
        self.assertEqual(req.headers["Content-type"], "application/json")
        self.assertEqual(req.headers["User-agent"], cb.USER_AGENT)

        cuerpo = json.loads(req.data.decode("utf-8"))
        self.assertEqual(
            cuerpo,
            {
                "baton": None,
                "requests": [
                    {"type": "execute", "stmt": {"sql": "SELECT 1;", "args": [], "want_rows": False}},
                    {"type": "close"},
                ],
            },
        )

    @patch("urllib.request.urlopen")
    def test_turso_pipeline_manejo_error_http(self, mock_urlopen):
        error_fp = io.BytesIO(b"Error de autorizacion o base de datos no encontrada")
        http_error = urllib.error.HTTPError(
            url="https://example.turso.io/v2/pipeline",
            code=401,
            msg="Unauthorized",
            hdrs={},
            fp=error_fp,
        )
        mock_urlopen.side_effect = http_error

        with self.assertRaises(RuntimeError) as ctx:
            cb.turso_pipeline("https://example.turso.io/v2/pipeline", "invalid-token", [])

        self.assertIn("Turso HTTP 401:", str(ctx.exception))
        self.assertIn("Error de autorizacion", str(ctx.exception))

    @patch("urllib.request.urlopen")
    def test_turso_pipeline_manejo_error_resultado(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({
            "results": [
                {"type": "error", "error": {"message": "Sintaxis SQL invalida"}}
            ]
        }).encode("utf-8")
        mock_response.__enter__.return_value = mock_response
        mock_urlopen.return_value = mock_response

        with self.assertRaises(RuntimeError) as ctx:
            cb.turso_pipeline("https://example.turso.io/v2/pipeline", "token", [])

        self.assertIn("Turso rechazó pipeline: Sintaxis SQL invalida", str(ctx.exception))

    @patch("scripts.ci_brain.turso_pipeline")
    def test_sync_table_lotes_y_conteo(self, mock_pipeline):
        llamadas = []
        def side_effect(endpoint, token, requests):
            llamadas.append((endpoint, token, copy.deepcopy(requests)))
        mock_pipeline.side_effect = side_effect

        with tempfile.TemporaryDirectory() as td:
            db_path = Path(td) / "test.sqlite3"
            conn = sqlite3.connect(db_path)
            conn.row_factory = sqlite3.Row
            conn.execute("CREATE TABLE demo (id INT, nombre TEXT);")
            for i in range(55):
                conn.execute("INSERT INTO demo VALUES (?, ?);", (i, f"item_{i}"))
            conn.commit()

            endpoint = "https://example.turso.io/v2/pipeline"
            token = "token"
            cols = ["id", "nombre"]
            upsert_sql = "INSERT INTO demo VALUES (?, ?) ON CONFLICT DO NOTHING;"

            total_sincronizados = cb.sync_table(
                conn, endpoint, token, "demo", cols, upsert_sql
            )

            conn.close()

            self.assertEqual(total_sincronizados, 55)
            self.assertEqual(len(llamadas), 2)

            # Primer lote: 50 elementos
            lote_1 = llamadas[0][2]
            self.assertEqual(len(lote_1), 50)
            self.assertEqual(lote_1[0]["stmt"]["sql"], upsert_sql)
            self.assertEqual(lote_1[0]["stmt"]["args"][0], {"type": "integer", "value": "0"})

            # Segundo lote: 5 elementos restantes
            lote_2 = llamadas[1][2]
            self.assertEqual(len(lote_2), 5)

    def test_sync_turso_sin_credenciales_lanza_system_exit(self):
        args = argparse.Namespace(url=None, token=None, sqlite="dist/.cache/ci-brain.sqlite3")
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(SystemExit) as ctx:
                cb.sync_turso(args)
            self.assertEqual(str(ctx.exception), "faltan TURSO_DATABASE_URL y/o TURSO_AUTH_TOKEN")

    @patch("scripts.ci_brain.turso_pipeline")
    def test_sync_turso_flujo_completo(self, mock_pipeline):
        with tempfile.TemporaryDirectory() as td:
            db_path = Path(td) / "brain.sqlite3"
            conn = cb.connect(db_path)
            conn.execute(
                cb.RUN_SQL,
                (
                    101, "Workflow CI", 1, "sha123", "main", "push", "success",
                    1, "2026-10-17T10:00:00Z", "2026-10-17T10:05:00Z", 300.0, "https://github.test/run/101"
                ),
            )
            conn.commit()
            conn.close()

            args = argparse.Namespace(
                url="libsql://db-org.turso.io",
                token="auth-token-xyz",
                sqlite=str(db_path),
            )

            with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout:
                codigo_salida = cb.sync_turso(args)

            self.assertEqual(codigo_salida, 0)
            salida_json = json.loads(mock_stdout.getvalue())

            self.assertEqual(salida_json["endpoint"], "https://db-org.turso.io/v2/pipeline")
            self.assertEqual(salida_json["synced"]["ci_runs"], 1)
            self.assertEqual(salida_json["synced"]["ci_jobs"], 0)
            self.assertEqual(salida_json["synced"]["memory_entries"], 0)

            # Verificar llamadas a turso_pipeline:
            # 1ª llamada: esquema SQL
            # Siguientes llamadas: tablas (ci_runs, ci_jobs, memory_entries)
            self.assertGreaterEqual(mock_pipeline.call_count, 2)
            primera_llamada = mock_pipeline.call_args_list[0]
            self.assertEqual(primera_llamada[0][0], "https://db-org.turso.io/v2/pipeline")
            self.assertEqual(primera_llamada[0][1], "auth-token-xyz")
            self.assertEqual(primera_llamada[0][2][0]["type"], "sequence")


if __name__ == "__main__":
    unittest.main()
