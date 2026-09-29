"""Contrato del handoff nivel 2 -> executor en agent-worker.yml."""

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

    def test_busca_plan_delegado_antes_de_reservar(self):
        paso = self._paso("delegated")
        self.assertIn('gh api "repos/$GITHUB_REPOSITORY/issues/$ISSUE"', paso)
        self.assertIn("python3 scripts/agent_delegated_plan.py", paso)
        self.assertLess(
            self.worker.index("- id: delegated\n"),
            self.worker.index("- id: reserve\n"),
        )

    def test_falta_plan_deriva_a_decompose_y_no_planifica(self):
        route = self._paso("route_decompose")
        self.assertIn("steps.delegated.outputs.found != 'true'", route)
        self.assertIn("--add-label agent:decompose", route)
        self.assertNotIn("- id: plan_qwen\n", self.worker)
        self.assertNotIn("- id: plan_gemini\n", self.worker)

    def test_reserva_lee_solo_plan_delegado_y_presupuesto(self):
        paso = self._paso("reserve")
        fuentes = re.findall(r"--source\s+(\S+)", paso)
        self.assertEqual(["/tmp/delegado.json"], fuentes)
        self.assertIn("AGENT_POOL_MAX_FILES", paso)
        self.assertIn('--max-files "$MAX_FILES"', paso)
        self.assertIn("steps.delegated.outputs.found == 'true'", paso)

    def test_executor_no_precarga_contexto_de_planificacion(self):
        self.assertNotIn("Cargar memoria historica de CI", self.worker)
        self.assertNotIn("Cargar Normas Platino, wiki y memoria", self.worker)
        self.assertNotIn("Afinar contexto y memoria por rutas", self.worker)
        self.assertNotIn("/tmp/agent-output-plan", self.worker)
        self.assertIn("Sellar versión de Normas Platino", self.worker)


if __name__ == "__main__":
    unittest.main()
