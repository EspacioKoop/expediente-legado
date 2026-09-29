"""Contrato de integración del protocolo B2B v1 en el worker."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = (ROOT / ".github" / "workflows" / "agent-worker.yml").read_text(encoding="utf-8")
CLAIM_GUARD = (ROOT / "scripts" / "agent_claim_guard.py").read_text(encoding="utf-8")


def step(marker: str) -> str:
    start = WORKFLOW.index(marker)
    end = WORKFLOW.find("\n      - ", start + len(marker))
    return WORKFLOW[start:] if end < 0 else WORKFLOW[start:end]


class AgentWorkerProtocolTest(unittest.TestCase):
    def test_taskpacket_se_compila_antes_de_implementar(self):
        protocol = WORKFLOW.index("- id: protocol\n")
        branch = WORKFLOW.index("- name: Crear rama\n")
        qwen = WORKFLOW.index("- id: implement_qwen\n")
        self.assertLess(protocol, branch)
        self.assertLess(branch, qwen)
        block = step("- id: protocol\n")
        self.assertIn("scripts/agent_protocol.py task", block)
        self.assertIn("scripts/agent_protocol.py prompt", block)
        self.assertIn(".agent-task-packet.json", block)
        self.assertIn(".agent-worker-prompt.md", block)
        self.assertIn("git rev-parse HEAD", block)

    def test_blocker_b2b_llega_al_planner_antes_del_plan(self):
        inbox = WORKFLOW.index("- id: b2b_plan_inbox\n")
        qwen = WORKFLOW.index("- id: plan_qwen\n")
        self.assertLess(inbox, qwen)
        block = step("- id: b2b_plan_inbox\n")
        self.assertIn("/api/agent-pool/b2b/inbox", block)
        self.assertIn('recipient:"worker"', block)
        self.assertIn("git rev-parse HEAD", block)
        self.assertIn(".agent-b2b-inbox.md", block)

        for planner in ("plan_qwen", "plan_gemini"):
            plan = step(f"- id: {planner}\n")
            self.assertIn(".agent-b2b-inbox.md si existe", plan)
            self.assertIn("BLOCKER de CLAIM", plan)

    def test_mailbox_b2b_se_lee_antes_de_implementar(self):
        inbox = WORKFLOW.index("- id: b2b_inbox\n")
        qwen = WORKFLOW.index("- id: implement_qwen\n")
        self.assertLess(inbox, qwen)
        block = step("- id: b2b_inbox\n")
        self.assertIn("/api/agent-pool/b2b/inbox", block)
        self.assertIn('recipient:"worker"', block)
        self.assertIn("steps.protocol.outputs.task_id", block)
        self.assertIn(".agent-b2b-inbox.md", block)
        self.assertIn("continue-on-error: true", block)

        ack = step("- name: Confirmar inbox B2B consumido\n")
        self.assertIn("/api/agent-pool/b2b/ack", ack)
        self.assertIn("steps.implement_qwen.outcome == 'success'", ack)
        self.assertIn("steps.implement_gemini.outcome == 'success'", ack)
        self.assertGreater(
            WORKFLOW.index("- name: Confirmar inbox B2B consumido\n"),
            WORKFLOW.index("- id: implement_gemini\n"),
        )

    def test_claim_drift_envia_blocker_al_dispatcher_y_conserva_fallback(self):
        block = step("- id: replan\n")
        self.assertIn("/api/agent-pool/b2b/send", block)
        self.assertIn('message_type:"BLOCKER"', block)
        self.assertIn("for recipient in dispatcher worker", block)
        self.assertIn('recipient:$recipient', block)
        self.assertIn("claim-drift-", block)
        self.assertIn(".outside[]", block)
        self.assertIn("AGENT_POOL_REPLAN", block)

    def test_workers_consumen_el_prompt_compilado(self):
        for worker_step in ("implement_qwen", "implement_gemini"):
            with self.subTest(worker=worker_step):
                block = step(f"- id: {worker_step}\n")
                self.assertIn("Lee .agent-worker-prompt.md", block)
                self.assertIn(".agent-task-packet.json", block)
                self.assertNotIn("Lee AGENTS.md", block)

    def test_resultado_se_normaliza_despues_del_claim_guard(self):
        claim = WORKFLOW.index("- id: claim_guard\n")
        result = WORKFLOW.index("- id: result_contract\n")
        validate = WORKFLOW.index("- id: validate_diff\n")
        self.assertLess(claim, result)
        self.assertLess(result, validate)
        block = step("- id: result_contract\n")
        self.assertIn("scripts/agent_protocol.py result", block)
        self.assertIn(".changed_allowed[]", block)
        self.assertIn("continue-on-error: true", block)
        self.assertIn("handoff_loss", block)

    def test_artefactos_del_protocolo_no_contaminan_claim_ni_diff(self):
        self.assertIn('".agent-task-packet.json"', CLAIM_GUARD)
        self.assertIn('".agent-worker-prompt.md"', CLAIM_GUARD)
        validate = step("- id: validate_diff\n")
        self.assertIn(".agent-task-packet.json", validate)
        self.assertIn(".agent-worker-prompt.md", validate)
        self.assertIn(".agent-b2b-inbox.md", WORKFLOW)

    def test_review_es_un_mensaje_b2b_tipado(self):
        self.assertGreaterEqual(WORKFLOW.count('"message_type":"REVIEW"'), 2)

    def test_pr_expone_metricas_del_handoff(self):
        publish = step("- name: Publicar PR draft y lanzar CI canonica\n")
        self.assertIn("RESULT_VALID:", publish)
        self.assertIn("RESULT_STATUS:", publish)
        self.assertIn("HANDOFF_LOSS:", publish)
        self.assertIn("handoff-loss proxy", publish)


if __name__ == "__main__":
    unittest.main()
