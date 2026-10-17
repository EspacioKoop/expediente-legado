#!/usr/bin/env python3
"""Pruebas unitarias para las funciones de comandos públicas de ci_brain.py.

Prueba comportamiento observable (valores de retorno, excepciones, registros en DB,
ficheros escritos y salida JSON) de:
- remember_command(args: argparse.Namespace) -> int
- recall(args: argparse.Namespace) -> int
- context_command(args: argparse.Namespace) -> int
- restore_command(args: argparse.Namespace) -> int
"""

from argparse import Namespace
import contextlib
from datetime import datetime, timedelta, timezone
import io
import json
import os
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest.mock import patch

from scripts.ci_brain import (
    connect,
    context_command,
    iso,
    recall,
    remember,
    remember_command,
    restore_command,
    utc_now,
)


class TestRememberCommand(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.tmpdir.name) / "test_ci_brain.sqlite3"

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_remember_command_exito_sin_ttl(self) -> None:
        args = Namespace(
            sqlite=str(self.db_path),
            kind="nota_tecnica",
            key="config_pipeline",
            summary="Ajuste de timeout en pipeline",
            metadata=json.dumps({"autor": "test_runner", "version": 1}),
            ttl_days=None,
        )
        ret = remember_command(args)
        self.assertEqual(ret, 0)

        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            row = conn.execute(
                "SELECT kind, memory_key, summary, metadata_json, expires_at FROM memory_entries WHERE memory_key = ?",
                ("config_pipeline",),
            ).fetchone()
            self.assertIsNotNone(row)
            self.assertEqual(row["kind"], "nota_tecnica")
            self.assertEqual(row["summary"], "Ajuste de timeout en pipeline")
            self.assertEqual(json.loads(row["metadata_json"]), {"autor": "test_runner", "version": 1})
            self.assertIsNone(row["expires_at"])
        finally:
            conn.close()

    def test_remember_command_exito_con_ttl(self) -> None:
        args = Namespace(
            sqlite=str(self.db_path),
            kind="alerta",
            key="fallo_memoria",
            summary="Alerta de consumo de memoria",
            metadata="{}",
            ttl_days=14,
        )
        ret = remember_command(args)
        self.assertEqual(ret, 0)

        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            row = conn.execute(
                "SELECT expires_at FROM memory_entries WHERE memory_key = ?",
                ("fallo_memoria",),
            ).fetchone()
            self.assertIsNotNone(row)
            self.assertIsNotNone(row["expires_at"])
            expires_dt = datetime.fromisoformat(row["expires_at"].replace("Z", "+00:00"))
            self.assertGreater(expires_dt, utc_now())
        finally:
            conn.close()

    def test_remember_command_metadata_json_invalido(self) -> None:
        args = Namespace(
            sqlite=str(self.db_path),
            kind="nota",
            key="clave_error",
            summary="Resumen de prueba",
            metadata="{json_invalido: true}",
            ttl_days=None,
        )
        with self.assertRaises(json.JSONDecodeError):
            remember_command(args)

    def test_remember_command_validacion_argumentos_vacios(self) -> None:
        args = Namespace(
            sqlite=str(self.db_path),
            kind="",
            key="clave",
            summary="Resumen",
            metadata="{}",
            ttl_days=None,
        )
        with self.assertRaises(ValueError):
            remember_command(args)


class TestRecallCommand(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.tmpdir.name) / "test_ci_brain.sqlite3"
        self.conn = connect(self.db_path)

    def tearDown(self) -> None:
        self.conn.close()
        self.tmpdir.cleanup()

    def test_recall_encuentra_coincidencias(self) -> None:
        remember(
            self.conn,
            kind="falla_ci",
            key="job_test_failure",
            summary="Fallo intermitente en pruebas unitarias",
            metadata={"job_id": 101},
        )
        remember(
            self.conn,
            kind="falla_ci",
            key="job_build_failure",
            summary="Error de compilacion en artifact",
            metadata={"job_id": 102},
        )
        self.conn.commit()

        args = Namespace(
            sqlite=str(self.db_path),
            query="compilacion",
            limit=10,
        )
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            ret = recall(args)

        self.assertEqual(ret, 0)
        data = json.loads(buf.getvalue())
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]["memory_key"], "job_build_failure")
        self.assertEqual(data[0]["metadata"], {"job_id": 102})

    def test_recall_ignora_entradas_expiradas(self) -> None:
        expirado = iso(utc_now() - timedelta(days=2))
        remember(
            self.conn,
            kind="alerta",
            key="alerta_vieja",
            summary="Alerta de prueba expirada",
            metadata={},
            expires_at=expirado,
        )
        remember(
            self.conn,
            kind="alerta",
            key="alerta_activa",
            summary="Alerta de prueba vigente",
            metadata={},
        )
        self.conn.commit()

        args = Namespace(
            sqlite=str(self.db_path),
            query="Alerta",
            limit=10,
        )
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            ret = recall(args)

        self.assertEqual(ret, 0)
        data = json.loads(buf.getvalue())
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]["memory_key"], "alerta_activa")

    def test_recall_sin_coincidencias(self) -> None:
        remember(
            self.conn,
            kind="nota",
            key="clave_unica",
            summary="Resumen sin coincidencia",
        )
        self.conn.commit()

        args = Namespace(
            sqlite=str(self.db_path),
            query="termino_inexistente",
            limit=10,
        )
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            ret = recall(args)

        self.assertEqual(ret, 0)
        data = json.loads(buf.getvalue())
        self.assertEqual(data, [])

    def test_recall_respeta_limite(self) -> None:
        for i in range(5):
            remember(
                self.conn,
                kind="log",
                key=f"item_{i}",
                summary=f"Log de evento repetido {i}",
            )
        self.conn.commit()

        args = Namespace(
            sqlite=str(self.db_path),
            query="evento",
            limit=2,
        )
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            ret = recall(args)

        self.assertEqual(ret, 0)
        data = json.loads(buf.getvalue())
        self.assertEqual(len(data), 2)


class TestContextCommand(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.tmpdir.name) / "test_ci_brain.sqlite3"
        self.conn = connect(self.db_path)
        remember(
            self.conn,
            kind="despliegue",
            key="prod_deploy",
            summary="Despliegue de produccion en servidor principal",
            metadata={"env": "prod"},
        )
        self.conn.commit()

    def tearDown(self) -> None:
        self.conn.close()
        self.tmpdir.cleanup()

    def test_context_command_codigo_retorno_y_escritura_output(self) -> None:
        out_file = Path(self.tmpdir.name) / "context_out.json"
        query_file = Path(self.tmpdir.name) / "query.txt"
        query_file.write_text("despliegue produccion", encoding="utf-8")

        args = Namespace(
            sqlite=str(self.db_path),
            query=None,
            query_file=str(query_file),
            paths_json=None,
            limit=5,
            output=str(out_file),
        )
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            ret = context_command(args)

        self.assertEqual(ret, 0)
        self.assertTrue(out_file.exists())
        written_content = out_file.read_text(encoding="utf-8")
        self.assertIn('"source": "ci-brain-sqlite"', written_content)

    def test_context_command_paths_json(self) -> None:
        paths_file = Path(self.tmpdir.name) / "paths.json"
        paths_file.write_text(json.dumps({"files": ["servidor/principal.py"]}), encoding="utf-8")

        args = Namespace(
            sqlite=str(self.db_path),
            query=None,
            query_file=None,
            paths_json=str(paths_file),
            limit=5,
            output=None,
        )
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            ret = context_command(args)

        self.assertEqual(ret, 0)
        self.assertIn("ci-brain-sqlite", buf.getvalue())

    def test_context_command_salida_json_valida(self) -> None:
        """Comprueba que la salida de context_command se pueda parsear con json.loads."""
        query_file = Path(self.tmpdir.name) / "query.txt"
        query_file.write_text("despliegue", encoding="utf-8")

        args = Namespace(
            sqlite=str(self.db_path),
            query=None,
            query_file=str(query_file),
            paths_json=None,
            limit=5,
            output=None,
        )
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            context_command(args)

        json.loads(buf.getvalue())

    def test_context_command_busqueda_por_argumento_query(self) -> None:
        """Comprueba que context_command encuentre memorias al pasar --query."""
        args = Namespace(
            sqlite=str(self.db_path),
            query="despliegue",
            query_file=None,
            paths_json=None,
            limit=5,
            output=None,
        )
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            context_command(args)

        # Limpiamos el '\\n' literal para poder parsear el JSON y comprobar que recupero la memoria
        raw = buf.getvalue().rstrip("\\n\r\n")
        parsed = json.loads(raw)
        self.assertGreater(len(parsed.get("memories", [])), 0)


class TestRestoreCommand(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.tmpdir.name) / "test_ci_brain.sqlite3"

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_restore_command_sin_token(self) -> None:
        args = Namespace(
            sqlite=str(self.db_path),
            repo="owner/repo",
            workflow="ci-brain.yml",
        )
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(SystemExit) as ctx:
                restore_command(args)
            self.assertIn("falta GH_TOKEN/GITHUB_TOKEN", str(ctx.exception))

    def test_restore_command_sin_repo(self) -> None:
        args = Namespace(
            sqlite=str(self.db_path),
            repo=None,
            workflow="ci-brain.yml",
        )
        with patch.dict(os.environ, {"GH_TOKEN": "token_falso"}, clear=True):
            with self.assertRaises(SystemExit) as ctx:
                restore_command(args)
            self.assertIn("falta --repo", str(ctx.exception))

    def test_restore_command_exito(self) -> None:
        args = Namespace(
            sqlite=str(self.db_path),
            repo="mi_usuario/mi_repo",
            workflow="ci-brain.yml",
        )
        with patch.dict(os.environ, {"GH_TOKEN": "token_prueba"}, clear=True):
            with patch("scripts.ci_brain.restore_latest_snapshot", return_value=123456) as mock_restore:
                buf = io.StringIO()
                with contextlib.redirect_stdout(buf):
                    ret = restore_command(args)

                self.assertEqual(ret, 0)
                mock_restore.assert_called_once_with(
                    self.db_path,
                    repo="mi_usuario/mi_repo",
                    token="token_prueba",
                    workflow="ci-brain.yml",
                )
                output = json.loads(buf.getvalue().strip())
                self.assertEqual(output, {"restored": True, "run_id": 123456})

    def test_restore_command_sin_snapshot(self) -> None:
        args = Namespace(
            sqlite=str(self.db_path),
            repo="mi_usuario/mi_repo",
            workflow="ci-brain.yml",
        )
        with patch.dict(os.environ, {"GH_TOKEN": "token_prueba"}, clear=True):
            with patch("scripts.ci_brain.restore_latest_snapshot", return_value=None):
                buf = io.StringIO()
                with contextlib.redirect_stdout(buf):
                    ret = restore_command(args)

                self.assertEqual(ret, 1)
                output = json.loads(buf.getvalue().strip())
                self.assertEqual(output, {"restored": False})


if __name__ == "__main__":
    unittest.main()
