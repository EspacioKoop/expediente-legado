from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
import json
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_pool_refill_canary.py"
SPEC = spec_from_file_location("agent_pool_refill_canary", MODULE_PATH)
mod = module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(mod)


def job(run_id, worker, start, end):
    return {
        "run_id": str(run_id),
        "worker": worker,
        "started_at": start,
        "completed_at": end,
    }


class AgentPoolRefillCanaryTest(unittest.TestCase):
    def test_refill_arranca_mientras_otro_worker_base_sigue_en_curso(self):
        data = {
            "base_run": "100",
            "refill_run": "101",
            "jobs": [
                job("100", "qwen-primary", "2026-10-03T18:00:00Z", "2026-10-03T18:02:00Z"),
                job("100", "gemini", "2026-10-03T18:00:05Z", "2026-10-03T18:10:00Z"),
                job("101", "qwen-primary", "2026-10-03T18:02:30Z", "2026-10-03T18:06:00Z"),
            ],
        }
        result = mod.evaluar(data)
        self.assertTrue(result["ok"], result)
        self.assertTrue(result["refill_antes_fin_tanda"])
        self.assertEqual([], result["worker_overlaps"])
        self.assertEqual(["qwen-primary"], result["refill_workers"])

    def test_dos_jobs_del_mismo_worker_solapados_invalidan_canario(self):
        data = {
            "base_run": "200",
            "refill_run": "201",
            "jobs": [
                job("200", "qwen-primary", "2026-10-03T18:00:00Z", "2026-10-03T18:08:00Z"),
                job("200", "gemini", "2026-10-03T18:00:00Z", "2026-10-03T18:10:00Z"),
                job("201", "qwen-primary", "2026-10-03T18:04:00Z", "2026-10-03T18:06:00Z"),
            ],
        }
        result = mod.evaluar(data)
        self.assertFalse(result["ok"])
        self.assertEqual("qwen-primary", result["worker_overlaps"][0]["worker"])
        self.assertIn(
            "hay workers ejecutándose simultáneamente en dos jobs",
            result["errors"],
        )

    def test_refill_despues_de_acabar_toda_la_tanda_no_demuestra_mejora(self):
        data = {
            "base_run": "300",
            "refill_run": "301",
            "jobs": [
                job("300", "qwen-primary", "2026-10-03T18:00:00Z", "2026-10-03T18:02:00Z"),
                job("300", "gemini", "2026-10-03T18:00:00Z", "2026-10-03T18:03:00Z"),
                job("301", "qwen-primary", "2026-10-03T18:03:30Z", "2026-10-03T18:05:00Z"),
            ],
        }
        result = mod.evaluar(data)
        self.assertFalse(result["ok"])
        self.assertFalse(result["refill_antes_fin_tanda"])
        self.assertIn(
            "el refill no arrancó antes de acabar la tanda base",
            result["errors"],
        )

    def test_cli_devuelve_uno_en_evidencia_invalida(self):
        data = {
            "base_run": "400",
            "refill_run": "401",
            "jobs": [
                job("400", "qwen-primary", "2026-10-03T18:00:00Z", "2026-10-03T18:01:00Z"),
            ],
        }
        with tempfile.TemporaryDirectory() as tmp:
            entrada = Path(tmp) / "input.json"
            salida = Path(tmp) / "result.json"
            entrada.write_text(json.dumps(data), encoding="utf-8")
            completed = subprocess.run(
                [
                    sys.executable,
                    str(MODULE_PATH),
                    "--input",
                    str(entrada),
                    "--output",
                    str(salida),
                ],
                capture_output=True,
                text=True,
                timeout=10,
            )
            self.assertEqual(1, completed.returncode)
            result = json.loads(salida.read_text(encoding="utf-8"))
            self.assertFalse(result["ok"])
            self.assertIn("refill_run sin jobs", result["errors"])

    def test_parser_admite_nombre_historico_de_matrix(self):
        self.assertEqual(
            "qwen-primary",
            mod._worker({"name": "run (qwen / qwen-primary) / worker"}),
        )
        self.assertEqual("", mod._worker({"name": "prepare"}))


if __name__ == "__main__":
    unittest.main()
