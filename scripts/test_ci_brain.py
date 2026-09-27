import importlib.util
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "ci_brain.py"
SCHEMA = ROOT / "infra" / "ci-brain" / "schema.sql"
WORKFLOW = ROOT / ".github" / "workflows" / "ci-brain.yml"


def cargar():
    spec = importlib.util.spec_from_file_location("ci_brain", SCRIPT)
    modulo = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(modulo)
    return modulo


class CiBrainTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.mod = cargar()

    def test_esquema_es_compacto_y_tiene_memoria(self):
        texto = SCHEMA.read_text(encoding="utf-8")
        self.assertIn("CREATE TABLE IF NOT EXISTS ci_runs", texto)
        self.assertIn("CREATE TABLE IF NOT EXISTS ci_jobs", texto)
        self.assertIn("CREATE TABLE IF NOT EXISTS memory_entries", texto)
        self.assertNotIn("logs", texto.lower())
        self.assertNotIn("artifact", texto.lower())

    def test_ingesta_local_es_idempotente_y_resume(self):
        with tempfile.TemporaryDirectory() as td:
            db = Path(td) / "brain.sqlite3"
            conn = self.mod.connect(db)
            run = {
                "id": 10,
                "name": "CI",
                "workflow_id": 1,
                "head_sha": "abc",
                "head_branch": "feature/x",
                "event": "pull_request",
                "conclusion": "failure",
                "run_attempt": 1,
                "created_at": "2026-09-27T10:00:00Z",
                "run_started_at": "2026-09-27T10:00:10Z",
                "updated_at": "2026-09-27T10:01:10Z",
                "html_url": "https://github.test/run/10",
            }
            job = {
                "id": 20,
                "name": "gdscript",
                "conclusion": "failure",
                "started_at": "2026-09-27T10:00:20Z",
                "completed_at": "2026-09-27T10:01:00Z",
                "html_url": "https://github.test/job/20",
            }
            conn.execute(self.mod.RUN_SQL, self.mod.normalize_run(run))
            conn.execute(self.mod.RUN_SQL, self.mod.normalize_run(run))
            conn.execute(self.mod.JOB_SQL, self.mod.normalize_job(run, job))
            conn.execute(self.mod.JOB_SQL, self.mod.normalize_job(run, job))
            conn.commit()
            self.assertEqual(1, conn.execute("SELECT COUNT(*) FROM ci_runs").fetchone()[0])
            self.assertEqual(1, conn.execute("SELECT COUNT(*) FROM ci_jobs").fetchone()[0])
            resumen = self.mod.build_summary(conn)
            conn.close()
            self.assertEqual(1, resumen["runs"])
            self.assertEqual(1, resumen["failures"])
            self.assertEqual("CI", resumen["workflows"][0]["workflow"])
            self.assertEqual(60.0, resumen["workflows"][0]["median_seconds"])

    def test_memoria_tiene_limites_y_recall_es_sqlite(self):
        with tempfile.TemporaryDirectory() as td:
            db = Path(td) / "brain.sqlite3"
            conn = self.mod.connect(db)
            self.mod.remember(
                conn,
                kind="ci_failure",
                key="CI::gdscript",
                summary="gdformat falló dos veces",
                metadata={"issue": 123},
            )
            conn.commit()
            row = conn.execute(
                "SELECT summary, metadata_json FROM memory_entries WHERE memory_key=?",
                ("CI::gdscript",),
            ).fetchone()
            conn.close()
            self.assertEqual("gdformat falló dos veces", row["summary"])
            self.assertEqual(123, json.loads(row["metadata_json"])["issue"])
            with self.assertRaises(ValueError):
                conn = self.mod.connect(db)
                try:
                    self.mod.remember(conn, kind="x", key="y", summary="x" * 2001)
                finally:
                    conn.close()

    def test_url_turso_se_convierte_a_pipeline_https(self):
        self.assertEqual(
            "https://siga98-org.turso.io/v2/pipeline",
            self.mod.turso_endpoint("libsql://siga98-org.turso.io"),
        )
        self.assertEqual(
            "https://siga98-org.turso.io/v2/pipeline",
            self.mod.turso_endpoint("https://siga98-org.turso.io"),
        )
        with self.assertRaises(ValueError):
            self.mod.turso_endpoint("http://siga98.invalid")

    def test_hrana_serializa_enteros_sin_perder_precision(self):
        self.assertEqual({"type": "integer", "value": "42"}, self.mod.hrana_value(42))
        self.assertEqual({"type": "null"}, self.mod.hrana_value(None))
        self.assertEqual({"type": "text", "value": "hola"}, self.mod.hrana_value("hola"))

    def test_workflow_es_programado_opt_in_y_guarda_snapshot(self):
        texto = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("schedule:", texto)
        self.assertIn("actions: read", texto)
        self.assertIn("python3 scripts/ci_brain.py collect", texto)
        self.assertIn("gh run download", texto)
        self.assertIn("ci-brain.sqlite3", texto)
        self.assertIn("python3 scripts/ci_brain.py sync-turso", texto)
        self.assertIn("vars.TURSO_DATABASE_URL", texto)
        self.assertIn("secrets.TURSO_AUTH_TOKEN", texto)
        self.assertIn("actions/upload-artifact@v4", texto)
        self.assertNotIn("pull_request:", texto)


if __name__ == "__main__":
    unittest.main()
