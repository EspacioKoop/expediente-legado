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
        self.assertIn("id-token: write", self.workflow)
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

    def test_cualquier_slot_y_fallback1_es_smoke_de_merge(self):
        # #1685: un solo paso para cualquier QWEN_FALLBACK_N; nada de pasos por slot.
        self.assertIn("SLOT_N: ${{ github.event_name == 'push' && 1 || inputs.slot }}", self.workflow)
        self.assertIn("format('qwen-fallback-{0}'", self.workflow)
        self.assertIn("python3 scripts/agent_slots.py resolver", self.workflow)
        self.assertIn("python3 scripts/agent_slots.py secreto", self.workflow)
        self.assertIn("openai_api_key: ${{ secrets[steps.slot.outputs.secret] }}", self.workflow)
        self.assertNotIn("smoke_f1", self.workflow)
        self.assertNotIn("QWEN_FALLBACK_2_API_KEY", self.workflow)

    def test_exige_tool_call_y_marcador_verificable(self):
        self.assertIn("Usa obligatoriamente read_file para leer AGENTS.md", self.workflow)
        self.assertIn("AGENT_PROVIDER_SMOKE_OK file=AGENTS.md", self.workflow)
        self.assertIn("grep -Fq", self.workflow)

    def test_smoke_verde_cierra_circuit_breaker(self):
        self.assertIn("Cerrar circuit breaker del slot", self.workflow)
        self.assertIn("siga98-agent-pool", self.workflow)
        self.assertIn("/api/agent-pool/worker-health/report", self.workflow)
        self.assertIn('status:"healthy"', self.workflow)

    def test_no_expone_la_key_en_pasos_shell(self):
        bloque = self.workflow.split("- id: config", 1)[1].split("- id: smoke", 1)[0]
        # En el paso shell solo entra si hay clave, nunca la clave.
        self.assertIn(
            "SLOT_HAS_KEY: ${{ steps.slot.outputs.secret != '' && secrets[steps.slot.outputs.secret] != '' }}",
            bloque,
        )
        self.assertNotRegex(bloque, r"secrets\[steps\.slot\.outputs\.secret\] \}\}")

if __name__ == "__main__":
    unittest.main()
