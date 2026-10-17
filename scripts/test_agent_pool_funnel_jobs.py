import json
import subprocess
import unittest
from unittest.mock import MagicMock, patch

import agent_pool_funnel as funnel


class DescargarJobsTest(unittest.TestCase):
    @patch("subprocess.run")
    def test_descargar_jobs_exito(self, mock_run):
        def side_effect(cmd, check, capture_output, text):
            ruta = cmd[2]
            if ruta == "repos/owner/repo/actions/workflows/agent-pool.yml/runs?per_page=10":
                stdout = json.dumps({"workflow_runs": [{"id": 101}, {"id": 102}]})
            elif ruta == "repos/owner/repo/actions/runs/101/jobs?per_page=100":
                stdout = json.dumps({"jobs": [{"id": 1, "name": "worker-1"}, {"id": 2, "name": "worker-2"}]})
            elif ruta == "repos/owner/repo/actions/runs/102/jobs?per_page=100":
                stdout = json.dumps({"jobs": [{"id": 3, "name": "worker-3"}]})
            else:
                self.fail(f"Comando inesperado: {cmd}")
            return MagicMock(stdout=stdout)

        mock_run.side_effect = side_effect

        jobs = funnel.descargar_jobs("owner/repo", 10)

        self.assertEqual(len(jobs), 3)
        self.assertEqual(jobs[0]["name"], "worker-1")
        self.assertEqual(jobs[1]["name"], "worker-2")
        self.assertEqual(jobs[2]["name"], "worker-3")
        self.assertEqual(mock_run.call_count, 3)

    @patch("subprocess.run")
    def test_descargar_jobs_sin_runs(self, mock_run):
        mock_run.return_value = MagicMock(stdout=json.dumps({"workflow_runs": []}))

        jobs = funnel.descargar_jobs("owner/repo", 5)

        self.assertEqual(jobs, [])
        mock_run.assert_called_once_with(
            ["gh", "api", "repos/owner/repo/actions/workflows/agent-pool.yml/runs?per_page=5"],
            check=True,
            capture_output=True,
            text=True,
        )

    @patch("subprocess.run")
    def test_descargar_jobs_run_sin_campo_jobs(self, mock_run):
        def side_effect(cmd, check, capture_output, text):
            ruta = cmd[2]
            if "workflows/agent-pool.yml/runs" in ruta:
                stdout = json.dumps({"workflow_runs": [{"id": 201}]})
            else:
                stdout = json.dumps({"sin_jobs": True})
            return MagicMock(stdout=stdout)

        mock_run.side_effect = side_effect

        jobs = funnel.descargar_jobs("owner/repo", 5)
        self.assertEqual(jobs, [])

    @patch("subprocess.run")
    def test_descargar_jobs_error_subprocess(self, mock_run):
        mock_run.side_effect = subprocess.CalledProcessError(
            returncode=1,
            cmd=["gh", "api", "repos/owner/repo/actions/workflows/agent-pool.yml/runs?per_page=5"],
            stderr="gh: command not found or API error",
        )

        with self.assertRaises(subprocess.CalledProcessError):
            funnel.descargar_jobs("owner/repo", 5)

    @patch("subprocess.run")
    def test_descargar_jobs_json_invalido(self, mock_run):
        mock_run.return_value = MagicMock(stdout="Not JSON")

        with self.assertRaises(json.JSONDecodeError):
            funnel.descargar_jobs("owner/repo", 5)


if __name__ == "__main__":
    unittest.main()
