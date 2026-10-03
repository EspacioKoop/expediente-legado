from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
import copy
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
    def evidencia(self):
        return {
            "base_run": "100", "refill_run": "101",
            "jobs": [
                job("100", "A", "2026-10-03T18:00:00Z", "2026-10-03T18:02:00Z"),
                job("100", "B", "2026-10-03T18:00:00Z", "2026-10-03T18:10:00Z"),
                job("101", "A", "2026-10-03T18:03:00Z", "2026-10-03T18:06:00Z"),
            ],
        }

    def test_refill_en_slot_ajeno_no_demuestra_reutilizacion(self):
        data = self.evidencia()
        data["jobs"][2]["worker"] = "ajeno"
        self.assertFalse(mod.evaluar(data)["ok"])

    def test_otro_worker_base_debe_estar_ejecutando_no_solo_acabar_mas_tarde(self):
        data = self.evidencia()
        data["jobs"][1]["started_at"] = "2026-10-03T18:07:00Z"
        self.assertFalse(mod.evaluar(data)["ok"])

    def test_nunca_ignora_tiempos_ausentes_o_invalidos_en_nadie(self):
        for index in range(3):
            for field in ("started_at", "completed_at"):
                for value in (None, "no-es-fecha", "2026-10-03T18:00:00"):
                    with self.subTest(index=index, field=field, value=value):
                        data = self.evidencia()
                        data["jobs"][index][field] = value
                        self.assertFalse(mod.evaluar(data)["ok"])

    def test_identidad_worker_ausente_en_base_tambien_invalida_evidencia(self):
        data = self.evidencia()
        data["jobs"][1].pop("worker")
        self.assertFalse(mod.evaluar(data)["ok"])

    def test_run_id_ausente_no_se_convierte_en_run_none(self):
        data = self.evidencia()
        data["jobs"][0]["run_id"] = None
        self.assertFalse(mod.evaluar(data)["ok"])

    def test_intervalos_invertidos_no_cuentan_como_prueba(self):
        data = self.evidencia()
        data["jobs"][2]["completed_at"] = "2026-10-03T18:01:00Z"
        self.assertFalse(mod.evaluar(data)["ok"])

    def test_tanda_base_y_refill_tienen_ids_distintos(self):
        data = self.evidencia()
        data["refill_run"] = "100"
        self.assertFalse(mod.evaluar(data)["ok"])

    def test_formas_invalidas_de_jobs_se_rechazan_sin_excepcion(self):
        for rows in (None, {}, "jobs", [None]):
            with self.subTest(rows=rows):
                data = self.evidencia()
                data["jobs"] = rows
                self.assertFalse(mod.evaluar(data)["ok"])

    def test_offsets_equivalentes_se_normalizan_y_no_mutan_entrada(self):
        data = self.evidencia()
        data["jobs"][2]["started_at"] = "2026-10-03T20:03:00+02:00"
        before = copy.deepcopy(data)
        self.assertTrue(mod.evaluar(data)["ok"])
        self.assertEqual(before, data)

    def test_solapes_anidados_reportan_tambien_el_tercer_job(self):
        data = self.evidencia()
        data["jobs"].extend([
            job("200", "C", "2026-10-03T18:00:00Z", "2026-10-03T18:10:00Z"),
            job("201", "C", "2026-10-03T18:01:00Z", "2026-10-03T18:02:00Z"),
            job("202", "C", "2026-10-03T18:03:00Z", "2026-10-03T18:04:00Z"),
        ])
        result = mod.evaluar(data)
        self.assertFalse(result["ok"])
        self.assertEqual({("200", "201"), ("200", "202")},
                         {(o["run_a"], o["run_b"]) for o in result["worker_overlaps"]})

    def test_limite_contiguo_del_slot_es_valido(self):
        data = self.evidencia()
        data["jobs"][2]["started_at"] = data["jobs"][0]["completed_at"]
        result = mod.evaluar(data)
        self.assertTrue(result["ok"], result)
        self.assertEqual([], result["worker_overlaps"])

    def test_otro_worker_que_acaba_en_el_limite_ya_no_esta_activo(self):
        data = self.evidencia()
        data["jobs"][1]["completed_at"] = data["jobs"][2]["started_at"]
        self.assertFalse(mod.evaluar(data)["ok"])

    def test_ids_enteros_y_nombres_historicos_mantienen_testigo(self):
        data = self.evidencia()
        data["base_run"], data["refill_run"] = 100, 101
        for row in data["jobs"]:
            row["run_id"] = int(row["run_id"])
            row["name"] = f'run (qwen / {row.pop("worker")}) / worker'
        result = mod.evaluar(data)
        self.assertTrue(result["ok"], result)
        self.assertEqual([{
            "worker": "A", "base_completed_at": "2026-10-03T18:02:00+00:00",
            "refill_started_at": "2026-10-03T18:03:00+00:00",
            "base_workers_en_curso": ["B"],
        }], result["refill_witnesses"])

    def test_cli_devuelve_uno_y_json_para_evidencia_incompleta(self):
        for value in (None, "2026-10-03T18:00:00"):
            with self.subTest(value=value), tempfile.TemporaryDirectory() as directory:
                data = self.evidencia()
                data["jobs"][1]["started_at"] = value
                path = Path(directory) / "input.json"
                path.write_text(json.dumps(data))
                run = subprocess.run([sys.executable, str(MODULE_PATH), "--input", str(path)],
                                     capture_output=True, text=True, timeout=10)
                self.assertEqual(1, run.returncode)
                self.assertFalse(json.loads(run.stdout)["ok"])
                self.assertNotIn("Traceback", run.stderr)

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
