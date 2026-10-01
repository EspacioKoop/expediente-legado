import importlib.util
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_decompose.py"
SPEC = importlib.util.spec_from_file_location("agent_decompose", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


def _run_del_step(workflow: str, step_id: str) -> str:
    """Extrae el bloque `run: |` de un step sin depender de PyYAML."""
    lineas = workflow.split(f"- id: {step_id}\n", 1)[1].splitlines()
    inicio = next(i for i, linea in enumerate(lineas) if linea.strip() == "run: |") + 1
    cuerpo = []
    sangria = None
    for linea in lineas[inicio:]:
        if linea.strip():
            actual = len(linea) - len(linea.lstrip())
            sangria = actual if sangria is None else sangria
            if actual < sangria:
                break
        cuerpo.append(linea)
    return textwrap.dedent("\n".join(cuerpo))


def _ejecutar_qwen_check(outcome: str, summary: str) -> str:
    workflow = (ROOT / ".github" / "workflows" / "agent-decompose.yml").read_text(
        encoding="utf-8"
    )
    script = _run_del_step(workflow, "qwen_check")
    with tempfile.TemporaryDirectory() as tmp:
        salida = Path(tmp) / "github_output"
        salida.touch()
        env = dict(
            os.environ,
            GITHUB_OUTPUT=str(salida),
            QWEN_OUTCOME=outcome,
            QWEN_SUMMARY=summary,
        )
        subprocess.run(
            ["bash", "-c", script], cwd=ROOT, env=env, check=True, capture_output=True
        )
        valores = dict(
            linea.split("=", 1) for linea in salida.read_text().splitlines() if linea
        )
    return valores["valid"]


def wrap(payload):
    import json
    return "AGENT_DECOMPOSE_BEGIN\n" + json.dumps(payload) + "\nAGENT_DECOMPOSE_END"


class AgentDecomposeTest(unittest.TestCase):
    def test_single_cut_declara_plan_ejecutable_de_un_fichero(self):
        result = mod.parse_decomposition(
            wrap(
                {
                    "fits_single_cut": True,
                    "subtasks": [
                        {
                            "title": "Corte directo",
                            "goal": "Modificar un fichero con alcance acotado.",
                            "files": ["scripts/a.py"],
                            "depends_on": [],
                        }
                    ],
                }
            )
        )
        self.assertTrue(result["fits_single_cut"])
        self.assertEqual(["scripts/a.py"], result["subtasks"][0]["files"])

    def test_gate_humano_no_crea_subtareas(self):
        result = mod.parse_decomposition(
            wrap(
                {
                    "fits_single_cut": False,
                    "needs_human": True,
                    "reason": "Solo queda un pase con mando físico real.",
                    "subtasks": [],
                }
            )
        )
        self.assertTrue(result["needs_human"])
        self.assertFalse(result["fits_single_cut"])
        self.assertEqual([], result["subtasks"])

    def test_gate_humano_con_reason_largo_se_recorta_sin_perderlo(self):
        # Caso real del run 36822348075 (#375): diagnóstico útil de ~440
        # caracteres que antes tumbaba la validación entera.
        reason = (
            "Issue #375 (multiplayer offline-first contract) está completamente "
            "completado. Todos los 7 criterios de aceptación están satisfechos por "
            "código integrado y probado: evento versionado #615, identidad revocable "
            "#1287, TTL revalidación #1734, y abstracción de transporte #1934. No hay "
            "código pendiente, PRs abiertos ni huecos. Los issues posteriores "
            "(#376-#383) son verticales independientes que construyen sobre esta base."
        )
        self.assertGreater(len(reason), mod.REASON_MAX)
        result = mod.parse_decomposition(
            wrap(
                {
                    "fits_single_cut": False,
                    "needs_human": True,
                    "reason": reason,
                    "subtasks": [],
                }
            )
        )
        self.assertTrue(result["needs_human"])
        self.assertLessEqual(len(result["reason"]), mod.REASON_MAX)
        self.assertTrue(result["reason"].endswith("…"))
        self.assertTrue(result["reason"].startswith("Issue #375"))
        self.assertIn("#1934", result["reason"])

    def test_gate_humano_sin_reason_concreto_se_rechaza(self):
        with self.assertRaisesRegex(ValueError, "reason humano"):
            mod.parse_decomposition(
                wrap(
                    {
                        "fits_single_cut": False,
                        "needs_human": True,
                        "reason": "humano",
                        "subtasks": [],
                    }
                )
            )

    def test_recorte_respeta_palabras_y_textos_cortos(self):
        self.assertEqual("corto", mod._recortar("corto", 10))
        self.assertEqual("uno dos…", mod._recortar("uno dos tres cuatro", 10))

    def test_gate_humano_no_se_mezcla_con_trabajo_automatico(self):
        with self.assertRaisesRegex(ValueError, "no puede combinarse"):
            mod.parse_decomposition(
                wrap(
                    {
                        "fits_single_cut": True,
                        "needs_human": True,
                        "reason": "Queda una validación física.",
                        "subtasks": [],
                    }
                )
            )

    def test_valida_cadena_de_dependencias(self):
        result = mod.parse_decomposition(
            wrap(
                {
                    "fits_single_cut": False,
                    "subtasks": [
                        {
                            "title": "Extraer contrato",
                            "goal": "Crear un contrato pequeño y testeable.",
                            "files": ["scripts/a.py"],
                            "depends_on": [],
                        },
                        {
                            "title": "Integrar contrato",
                            "goal": "Consumir el contrato desde el selector.",
                            "files": ["scripts/a.py"],
                            "depends_on": [0],
                        },
                    ],
                }
            )
        )
        self.assertEqual([0], result["subtasks"][1]["depends_on"])

    def test_solape_sin_dependencia_se_rechaza(self):
        with self.assertRaisesRegex(ValueError, "solapadas"):
            mod.parse_decomposition(
                wrap(
                    {
                        "fits_single_cut": False,
                        "subtasks": [
                            {
                                "title": "Primer corte",
                                "goal": "Modificar una ruta compartida con prueba.",
                                "files": ["scripts/a.py"],
                                "depends_on": [],
                            },
                            {
                                "title": "Segundo corte",
                                "goal": "Volver a modificar la misma ruta.",
                                "files": ["scripts/a.py"],
                                "depends_on": [],
                            },
                        ],
                    }
                )
            )

    def test_dependencia_futura_se_rechaza(self):
        with self.assertRaisesRegex(ValueError, "anterior"):
            mod.parse_decomposition(
                wrap(
                    {
                        "fits_single_cut": False,
                        "subtasks": [
                            {
                                "title": "Primer corte",
                                "goal": "Objetivo suficientemente concreto.",
                                "files": ["scripts/a.py"],
                                "depends_on": [1],
                            },
                            {
                                "title": "Segundo corte",
                                "goal": "Objetivo suficientemente concreto.",
                                "files": ["scripts/b.py"],
                                "depends_on": [],
                            },
                        ],
                    }
                )
            )

    def test_acepta_hasta_seis_subtareas(self):
        subtasks = []
        for index in range(6):
            subtasks.append(
                {
                    "title": f"Corte seguro {index}",
                    "goal": "Objetivo pequeño, independiente y verificable.",
                    "files": [f"scripts/corte_{index}.py"],
                    "depends_on": [],
                }
            )
        result = mod.parse_decomposition(
            wrap({"fits_single_cut": False, "subtasks": subtasks})
        )
        self.assertEqual(6, len(result["subtasks"]))

    def test_rechaza_mas_de_seis_subtareas(self):
        subtasks = []
        for index in range(7):
            subtasks.append(
                {
                    "title": f"Corte seguro {index}",
                    "goal": "Objetivo pequeño, independiente y verificable.",
                    "files": [f"scripts/corte_{index}.py"],
                    "depends_on": [],
                }
            )
        with self.assertRaisesRegex(ValueError, "entre 2 y 6"):
            mod.parse_decomposition(
                wrap({"fits_single_cut": False, "subtasks": subtasks})
            )

    def test_rechaza_mas_de_una_ruta_por_corte(self):
        with self.assertRaisesRegex(ValueError, "exactamente 1"):
            mod.parse_decomposition(
                wrap(
                    {
                        "fits_single_cut": False,
                        "subtasks": [
                            {
                                "title": "Corte demasiado ancho",
                                "goal": "Este corte intenta abarcar demasiadas rutas.",
                                "files": ["scripts/a.py", "scripts/b.py"],
                                "depends_on": [],
                            },
                            {
                                "title": "Segundo corte seguro",
                                "goal": "Segundo corte requerido por el contrato.",
                                "files": ["scripts/segundo.py"],
                                "depends_on": [],
                            },
                        ],
                    }
                )
            )

    def test_workflow_tiene_presupuesto_duro_y_no_cierra_padre(self):
        workflow = (
            ROOT / ".github" / "workflows" / "agent-decompose.yml"
        ).read_text(encoding="utf-8")
        # Con 8 turnos Qwen agotaba la sesión antes de emitir el bloque en 8 de
        # cada 10 runs (#2068); el tope duro sigue siendo el timeout por provider.
        self.assertEqual(2, workflow.count('maxSessionTurns":20'))
        self.assertNotIn('maxSessionTurns":8', workflow)
        self.assertIn("timeout-minutes: 5", workflow)
        self.assertIn("continue-on-error: true", workflow)
        self.assertIn("GEMINI_CLI_TRUST_WORKSPACE: 'true'", workflow)
        self.assertNotIn("Normas Platino no disponibles en esta ejecucion", workflow)
        self.assertIn("crea entre 2 y 6 subtareas pequeñas", workflow)
        self.assertIn("needs_human=true", workflow)
        self.assertIn("Gate humano", workflow)
        self.assertIn("exactamente 1 ruta", workflow)
        self.assertIn("agent:decomposed", workflow)
        self.assertIn("agent-delegated-plan:v1", workflow)
        self.assertIn("AGENT_PLAN_BEGIN", workflow)
        self.assertIn("worker de nivel 3 ejecuta el TaskPacket", workflow)
        self.assertNotIn('gh issue close "$ISSUE"', workflow)

    def test_single_cut_materializa_plan_maquina(self):
        workflow = (
            ROOT / ".github" / "workflows" / "agent-decompose.yml"
        ).read_text(encoding="utf-8")
        normalizar = workflow.split("- id: normalize", 1)[1].split("- name: Crear subtareas", 1)[0]
        self.assertIn("jq -c '{files:.files,goal:.goal}'", normalizar)
        self.assertIn("agent-delegated-plan:v1", normalizar)
        self.assertIn("AGENT_PLAN_BEGIN", normalizar)
        self.assertIn("gh workflow run agent-pool.yml", normalizar)

    def test_desbloqueo_depende_de_cierre_real(self):
        workflow = (
            ROOT / ".github" / "workflows" / "agent-dependency-unblock.yml"
        ).read_text(encoding="utf-8")
        self.assertIn("agent-depends-on:", workflow)
        self.assertIn('[[ "$state" != CLOSED ]]', workflow)
        self.assertIn('queue_label=agent:auto', workflow)
        self.assertIn('queue_label=agent:qwen', workflow)
        self.assertIn('queue_label=agent:gemini', workflow)
        self.assertIn('--remove-label agent:blocked --add-label "$queue_label"', workflow)
        self.assertIn("agent-provider:", workflow)

    def test_decompose_saca_padre_de_cola_mientras_planifica(self):
        workflow = (
            ROOT / ".github" / "workflows" / "agent-decompose.yml"
        ).read_text(encoding="utf-8")
        for label in ("agent:auto", "agent:pool", "agent:qwen", "agent:gemini"):
            self.assertIn(f'--remove-label "$label"', workflow)
        self.assertIn("requested_provider", workflow)
        self.assertIn("agent-provider:", workflow)

    def test_fallback_gemini_depende_del_contrato_de_qwen(self):
        workflow = (
            ROOT / ".github" / "workflows" / "agent-decompose.yml"
        ).read_text(encoding="utf-8")
        orden = [
            workflow.index("- id: plan_qwen"),
            workflow.index("- id: qwen_check"),
            workflow.index("- id: plan_gemini"),
            workflow.index("- id: normalize"),
        ]
        self.assertEqual(sorted(orden), orden)
        gemini = workflow.split("- id: plan_gemini", 1)[1].split("uses:", 1)[0]
        self.assertIn("steps.qwen_check.outputs.valid != 'true'", gemini)
        self.assertNotIn("steps.plan_qwen.outcome", gemini)
        normalizar = workflow.split("- id: normalize", 1)[1].split("run:", 1)[0]
        self.assertIn(
            "steps.qwen_check.outputs.valid == 'true' && steps.plan_qwen.outputs.summary",
            normalizar,
        )

    def test_qwen_check_ejecutado_clasifica_la_salida(self):
        bloque_valido = wrap(
            {
                "fits_single_cut": False,
                "needs_human": True,
                "reason": "x " * 300,
                "subtasks": [],
            }
        )
        casos = [
            ("success", bloque_valido, "true"),
            ("success", "Reached max session turns", "false"),
            ("success", "", "false"),
            ("failure", bloque_valido, "false"),
        ]
        for outcome, summary, esperado in casos:
            with self.subTest(outcome=outcome, summary=summary[:30]):
                self.assertEqual(esperado, _ejecutar_qwen_check(outcome, summary))

    def test_ruta_protegida_se_rechaza(self):
        with self.assertRaisesRegex(ValueError, "insegura"):
            mod.parse_decomposition(
                wrap(
                    {
                        "fits_single_cut": False,
                        "subtasks": [
                            {
                                "title": "Primer corte",
                                "goal": "Objetivo suficientemente concreto.",
                                "files": [".github/workflows/x.yml"],
                                "depends_on": [],
                            },
                            {
                                "title": "Segundo corte",
                                "goal": "Objetivo suficientemente concreto.",
                                "files": ["scripts/b.py"],
                                "depends_on": [],
                            },
                        ],
                    }
                )
            )


if __name__ == "__main__":
    unittest.main()
