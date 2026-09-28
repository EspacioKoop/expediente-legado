from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "agent-provider-smoke.yml"


class AgentProviderSmokeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_es_solo_lectura_y_sin_permisos_de_escritura(self):
        self.assertIn("permissions:\n  contents: read", self.workflow)
        self.assertIn('"tools":{"core":["read_file"]}', self.workflow)
        for prohibido in (
            '"write_file"',
            '"edit"',
            '"replace"',
            '"run_shell_command"',
            "contents: write",
            "pull-requests: write",
            "issues: write",
            "git push",
            "gh issue",
            "gh pr",
        ):
            self.assertNotIn(prohibido, self.workflow)

    def test_cubre_los_cuatro_slots_y_fallback1_es_smoke_de_merge(self):
        self.assertIn("github.event_name == 'push' && 'qwen-fallback-1'", self.workflow)
        for numero in range(1, 5):
            self.assertIn(f"qwen-fallback-{numero}", self.workflow)
            self.assertIn(f"QWEN_FALLBACK_{numero}_API_KEY", self.workflow)
            self.assertIn(f"QWEN_FALLBACK_{numero}_BASE_URL", self.workflow)
            self.assertIn(f"QWEN_FALLBACK_{numero}_MODEL", self.workflow)

    def test_exige_tool_call_y_marcador_verificable(self):
        self.assertIn("Usa obligatoriamente read_file para leer AGENTS.md", self.workflow)
        self.assertIn("AGENT_PROVIDER_SMOKE_OK file=AGENTS.md", self.workflow)
        self.assertIn("grep -Fq", self.workflow)

    def test_no_expone_la_key_en_pasos_shell(self):
        bloque = self.workflow.split("- id: config", 1)[1].split("- id: smoke_f1", 1)[0]
        self.assertNotIn("QWEN_FALLBACK_1_API_KEY:", bloque)
        self.assertIn("secrets.QWEN_FALLBACK_1_API_KEY != ''", bloque)


if __name__ == "__main__":
    unittest.main()
