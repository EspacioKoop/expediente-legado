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
        paso = self._paso("reserve")
        fuentes = re.findall(r"--source\s+(\S+)", paso)
        self.assertIn("python3 scripts/agent_plan_parse.py", paso)
        self.assertEqual("/tmp/delegado.json", fuentes[0])
        self.assertGreater(len(fuentes), 1)

    def test_la_salida_del_planificador_no_viaja_por_env(self):
        # >128 KB en una variable: «Argument list too long» y el paso ni
        # arranca, tampoco el de limpieza, que deja el CLAIM colgado (#1881).
        for step in ("plan_qwen", "plan_gemini", "delegated"):
            with self.subTest(step=step):
                self.assertNotRegex(self.worker, rf"steps\.{step}\.outputs\.summary")

    def test_limpieza_detecta_sobrecarga_leyendo_fichero(self):
        inicio = self.worker.index("name: Limpiar fallo o cancelacion")
        paso = self.worker[inicio:]
        self.assertIn("overloaded", paso)
        self.assertIn("/tmp/agent-output-plan", paso)
        self.assertIn("/tmp/agent-output-implement", paso)
        self.assertIn("/tmp/agent-output-implement", self._paso("validate_diff"))


if __name__ == "__main__":
    unittest.main()
