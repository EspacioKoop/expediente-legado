#!/usr/bin/env python3
"""Pruebas unitarias para las funciones prune y refresh_failure_memory de ci_brain."""

from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from datetime import timedelta
from pathlib import Path

from scripts.ci_brain import connect, iso, prune, refresh_failure_memory, utc_now


class TestCIBrainMemoria(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.temp_dir.name) / "ci_brain.sqlite3"
        self.conn = connect(self.db_path)

    def tearDown(self) -> None:
        self.conn.close()
        self.temp_dir.cleanup()

    def test_prune_elimina_runs_y_jobs_antiguos(self) -> None:
        now = utc_now()
        antiguo_date = iso(now - timedelta(days=150))
        reciente_date = iso(now - timedelta(days=10))

        # Insertar run y job antiguo
        self.conn.execute(
            """
            INSERT INTO ci_runs (run_id, workflow, updated_at)
            VALUES (?, ?, ?)
            """,
            (1, "workflow-antiguo", antiguo_date),
        )
        self.conn.execute(
            """
            INSERT INTO ci_jobs (job_id, run_id, workflow, name)
            VALUES (?, ?, ?, ?)
            """,
            (101, 1, "workflow-antiguo", "job-1"),
        )

        # Insertar run y job reciente
        self.conn.execute(
            """
            INSERT INTO ci_runs (run_id, workflow, updated_at)
            VALUES (?, ?, ?)
            """,
            (2, "workflow-reciente", reciente_date),
        )
        self.conn.execute(
            """
            INSERT INTO ci_jobs (job_id, run_id, workflow, name)
            VALUES (?, ?, ?, ?)
            """,
            (102, 2, "workflow-reciente", "job-2"),
        )
        self.conn.commit()

        prune(self.conn, days=120)

        runs = self.conn.execute("SELECT run_id FROM ci_runs").fetchall()
        jobs = self.conn.execute("SELECT job_id FROM ci_jobs").fetchall()

        self.assertEqual([r["run_id"] for r in runs], [2])
        self.assertEqual([j["job_id"] for j in jobs], [102])

    def test_prune_elimina_memorias_expiradas(self) -> None:
        now = utc_now()
        expirado = iso(now - timedelta(hours=1))
        valido = iso(now + timedelta(hours=24))
        creado = iso(now)

        # Insertar 3 entradas de memoria: expirada, valida y sin expiracion
        self.conn.execute(
            """
            INSERT INTO memory_entries (kind, memory_key, summary, metadata_json, created_at, updated_at, expires_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            ("test_kind", "expirada", "resumen 1", "{}", creado, creado, expirado),
        )
        self.conn.execute(
            """
            INSERT INTO memory_entries (kind, memory_key, summary, metadata_json, created_at, updated_at, expires_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            ("test_kind", "valida", "resumen 2", "{}", creado, creado, valido),
        )
        self.conn.execute(
            """
            INSERT INTO memory_entries (kind, memory_key, summary, metadata_json, created_at, updated_at, expires_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            ("test_kind", "eterna", "resumen 3", "{}", creado, creado, None),
        )
        self.conn.commit()

        prune(self.conn, days=120)

        rows = self.conn.execute(
            "SELECT memory_key FROM memory_entries ORDER BY memory_key"
        ).fetchall()
        keys = [r["memory_key"] for r in rows]

        self.assertEqual(keys, ["eterna", "valida"])

    def test_refresh_failure_memory_registra_fallos_recurrentes(self) -> None:
        now = utc_now()
        fecha_run = iso(now - timedelta(days=5))
        fecha_job1 = iso(now - timedelta(days=5, hours=2))
        fecha_job2 = iso(now - timedelta(days=5))

        # Insertar run dentro de los últimos 30 días
        self.conn.execute(
            """
            INSERT INTO ci_runs (run_id, workflow, updated_at)
            VALUES (?, ?, ?)
            """,
            (10, "build.yml", fecha_run),
        )

        # Insertar 2 jobs fallidos para el mismo workflow y name
        self.conn.execute(
            """
            INSERT INTO ci_jobs (job_id, run_id, workflow, name, conclusion, completed_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (1001, 10, "build.yml", "test-job", "failure", fecha_job1),
        )
        self.conn.execute(
            """
            INSERT INTO ci_jobs (job_id, run_id, workflow, name, conclusion, completed_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (1002, 10, "build.yml", "test-job", "failure", fecha_job2),
        )
        self.conn.commit()

        refresh_failure_memory(self.conn)

        row = self.conn.execute(
            """
            SELECT kind, memory_key, summary, metadata_json
            FROM memory_entries
            WHERE kind = 'ci_failure' AND memory_key = 'build.yml::test-job'
            """
        ).fetchone()

        self.assertIsNotNone(row)
        self.assertEqual(row["kind"], "ci_failure")
        self.assertEqual(row["memory_key"], "build.yml::test-job")
        self.assertIn("2 fallos en los últimos 30 días", row["summary"])

        metadata = json.loads(row["metadata_json"])
        self.assertEqual(metadata["workflow"], "build.yml")
        self.assertEqual(metadata["job"], "test-job")
        self.assertEqual(metadata["failures_30d"], 2)
        self.assertEqual(metadata["last_failed"], fecha_job2)

    def test_refresh_failure_memory_ignora_fallos_aislados_o_antiguos(self) -> None:
        now = utc_now()
        reciente = iso(now - timedelta(days=5))
        antiguo = iso(now - timedelta(days=40))

        # Run 20: 1 fallo reciente (fallo aislado)
        self.conn.execute(
            "INSERT INTO ci_runs (run_id, workflow, updated_at) VALUES (?, ?, ?)",
            (20, "single.yml", reciente),
        )
        self.conn.execute(
            "INSERT INTO ci_jobs (job_id, run_id, workflow, name, conclusion) VALUES (?, ?, ?, ?, ?)",
            (2001, 20, "single.yml", "job-single", "failure"),
        )

        # Run 30: 2 fallos pero de un run de hace más de 30 días (antiguo)
        self.conn.execute(
            "INSERT INTO ci_runs (run_id, workflow, updated_at) VALUES (?, ?, ?)",
            (30, "old.yml", antiguo),
        )
        self.conn.execute(
            "INSERT INTO ci_jobs (job_id, run_id, workflow, name, conclusion) VALUES (?, ?, ?, ?, ?)",
            (3001, 30, "old.yml", "job-old", "failure"),
        )
        self.conn.execute(
            "INSERT INTO ci_jobs (job_id, run_id, workflow, name, conclusion) VALUES (?, ?, ?, ?, ?)",
            (3002, 30, "old.yml", "job-old", "failure"),
        )

        # Run 40: 2 éxitos recientes
        self.conn.execute(
            "INSERT INTO ci_runs (run_id, workflow, updated_at) VALUES (?, ?, ?)",
            (40, "success.yml", reciente),
        )
        self.conn.execute(
            "INSERT INTO ci_jobs (job_id, run_id, workflow, name, conclusion) VALUES (?, ?, ?, ?, ?)",
            (4001, 40, "success.yml", "job-ok", "success"),
        )
        self.conn.execute(
            "INSERT INTO ci_jobs (job_id, run_id, workflow, name, conclusion) VALUES (?, ?, ?, ?, ?)",
            (4002, 40, "success.yml", "job-ok", "success"),
        )

        self.conn.commit()

        refresh_failure_memory(self.conn)

        count = self.conn.execute(
            "SELECT COUNT(*) AS total FROM memory_entries WHERE kind = 'ci_failure'"
        ).fetchone()["total"]

        self.assertEqual(count, 0)


if __name__ == "__main__":
    unittest.main()
