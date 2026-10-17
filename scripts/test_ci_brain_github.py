import importlib.util
import io
import json
import tempfile
import unittest
import urllib.error
import zipfile
from pathlib import Path
from unittest.mock import MagicMock, patch

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "ci_brain.py"


def cargar():
    spec = importlib.util.spec_from_file_location("ci_brain", SCRIPT)
    modulo = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(modulo)
    return modulo


class MockResponse:
    def __init__(self, data: bytes, status: int = 200):
        self._bio = io.BytesIO(data)
        self.status = status
        self.code = status

    def read(self, *args, **kwargs):
        return self._bio.read(*args, **kwargs)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        pass


class CiBrainGithubTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mod = cargar()

    def test_github_json_exito(self):
        datos_esperados = {"id": 123, "name": "test-workflow"}
        cuerpo = json.dumps(datos_esperados).encode("utf-8")
        mock_resp = MockResponse(cuerpo)

        with patch("urllib.request.urlopen", return_value=mock_resp) as mock_urlopen:
            res = self.mod.github_json("https://api.github.com/test", "token-sintetico")

        self.assertEqual(res, datos_esperados)
        mock_urlopen.assert_called_once()
        req = mock_urlopen.call_args[0][0]
        self.assertEqual(req.full_url, "https://api.github.com/test")
        self.assertEqual(req.headers["Accept"], "application/vnd.github+json")
        self.assertEqual(req.headers["Authorization"], "Bearer token-sintetico")
        self.assertEqual(req.headers["User-agent"], self.mod.USER_AGENT)
        self.assertEqual(req.headers["X-github-api-version"], "2022-11-28")

    def test_github_json_error_404(self):
        error_404 = urllib.error.HTTPError(
            "https://api.github.com/test",
            404,
            "Not Found",
            {},
            io.BytesIO(b"Recurso no encontrado"),
        )
        with patch("urllib.request.urlopen", side_effect=error_404):
            with self.assertRaises(RuntimeError) as cm:
                self.mod.github_json("https://api.github.com/test", "token-sintetico")

        self.assertIn("GitHub API 404: Recurso no encontrado", str(cm.exception))

    def test_github_json_error_500(self):
        error_500 = urllib.error.HTTPError(
            "https://api.github.com/test",
            500,
            "Internal Server Error",
            {},
            io.BytesIO(b"Fallo interno del servidor"),
        )
        with patch("urllib.request.urlopen", side_effect=error_500):
            with self.assertRaises(RuntimeError) as cm:
                self.mod.github_json("https://api.github.com/test", "token-sintetico")

        self.assertIn("GitHub API 500: Fallo interno del servidor", str(cm.exception))

    def test_github_bytes_exito(self):
        contenido_binario = b"bytes_sinteticos_\x00\x01\x02"
        mock_resp = MockResponse(contenido_binario)
        mock_opener = MagicMock()
        mock_opener.open.return_value = mock_resp

        with patch("urllib.request.build_opener", return_value=mock_opener):
            res = self.mod.github_bytes("https://api.github.com/bytes", "token-sintetico")

        self.assertEqual(res, contenido_binario)
        mock_opener.open.assert_called_once()
        req = mock_opener.open.call_args[0][0]
        self.assertEqual(req.full_url, "https://api.github.com/bytes")
        self.assertEqual(req.headers["Accept"], "application/vnd.github+json")
        self.assertEqual(req.headers["Authorization"], "Bearer token-sintetico")
        self.assertEqual(req.headers["User-agent"], self.mod.USER_AGENT)
        self.assertEqual(req.headers["X-github-api-version"], "2022-11-28")

    def test_github_bytes_error_http(self):
        error_403 = urllib.error.HTTPError(
            "https://api.github.com/bytes",
            403,
            "Forbidden",
            {},
            io.BytesIO(b"Acceso denegado"),
        )
        mock_opener = MagicMock()
        mock_opener.open.side_effect = error_403

        with patch("urllib.request.build_opener", return_value=mock_opener):
            with self.assertRaises(RuntimeError) as cm:
                self.mod.github_bytes("https://api.github.com/bytes", "token-sintetico")

        self.assertIn("GitHub API 403: Acceso denegado", str(cm.exception))

    def test_github_text_exito(self):
        texto = "Hola Mundo Ñ \u2665"
        contenido = texto.encode("utf-8")

        with patch.object(self.mod, "github_bytes", return_value=contenido) as mock_gb:
            res = self.mod.github_text("https://api.github.com/text", "token-sintetico")

        self.assertEqual(res, texto)
        mock_gb.assert_called_once_with("https://api.github.com/text", "token-sintetico")

    def test_restore_latest_snapshot_exito(self):
        contenido_sqlite = b"SQLite format 3\x00contenido_sintetico_db"
        bio_zip = io.BytesIO()
        with zipfile.ZipFile(bio_zip, "w") as zf:
            zf.writestr("data/ci-brain.sqlite3", contenido_sqlite)
        payload_zip = bio_zip.getvalue()

        def mock_github_json(url, token):
            self.assertEqual(token, "token-sintetico")
            if "/actions/workflows/" in url:
                return {
                    "workflow_runs": [
                        {"id": 99999, "status": "success", "head_branch": "main"}
                    ]
                }
            if "/actions/runs/99999/artifacts" in url:
                return {
                    "artifacts": [
                        {
                            "name": "ci-brain-99999",
                            "expired": False,
                            "archive_download_url": "https://api.github.com/repos/org/repo/actions/artifacts/1/zip",
                        }
                    ]
                }
            return {}

        def mock_github_bytes(url, token):
            self.assertEqual(token, "token-sintetico")
            self.assertEqual(
                url, "https://api.github.com/repos/org/repo/actions/artifacts/1/zip"
            )
            return payload_zip

        with patch.object(self.mod, "github_json", side_effect=mock_github_json), \
             patch.object(self.mod, "github_bytes", side_effect=mock_github_bytes):
            with tempfile.TemporaryDirectory() as td:
                destino = Path(td) / "subdirectorio" / "brain.sqlite3"
                run_id = self.mod.restore_latest_snapshot(
                    destino,
                    repo="org/repo",
                    token="token-sintetico",
                    workflow="ci-brain.yml",
                )

                self.assertEqual(run_id, 99999)
                self.assertTrue(destino.exists())
                self.assertEqual(destino.read_bytes(), contenido_sqlite)
                # Verifica que escribió exactamente dentro del directorio temporal destino
                self.assertTrue(destino.resolve().is_relative_to(Path(td).resolve()))

    def test_restore_latest_snapshot_sin_runs_o_artefactos(self):
        with patch.object(self.mod, "github_json", return_value={"workflow_runs": []}):
            with tempfile.TemporaryDirectory() as td:
                destino = Path(td) / "brain.sqlite3"
                run_id = self.mod.restore_latest_snapshot(
                    destino,
                    repo="org/repo",
                    token="token-sintetico",
                )
                self.assertIsNone(run_id)
                self.assertFalse(destino.exists())

    def test_restore_latest_snapshot_artefacto_expirado_o_sin_sqlite(self):
        bio_zip = io.BytesIO()
        with zipfile.ZipFile(bio_zip, "w") as zf:
            zf.writestr("otro_archivo.txt", b"no sqlite")
        payload_zip = bio_zip.getvalue()

        def mock_github_json(url, token):
            if "/actions/workflows/" in url:
                return {"workflow_runs": [{"id": 888}]}
            if "/actions/runs/888/artifacts" in url:
                return {
                    "artifacts": [
                        {
                            "name": "ci-brain-888",
                            "expired": False,
                            "archive_download_url": "https://api.github.com/download/888",
                        }
                    ]
                }
            return {}

        with patch.object(self.mod, "github_json", side_effect=mock_github_json), \
             patch.object(self.mod, "github_bytes", return_value=payload_zip):
            with tempfile.TemporaryDirectory() as td:
                destino = Path(td) / "brain.sqlite3"
                run_id = self.mod.restore_latest_snapshot(
                    destino,
                    repo="org/repo",
                    token="token-sintetico",
                )
                self.assertIsNone(run_id)
                self.assertFalse(destino.exists())


if __name__ == "__main__":
    unittest.main()
