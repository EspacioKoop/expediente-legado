import importlib.util
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_decompose.py"
SPEC = importlib.util.spec_from_file_location("agent_decompose", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


def wrap(payload):
    import json
    return "AGENT_DECOMPOSE_BEGIN\n" + json.dumps(payload) + "\nAGENT_DECOMPOSE_END"


class AgentDecomposeTest(unittest.TestCase):
    def test_single_cut_no_crea_subtareas(self):
        result = mod.parse_decomposition(
            wrap({"fits_single_cut": True, "subtasks": [{"title": "ignorar"}]})
        )
        self.assertTrue(result["fits_single_cut"])
        self.assertEqual([], result["subtasks"])

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
                            "files": ["scripts/a.py", "scripts/b.py"],
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

    def test_rechaza_mas_de_ocho_rutas_por_corte(self):
        with self.assertRaisesRegex(ValueError, "entre 1 y 8"):
            mod.parse_decomposition(
                wrap(
                    {
                        "fits_single_cut": False,
                        "subtasks": [
                            {
                                "title": "Corte demasiado ancho",
                                "goal": "Este corte intenta abarcar demasiadas rutas.",
                                "files": [f"scripts/f_{i}.py" for i in range(9)],
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
        self.assertIn('maxSessionTurns":8', workflow)
        self.assertIn("timeout-minutes: 5", workflow)
        self.assertIn("continue-on-error: true", workflow)
        self.assertIn("crea entre 2 y 6 subtareas pequeñas", workflow)
        self.assertIn("needs_human=true", workflow)
        self.assertIn("Gate humano", workflow)
        self.assertIn("files concretos (max 8)", workflow)
        self.assertIn("agent:decomposed", workflow)
        self.assertNotIn('gh issue close "$ISSUE"', workflow)

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
