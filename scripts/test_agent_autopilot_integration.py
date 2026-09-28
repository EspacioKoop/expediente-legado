import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "agent-autopilot.yml"


class AgentAutopilotIntegrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_kev_router_se_ejecuta_tras_checkout(self):
        checkout = self.workflow.index("- name: Checkout")
        router = self.workflow.index("- id: route")
        qwen = self.workflow.index("- id: qwen")
        self.assertLess(checkout, router)
        self.assertLess(router, qwen)
        self.assertIn("python3 scripts/kev_router.py", self.workflow)
        self.assertIn("KEV_BASE_URL: ${{ vars.KEV_BASE_URL }}", self.workflow)
        self.assertIn("KEV_API_KEY: ${{ secrets.KEV_API_KEY }}", self.workflow)

    def test_router_recibe_estado_acotado_y_respeta_proveedor_explicito(self):
        self.assertIn("--json title,body,labels", self.workflow)
        self.assertIn("--requested-provider \"$REQUESTED_PROVIDER\"", self.workflow)
        self.assertNotIn("steps.select.outputs.provider", self.workflow)
        self.assertIn("steps.route.outputs.provider", self.workflow)
        self.assertIn("requested_provider=$provider", self.workflow)

    def test_context_packer_se_genera_y_refina(self):
        self.assertEqual(
            2,
            self.workflow.count("python3 scripts/agent_context_pack.py"),
        )
        self.assertIn("--output .agent-context.md", self.workflow)
        self.assertIn('args+=(--path "$file")', self.workflow)
        self.assertIn(
            ".agent-plan.json, .agent-context.md, .agent-memory.json",
            self.workflow,
        )
        self.assertIn(
            ".agent-task.md, .agent-context.md, .agent-memory.json",
            self.workflow,
        )

    def test_contexto_temporal_no_se_publica_en_el_pr(self):
        self.assertIn(
            "rm -f .agent-task.md .agent-plan.json .agent-context.md .agent-memory.json",
            self.workflow,
        )


if __name__ == "__main__":
    unittest.main()
