import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULO = ROOT / "scripts" / "agent_claim_guard.py"
WORKFLOW = ROOT / ".github" / "workflows" / "agent-autopilot.yml"
WORKER_WORKFLOW = ROOT / ".github" / "workflows" / "agent-worker.yml"

SPEC = importlib.util.spec_from_file_location("agent_claim_guard", MODULO)
assert SPEC and SPEC.loader
guard = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(guard)


class AgentClaimGuardTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        subprocess.run(["git", "init", "-q"], cwd=self.repo, check=True)
        subprocess.run(
            ["git", "config", "user.email", "test@example.invalid"],
            cwd=self.repo,
            check=True,
        )
        subprocess.run(
            ["git", "config", "user.name", "Test"],
            cwd=self.repo,
            check=True,
        )
        (self.repo / "permitido.txt").write_text("base\n", encoding="utf-8")
        (self.repo / "bloqueado.txt").write_text("base\n", encoding="utf-8")
        subprocess.run(["git", "add", "."], cwd=self.repo, check=True)
        subprocess.run(["git", "commit", "-qm", "base"], cwd=self.repo, check=True)
        self.plan = self.repo / ".agent-plan.json"
        self.plan.write_text(
            json.dumps({"files": ["permitido.txt"], "goal": "prueba"}),
            encoding="utf-8",
        )

    def tearDown(self):
        self.tmp.cleanup()

    def test_detecta_fuera_del_claim_e_ignora_contexto_del_agente(self):
        (self.repo / "permitido.txt").write_text("ok\n", encoding="utf-8")
        (self.repo / "bloqueado.txt").write_text("mal\n", encoding="utf-8")
        (self.repo / "nuevo.txt").write_text("mal\n", encoding="utf-8")
        (self.repo / ".agent-task.md").write_text("contexto\n", encoding="utf-8")
        (self.repo / ".qwen").mkdir()
        (self.repo / ".qwen" / "telemetry.log").write_text("x\n", encoding="utf-8")

        resultado = guard.ejecutar(self.repo, self.plan, restaurar=False)

        self.assertEqual(resultado["changed_allowed"], ["permitido.txt"])
        self.assertEqual(resultado["outside"], ["bloqueado.txt", "nuevo.txt"])

    def test_restore_elimina_solo_desvio_y_conserva_el_claim(self):
        (self.repo / "permitido.txt").write_text("cambio válido\n", encoding="utf-8")
        (self.repo / "bloqueado.txt").write_text("cambio inválido\n", encoding="utf-8")
        (self.repo / "nuevo.txt").write_text("nuevo inválido\n", encoding="utf-8")

        resultado = guard.ejecutar(self.repo, self.plan, restaurar=True)

        self.assertTrue(resultado["restored"])
        self.assertEqual(
            (self.repo / "permitido.txt").read_text(encoding="utf-8"),
            "cambio válido\n",
        )
        self.assertEqual(
            (self.repo / "bloqueado.txt").read_text(encoding="utf-8"),
            "base\n",
        )
        self.assertFalse((self.repo / "nuevo.txt").exists())
        self.assertEqual(guard.rutas_cambiadas(self.repo), {"permitido.txt"})

    def test_rechaza_rutas_que_escapan_del_repo(self):
        self.plan.write_text(
            json.dumps({"files": ["../fuera.txt"], "goal": "mal"}),
            encoding="utf-8",
        )
        with self.assertRaises(ValueError):
            guard.cargar_plan(self.plan)

    def test_workflow_replanifica_en_vez_de_pedir_humano_al_primer_desvio(self):
        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("Normalizar cambios al CLAIM", workflow)
        self.assertIn("scripts/agent_claim_guard.py", workflow)
        self.assertIn("AUTOPILOT_REPLAN", workflow)
        self.assertIn("MAX_REPLANS: '2'", workflow)
        self.assertIn("gh workflow run agent-autopilot.yml", workflow)
        self.assertIn("motivo=autopilot-replan-claim-incompleto", workflow)
        self.assertIn('select(startswith("AUTOPILOT_REPLAN "))', workflow)
        gemini = workflow.split("name: Implementar con Gemini", 1)[1].split(
            "uses: google-github-actions/run-gemini-cli@v0", 1
        )[0]
        self.assertIn("continue-on-error: true", gemini)
        self.assertIn("steps.claim_guard.outputs.drift != 'true'", workflow)


    def test_worker_pool_replanifica_en_vez_de_escalar_el_primer_desvio(self):
        workflow = WORKER_WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("Normalizar cambios al CLAIM", workflow)
        self.assertIn("scripts/agent_claim_guard.py", workflow)
        self.assertIn("AGENT_POOL_REPLAN", workflow)
        self.assertIn("MAX_REPLANS: '2'", workflow)
        self.assertIn("gh workflow run agent-worker.yml", workflow)
        self.assertIn("motivo=agent-pool-replan-claim-incompleto", workflow)
        self.assertIn('select(startswith("AGENT_POOL_REPLAN "))', workflow)
        self.assertIn("steps.claim_guard.outputs.drift == 'true'", workflow)
        self.assertIn("steps.claim_guard.outputs.drift != 'true'", workflow)
        qwen = workflow.split("name: Implementar con Qwen", 1)[1].split(
            "uses: QwenLM/qwen-code-action@v1", 1
        )[0]
        gemini = workflow.split("name: Implementar con Gemini", 1)[1].split(
            "uses: google-github-actions/run-gemini-cli@v0", 1
        )[0]
        self.assertIn("continue-on-error: true", qwen)
        self.assertIn("continue-on-error: true", gemini)
        self.assertIn("observed_paths", workflow)


if __name__ == "__main__":
    unittest.main()
