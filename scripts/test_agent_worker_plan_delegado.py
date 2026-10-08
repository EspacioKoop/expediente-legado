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

    def test_falta_plan_deriva_a_decompose_sin_llm(self):
        paso = self._paso("route_decompose")
        self.assertIn("steps.delegated.outputs.found != 'true'", paso)
        self.assertIn("--add-label agent:decompose", paso)
        self.assertNotIn("- id: plan_qwen\n", self.worker)
        self.assertNotIn("- id: plan_gemini\n", self.worker)

    def test_reserva_lee_solo_el_plan_delegado(self):
        paso = self._paso("reserve")
        fuentes = re.findall(r"--source\s+(\S+)", paso)
        self.assertEqual(["/tmp/delegado.json"], fuentes)
        self.assertIn("steps.delegated.outputs.found == 'true'", paso)
        self.assertIn("scripts/agent_scope_limit.py --issue-json /tmp/agent-issue.json", paso)
        self.assertIn('--max-files "$MAX_FILES"', paso)
        self.assertIn("status == 5", paso)
        self.assertIn("agent:decompose", paso)

    def test_executor_no_precarga_contexto_de_planificacion(self):
        self.assertNotIn("Cargar memoria historica de CI", self.worker)
        self.assertNotIn("Cargar Normas Platino, wiki y memoria", self.worker)
        self.assertNotIn("Afinar contexto y memoria por rutas", self.worker)
        self.assertNotIn("/tmp/agent-output-plan", self.worker)
        self.assertIn("Sellar versión de Normas Platino", self.worker)

    def test_implementacion_no_lee_contexto_extra(self):
        for paso_id in ("implement_qwen", "implement_gemini"):
            with self.subTest(paso=paso_id):
                self.assertIn(
                    "No leas ningun otro fichero de contexto",
                    self._paso(paso_id),
                )


    def test_limpieza_clasifica_sobrecarga_leyendo_fichero(self):
        inicio = self.worker.index("name: Limpiar fallo o cancelacion")
        paso = self.worker[inicio:]
        policy = (ROOT / "scripts" / "agent_failure_policy.py").read_text(encoding="utf-8")
        self.assertIn("scripts/agent_failure_policy.py", paso)
        self.assertIn("--text-file", paso)
        self.assertIn("overloaded", policy)
        self.assertNotIn("/tmp/agent-output-plan", paso)
        self.assertIn("/tmp/agent-output-implement", paso)
        self.assertIn("/tmp/agent-output-implement", self._paso("validate_diff"))


if __name__ == "__main__":
    unittest.main()
