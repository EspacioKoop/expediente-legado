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
