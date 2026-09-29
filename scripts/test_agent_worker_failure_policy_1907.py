from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKER = (ROOT / ".github" / "workflows" / "agent-worker.yml").read_text(encoding="utf-8")


class AgentWorkerFailurePolicy1907Test(unittest.TestCase):
    def test_retry_hint_es_input_y_entra_en_el_prompt_concreto(self):
        self.assertGreaterEqual(WORKER.count("retry_hint:"), 2)
        protocol = WORKER.split("- id: protocol", 1)[1].split("- id: b2b_inbox", 1)[0]
        self.assertIn("RETRY_HINT: ${{ inputs.retry_hint || '' }}", protocol)
        self.assertIn("## Feedback del intento anterior", protocol)
        self.assertIn("head -c 1200", protocol)

    def test_preflight_expone_stage_y_log_acotable(self):
        validate = WORKER.split("- id: validate_diff", 1)[1].split(
            "- id: b2b_review_handoff", 1
        )[0]
        self.assertIn("/tmp/agent-preflight-failure.log", validate)
        self.assertIn('echo "retry_stage=preflight" >> "$GITHUB_OUTPUT"', validate)
        self.assertIn("scripts/agent_preflight.py", validate)

    def test_cleanup_clasifica_antes_de_actuar(self):
        cleanup = WORKER.split("- name: Limpiar fallo o cancelacion", 1)[1].split(
            "- name: Liberar lease Deno KV", 1
        )[0]
        classify = cleanup.index("scripts/agent_failure_policy.py")
        same = cleanup.index("same_worker_fix|split_or_same_worker)")
        rotate = cleanup.index("rotate_provider)")
        noop = cleanup.index("stop_noop)")
        self.assertLess(classify, same)
        self.assertLess(classify, rotate)
        self.assertLess(classify, noop)
        self.assertIn("--text-file", cleanup)

    def test_solo_rotacion_marca_worker_como_fallido(self):
        cleanup = WORKER.split("- name: Limpiar fallo o cancelacion", 1)[1].split(
            "- name: Liberar lease Deno KV", 1
        )[0]
        rotate = cleanup.split("rotate_provider)", 1)[1].split("human_review|*)", 1)[0]
        same = cleanup.split("same_worker_fix|split_or_same_worker)", 1)[1].split(
            "rotate_provider)", 1
        )[0]
        noop = cleanup.split("stop_noop)", 1)[1].split(
            "same_worker_fix|split_or_same_worker)", 1
        )[0]
        self.assertIn("AGENT_POOL_WORKER_FAILURE", rotate)
        self.assertNotIn("AGENT_POOL_WORKER_FAILURE", same)
        self.assertNotIn("AGENT_POOL_WORKER_FAILURE", noop)

    def test_same_worker_tiene_un_solo_retry_y_feedback(self):
        cleanup = WORKER.split("- name: Limpiar fallo o cancelacion", 1)[1].split(
            "- name: Liberar lease Deno KV", 1
        )[0]
        same = cleanup.split("same_worker_fix|split_or_same_worker)", 1)[1].split(
            "rotate_provider)", 1
        )[0]
        self.assertIn("if (( previous >= 1 )); then", same)
        self.assertIn("AGENT_POOL_SAME_WORKER_RETRY", same)
        self.assertIn('-f worker="$WORKER"', same)
        self.assertIn('-f retry_hint="$retry_hint"', same)

    def test_no_changes_para_sin_penalizar(self):
        cleanup = WORKER.split("- name: Limpiar fallo o cancelacion", 1)[1].split(
            "- name: Liberar lease Deno KV", 1
        )[0]
        noop = cleanup.split("stop_noop)", 1)[1].split(
            "same_worker_fix|split_or_same_worker)", 1
        )[0]
        self.assertIn("--add-label agent:needs-human", noop)
        self.assertIn("No se penaliza ni rota el worker", noop)


if __name__ == "__main__":
    unittest.main()
