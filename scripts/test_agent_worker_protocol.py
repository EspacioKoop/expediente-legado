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

    def test_taskpacket_solo_se_compila_con_plan_delegado(self):
        delegated = WORKFLOW.index("- id: delegated\n")
        reserve = WORKFLOW.index("- id: reserve\n")
        protocol = WORKFLOW.index("- id: protocol\n")
        self.assertLess(delegated, reserve)
        self.assertLess(reserve, protocol)
        self.assertNotIn("- id: plan_qwen\n", WORKFLOW)
        self.assertNotIn("- id: plan_gemini\n", WORKFLOW)
        block = step("- id: protocol\n")
        self.assertIn("--max-files", block)
        self.assertIn("agent_scope_limit.py --issue-json /tmp/agent-issue.json", block)

    def test_mailbox_b2b_se_refresca_antes_de_implementar(self):
        protocol = WORKFLOW.index("- id: protocol\n")
        inbox = WORKFLOW.index("- id: b2b_inbox\n")
        qwen = WORKFLOW.index("- id: implement_qwen\n")
        self.assertLess(protocol, inbox)
        self.assertLess(inbox, qwen)
        block = step("- id: b2b_inbox\n")
        self.assertIn("scripts/agent_b2b_mailbox.py", block)
        self.assertIn("inbox --recipient worker", block)
        self.assertIn("steps.protocol.outputs.task_id", block)
        self.assertIn("continue-on-error: true", block)

    def test_ack_ocurre_solo_tras_consumo_del_implementer(self):
        ack = step("- name: Confirmar inbox B2B consumido\n")
        self.assertIn("scripts/agent_b2b_mailbox.py ack", ack)
        self.assertIn("steps.implement_qwen.outcome == 'success'", ack)
        self.assertIn("steps.implement_gemini.outcome == 'success'", ack)
        self.assertGreater(
            WORKFLOW.index("- name: Confirmar inbox B2B consumido\n"),
            WORKFLOW.index("- id: implement_gemini\n"),
        )

    def test_claim_drift_envia_blocker_y_conserva_fallback_github(self):
        block = step("- id: replan\n")
        self.assertIn("scripts/agent_b2b_mailbox.py", block)
        self.assertIn("--type BLOCKER", block)
        self.assertIn("for recipient in dispatcher worker", block)
        self.assertIn("claim-drift-", block)
        self.assertIn(".outside[]", block)
        self.assertIn("AGENT_POOL_REPLAN", block)

    def test_handoff_b2b_llega_al_reviewer_antes_de_revisar(self):
        result = WORKFLOW.index("- id: result_contract\n")
        handoff = WORKFLOW.index("- id: b2b_review_handoff\n")
        review = WORKFLOW.index("- id: review_qwen\n")
        self.assertLess(result, handoff)
        self.assertLess(handoff, review)

        block = step("- id: b2b_review_handoff\n")
        self.assertIn("scripts/agent_b2b_mailbox.py send", block)
        self.assertIn("--type EVIDENCE", block)
        self.assertIn("--type HANDOFF", block)
        self.assertIn("--recipient reviewer", block)
        self.assertIn("inbox --recipient reviewer", block)
        self.assertIn(".agent-review-input.md", block)
        self.assertIn("idempotency-key", block)

    def test_result_review_y_blocker_vuelven_al_dispatcher(self):
        normalized = WORKFLOW.index("- id: review_contract\n")
        publish = WORKFLOW.index("- id: b2b_review_publish\n")
        memory = WORKFLOW.index("- name: Guardar memoria de trabajo\n")
        self.assertLess(normalized, publish)
        self.assertLess(publish, memory)

        block = step("- id: b2b_review_publish\n")
        self.assertIn("--type RESULT", block)
        self.assertIn("--type REVIEW", block)
        self.assertIn("--type BLOCKER", block)
        self.assertIn("--recipient dispatcher", block)
        self.assertIn('[[ "$RESULT_STATUS" == blocked ]]', block)
        self.assertIn("scripts/agent_b2b_mailbox.py ack", block)
        self.assertIn("--recipient reviewer", block)
        self.assertIn("steps.review_contract.outputs.verdict", block)

    def test_ack_reviewer_ocurre_despues_del_review_contract(self):
        review_contract = WORKFLOW.index("- id: review_contract\n")
        publish = WORKFLOW.index("- id: b2b_review_publish\n")
        self.assertGreater(publish, review_contract)
        block = step("- id: b2b_review_publish\n")
        self.assertIn("/tmp/agent-b2b-reviewer-inbox.json", block)
        self.assertIn(".messages[].message_id", block)

    def test_workers_consumen_el_prompt_compilado(self):
        for worker_step in ("implement_qwen", "implement_gemini"):
            with self.subTest(worker=worker_step):
                block = step(f"- id: {worker_step}\n")
                self.assertIn("Lee .agent-worker-prompt.md", block)
                self.assertIn("No leas ningun otro fichero de contexto", block)
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
