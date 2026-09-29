import json
from pathlib import Path
import subprocess
import sys
import re
import tempfile
import unittest

import agent_pool_funnel as funnel

ROOT = Path(__file__).resolve().parents[1]


def job(worker, exitos, extra=None, issue=10, provider="qwen"):
    pasos = [{"name": nombre, "conclusion": "success"} for nombre in exitos]
    pasos += [{"name": nombre, "conclusion": c} for nombre, c in (extra or [])]
    return {"name": f"run ({issue}, {provider}, {worker}) / worker", "steps": pasos}


ARRANCA = ["Validar issue y slot", "Materializar contexto del issue"]
PLAN = ARRANCA + ["Validar plan y reservar rutas"]
RESERVA = PLAN + ["Compilar TaskPacket y prompt del worker", "Crear rama"]
IMPLEMENTA = RESERVA + ["Implementar con Qwen", "Normalizar cambios al CLAIM"]
COMPLETO = IMPLEMENTA + ["Validar diff y preflight", "Publicar PR draft y lanzar CI canonica"]


class EmbudoPoolTest(unittest.TestCase):
    def test_fase_mas_avanzada_de_cada_job(self):
        self.assertIsNone(funnel.fase_alcanzada(job("w", ["Validar issue y slot"])))
        self.assertEqual("arranca", funnel.fase_alcanzada(job("w", ARRANCA)))
        # Plan vacío: el paso de reserva acaba en success sin reservar.
        self.assertEqual("plan_parseado", funnel.fase_alcanzada(job("w", PLAN)))
        self.assertEqual("reserva", funnel.fase_alcanzada(job("w", RESERVA)))
        self.assertEqual("pr_draft", funnel.fase_alcanzada(job("w", COMPLETO)))

    def test_fase_rota_corta_el_embudo(self):
        # Sin plan válido no cuenta como reserva aunque un paso posterior figure en success.
        pasos = ARRANCA + ["Compilar TaskPacket y prompt del worker"]
        self.assertEqual("arranca", funnel.fase_alcanzada(job("w", pasos)))

    def test_replan_marca_implementacion_fuera_de_claim(self):
        replan = job("w", IMPLEMENTA + ["Replanificar pool tras desvio de CLAIM"])
        self.assertEqual("implementa_fuera_de_claim", funnel.fase_alcanzada(replan))

    def test_origen_plan_delegado(self):
        delegado = job("w", PLAN, extra=[("Plan Qwen", "skipped")])
        delegado["steps"].append({"name": "Buscar plan delegado por el nivel 2", "conclusion": "success"})
        self.assertEqual("delegado", funnel.origen_plan(delegado))

    def test_origen_plan_generado(self):
        self.assertEqual("generado", funnel.origen_plan(job("w", PLAN)))
        fallido = job("w", PLAN, extra=[("Plan Qwen", "failure")])
        self.assertEqual("generado", funnel.origen_plan(fallido))

    def test_origen_plan_nulo_si_no_llega(self):
        self.assertIsNone(funnel.origen_plan(job("w", ["Validar issue y slot"])))
        # Planificador omitido sin búsqueda delegada exitosa: no llegó a planificar.
        omitido = job("w", ARRANCA, extra=[("Plan Gemini", "skipped")])
        self.assertIsNone(funnel.origen_plan(omitido))

    def test_embudo_separa_por_origen_del_plan(self):
        delegado = job("w", COMPLETO)
        delegado["steps"].append({"name": "Buscar plan delegado por el nivel 2", "conclusion": "success"})
        delegado["steps"].append({"name": "Plan Qwen", "conclusion": "skipped"})
        generado = job("w", PLAN, provider="gemini")
        resultado = funnel.embudo([delegado, generado])
        self.assertEqual(1, resultado["por_origen"]["delegado"]["pr_draft"])
        self.assertEqual(0, resultado["por_origen"]["generado"]["pr_draft"])
        self.assertEqual(1, resultado["por_origen"]["generado"]["plan_parseado"])

    def test_tabla_muestra_linea_por_origen(self):
        delegado = job("w", COMPLETO)
        delegado["steps"].append({"name": "Buscar plan delegado por el nivel 2", "conclusion": "success"})
        delegado["steps"].append({"name": "Plan Qwen", "conclusion": "skipped"})
        resultado = funnel.embudo([delegado])
        texto = funnel.tabla(resultado)
        self.assertIn("Plan delegado: 1 workers, 1 PR (100%).", texto)
        self.assertNotIn("Plan generado:", texto)

    def test_embudo_acumulado_y_por_worker(self):
        jobs = [
            job("qwen-primary", COMPLETO),
            job("qwen-primary", RESERVA),
            job("gemini", PLAN, provider="gemini"),
            job("gemini", ["Validar issue y slot"], provider="gemini"),
            job("qwen-primary", IMPLEMENTA + ["Replanificar pool tras desvio de CLAIM"]),
            {"name": "prepare", "steps": [{"name": "x", "conclusion": "success"}]},
        ]
        resultado = funnel.embudo(jobs)
        self.assertEqual(5, resultado["workers"])
        self.assertEqual(
            {
                "arranca": 4,
                "plan_parseado": 4,
                "reserva": 3,
                "implementa": 2,
                "preflight": 1,
                "pr_draft": 1,
            },
            resultado["embudo"],
        )
        self.assertEqual(1, resultado["implementa_fuera_de_claim"])
        self.assertEqual(2, resultado["por_worker"]["gemini"]["workers"])
        self.assertEqual(0, resultado["por_worker"]["gemini"]["reserva"])
        # Tasas de conversión sobre el total de workers.
        self.assertAlmostEqual(0.6, resultado["reservation_rate"])
        self.assertAlmostEqual(0.4, resultado["implementation_rate"])
        self.assertAlmostEqual(0.2, resultado["pr_rate"])

    def test_embudo_sin_workers_da_tasas_cero(self):
        resultado = funnel.embudo([])
        self.assertEqual(0, resultado["workers"])
        self.assertEqual(0.0, resultado["reservation_rate"])
        self.assertEqual(0.0, resultado["implementation_rate"])
        self.assertEqual(0.0, resultado["pr_rate"])

    def test_nombres_de_pasos_existen_en_el_worker(self):
        # Si alguien renombra un paso, el embudo daría cero en silencio.
        worker = (ROOT / ".github" / "workflows" / "agent-worker.yml").read_text(encoding="utf-8")
        nombres = set(re.findall(r"^\s+(?:- )?name: (.+?)\s*$", worker, re.M))
        for fase, pasos in funnel.FASES:
            for paso in pasos:
                with self.subTest(fase=fase, paso=paso):
                    self.assertIn(paso, nombres)
        self.assertIn("Replanificar pool tras desvio de CLAIM", nombres)

    def test_cli_con_jobs_descargados(self):
        with tempfile.TemporaryDirectory() as tmp:
            datos = Path(tmp) / "jobs.json"
            datos.write_text(json.dumps([job("qwen-primary", COMPLETO)]), encoding="utf-8")
            salida = subprocess.run(
                [sys.executable, str(ROOT / "scripts" / "agent_pool_funnel.py"), "--jobs-json", str(datos)],
                check=True,
                capture_output=True,
                text=True,
            ).stdout
        self.assertIn("| pr_draft | 1 | 100% |", salida)
        self.assertIn("PR/worker: 100%.", salida)


if __name__ == "__main__":
    unittest.main()
