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
AUTOPILOT = ROOT / ".github" / "workflows" / "agent-autopilot.yml"
REPAIR = ROOT / ".github" / "workflows" / "agent-ci-repair.yml"


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

    def test_fingerprint_normaliza_ruido_y_redacta_secretos(self):
        log_a = """2026-09-27T20:00:00Z ERROR scripts/foo.py:123:45 abcdef1234567890
2026-09-27T20:00:01Z AssertionError: sk-abcdefghijklmnopqrstuvwxyz
"""
        log_b = """2026-09-27T21:00:00Z ERROR scripts/foo.py:999:2 fedcba9876543210
2026-09-27T21:00:01Z AssertionError: sk-zyxwvutsrqponmlkjihgfedcba
"""
        firma_a = self.mod.normalize_failure_signature(log_a)
        firma_b = self.mod.normalize_failure_signature(log_b)
        self.assertEqual(firma_a, firma_b)
        self.assertEqual(
            "ERROR scripts/foo.py:<n> <sha>\nAssertionError: <redacted>",
            firma_a,
        )
        self.assertNotIn("2026-09-27", firma_a)
        self.assertNotIn("sk-", firma_a)
        self.assertIn("<redacted>", firma_a)
        self.assertEqual(
            self.mod.failure_fingerprint(firma_a),
            self.mod.failure_fingerprint(firma_b),
        )

    def test_muestra_de_fallo_es_idempotente_y_contexto_la_recupera(self):
        with tempfile.TemporaryDirectory() as td:
            db = Path(td) / "brain.sqlite3"
            conn = self.mod.connect(db)
            run = {
                "id": 11,
                "name": "CI",
                "updated_at": "2026-09-27T10:01:10Z",
            }
            job = {
                "id": 21,
                "name": "godot",
                "completed_at": "2026-09-27T10:01:00Z",
            }
            log = "ERROR gdformat: formato inesperado en scripts/test_demo.py:33"
            fp = self.mod.remember_failure_sample(
                conn, run, job, log, retention_days=120
            )
            self.mod.remember_failure_sample(
                conn, run, job, log, retention_days=120
            )
            self.mod.refresh_failure_fingerprint_memory(conn)
            conn.commit()
            self.assertEqual(
                1,
                conn.execute(
                    "SELECT COUNT(*) FROM memory_entries "
                    "WHERE kind='ci_failure_sample' AND memory_key='21'"
                ).fetchone()[0],
            )
            contexto = self.mod.build_memory_context(
                conn,
                "gdformat scripts/test_demo.py",
                ["scripts/test_demo.py"],
            )
            conn.close()
            self.assertTrue(fp)
            self.assertTrue(contexto["memories"])
            self.assertEqual(
                "ci_failure_fingerprint",
                contexto["memories"][0]["kind"],
            )

    def test_agentes_consumen_snapshot_historico_sin_hacerlo_autoritativo(self):
        autopilot = AUTOPILOT.read_text(encoding="utf-8")
        repair = REPAIR.read_text(encoding="utf-8")
        for workflow in (autopilot, repair):
            self.assertIn("scripts/ci_brain.py restore", workflow)
            self.assertIn("scripts/ci_brain.py context", workflow)
            self.assertIn(".agent-history.json", workflow)
            self.assertIn("memoria histórica", workflow)
        self.assertIn("--paths-json .agent-plan.json", autopilot)
        self.assertIn("--paths-json .agent-plan.json", repair)

    def test_redirect_de_artefacto_no_reenvia_authorization_a_otro_host(self):
        request = self.mod.urllib.request.Request(
            "https://api.github.com/repos/EspacioKoop/expediente-legado/actions/artifacts/1/zip",
            headers={
                "Authorization": "Bearer secreto",
                "User-Agent": self.mod.USER_AGENT,
            },
        )
        handler = self.mod._GithubSafeRedirectHandler()

        redirected = handler.redirect_request(
            request,
            None,
            302,
            "Found",
            {},
            "https://results-receiver.actions.githubusercontent.com/blob/signed.zip",
        )

        self.assertIsNotNone(redirected)
        self.assertIsNone(redirected.get_header("Authorization"))
        self.assertEqual(self.mod.USER_AGENT, redirected.get_header("User-agent"))

    def test_redirect_github_mismo_host_conserva_authorization(self):
        request = self.mod.urllib.request.Request(
            "https://api.github.com/repos/EspacioKoop/expediente-legado/actions/artifacts/1/zip",
            headers={"Authorization": "Bearer secreto"},
        )
        handler = self.mod._GithubSafeRedirectHandler()

        redirected = handler.redirect_request(
            request,
            None,
            302,
            "Found",
            {},
            "https://api.github.com/repos/EspacioKoop/expediente-legado/actions/artifacts/1/archive",
        )

        self.assertIsNotNone(redirected)
        self.assertEqual("Bearer secreto", redirected.get_header("Authorization"))

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
        # Fijado por SHA completo (#1819); el comentario conserva la versión. No
        # se exige una versión mayor concreta: Dependabot la sube (#1850).
        self.assertRegex(texto, r"actions/upload-artifact@[0-9a-f]{40} # v\d+")
        self.assertNotIn("pull_request:", texto)


if __name__ == "__main__":
    unittest.main()
