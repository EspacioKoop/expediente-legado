"""Contrato: el planificador recibe la tarea en el prompt, no solo en un fichero.

En el pool, Qwen respondió «no se ha presentado ninguna tarea» (#667), pidió
herramientas de edición en la fase de plan (#668) o filtró razonamiento interno
(#1615): ninguno llegó a leer `.agent-task.md`.
"""

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKER = ROOT / ".github" / "workflows" / "agent-worker.yml"


class PromptPlanIncluyeTareaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.worker = WORKER.read_text(encoding="utf-8")

    def _bloque_paso(self, paso_id):
        inicio = self.worker.index(f"- id: {paso_id}\n")
        fin = self.worker.index("\n      - ", inicio + 1)
        return self.worker[inicio:fin]

    def test_materializar_expone_la_tarea_como_salida(self):
        paso = self._bloque_paso("task")
        self.assertIn("name: Materializar contexto del issue", paso)
        # Delimitador aleatorio: el cuerpo del issue no puede cerrar el heredoc.
        self.assertIn('delim="TAREA_$(openssl rand -hex 8)"', paso)
        self.assertIn('echo "brief<<$delim"', paso)
        self.assertRegex(paso, r"--json\s+number,title,body")
        self.assertIn(".[0:6000]", paso)

    def test_prompts_de_plan_llevan_la_tarea_y_la_fase(self):
        for paso_id in ("plan_qwen", "plan_gemini"):
            with self.subTest(paso=paso_id):
                prompt = re.search(r"prompt: '(.*)'", self._bloque_paso(paso_id)).group(1)
                self.assertTrue(prompt.startswith("FASE DE PLAN (solo lectura)"))
                self.assertIn("${{ steps.task.outputs.brief }}", prompt)
                self.assertLess(
                    prompt.index("${{ steps.task.outputs.brief }}"),
                    prompt.index("AGENT_PLAN_BEGIN"),
                )


if __name__ == "__main__":
    unittest.main()
