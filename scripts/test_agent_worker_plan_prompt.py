"""Contrato: el worker final ejecuta un plan delegado y no planifica."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKER = ROOT / ".github" / "workflows" / "agent-worker.yml"


class WorkerExecutorOnlyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.worker = WORKER.read_text(encoding="utf-8")

    def _bloque_paso(self, paso_id):
        inicio = self.worker.index(f"- id: {paso_id}\n")
        fin = self.worker.index("\n      - ", inicio + 1)
        return self.worker[inicio:fin]

    def test_no_hay_planificador_en_nivel_tres(self):
        self.assertNotIn("- id: plan_qwen\n", self.worker)
        self.assertNotIn("- id: plan_gemini\n", self.worker)
        self.assertNotIn("FASE DE PLAN (solo lectura)", self.worker)

    def test_sin_plan_se_devuelve_al_decomposer(self):
        delegated = self._bloque_paso("delegated")
        route = self._bloque_paso("route_decompose")
        self.assertIn("scripts/agent_delegated_plan.py", delegated)
        self.assertIn("found=false", delegated)
        self.assertIn("agent:decompose", route)
        self.assertIn("executor no consume turnos planificando", route)

    def test_implementers_solo_reciben_prompt_compilado(self):
        for paso_id in ("implement_qwen", "implement_gemini"):
            with self.subTest(paso=paso_id):
                paso = self._bloque_paso(paso_id)
                self.assertIn("Lee .agent-worker-prompt.md", paso)
                self.assertIn("No leas ningun otro fichero de contexto", paso)
                self.assertNotIn("AGENTS.md", paso)


if __name__ == "__main__":
    unittest.main()
