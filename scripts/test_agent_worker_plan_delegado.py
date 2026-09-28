"""Contrato del cableado de planes delegados en agent-worker.yml (#1637).

El selector vive en scripts/agent_delegated_plan.py; aquí se fija que el
worker lo invoque con datos REST y que, si hay plan, se omita el planificador.
"""

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKER = ROOT / ".github" / "workflows" / "agent-worker.yml"


class CableadoPlanDelegadoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.worker = WORKER.read_text(encoding="utf-8")

    def _paso(self, paso_id):
        inicio = self.worker.index(f"- id: {paso_id}\n")
        fin = self.worker.index("\n      - ", inicio + 1)
        return self.worker[inicio:fin]

    def test_busca_plan_con_rest_antes_de_planificar(self):
        paso = self._paso("delegated")
        # gh issue view no expone author_association del cuerpo del issue.
        self.assertIn('gh api "repos/$GITHUB_REPOSITORY/issues/$ISSUE"', paso)
        self.assertIn("python3 scripts/agent_delegated_plan.py", paso)
        self.assertIn("se usará el planificador", paso)
        self.assertLess(
            self.worker.index("- id: delegated\n"), self.worker.index("- id: plan_qwen\n")
        )

    def test_plan_delegado_omite_planificadores(self):
        for paso_id in ("plan_qwen", "plan_gemini"):
            with self.subTest(paso=paso_id):
                self.assertIn("steps.delegated.outputs.found != 'true'", self._paso(paso_id))

    def test_toda_lectura_del_plan_prioriza_el_delegado(self):
        lecturas = re.findall(r"\$\{\{ [^}]*steps\.plan_qwen\.outputs\.summary[^}]*\}\}", self.worker)
        self.assertEqual(2, len(lecturas))
        for lectura in lecturas:
            self.assertTrue(lectura.startswith("${{ steps.delegated.outputs.summary ||"), lectura)


if __name__ == "__main__":
    unittest.main()
