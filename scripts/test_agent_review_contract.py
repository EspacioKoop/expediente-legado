import importlib.util
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_review_contract.py"
SPEC = importlib.util.spec_from_file_location("agent_review_contract", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class AgentReviewContractTest(unittest.TestCase):
    def test_approve(self):
        raw = 'AGENT_REVIEW_BEGIN {"verdict":"approve","findings":[]} AGENT_REVIEW_END'
        self.assertEqual(
            {"status": "ok", "verdict": "approve", "findings": []},
            mod.parse_review(raw),
        )

    def test_findings_limitados(self):
        raw = """AGENT_REVIEW_BEGIN
        ```json
        {"verdict":"findings","findings":["uno","dos","tres","cuatro","cinco","seis"]}
        ```
        AGENT_REVIEW_END"""
        result = mod.parse_review(raw)
        self.assertEqual("ok", result["status"])
        self.assertEqual("findings", result["verdict"])
        self.assertEqual(5, len(result["findings"]))

    def test_sin_contrato_es_skipped(self):
        self.assertEqual("skipped", mod.parse_review("sigo pensando")["status"])

    def test_findings_vacios_no_bloquean(self):
        raw = 'AGENT_REVIEW_BEGIN {"verdict":"findings","findings":[]} AGENT_REVIEW_END'
        self.assertEqual("skipped", mod.parse_review(raw)["status"])

    def test_workflow_reviewer_tiene_presupuesto_duro_y_sin_retry(self):
        workflow = (
            ROOT / ".github" / "workflows" / "agent-worker.yml"
        ).read_text(encoding="utf-8")
        self.assertIn('maxSessionTurns":4', workflow)
        self.assertIn("timeout-minutes: 3", workflow)
        self.assertIn('"core":["read_file"]', workflow)
        self.assertIn("Reviewer acotado (advisory; sin retries automaticos)", workflow)
        self.assertNotIn("review_retry", workflow)

    def test_con_nonce_que_coincide_el_veredicto_vale(self):
        raw = (
            'AGENT_REVIEW_BEGIN {"input_nonce":"a1b2c3d4","verdict":"findings",'
            '"findings":["B sin cargar"]} AGENT_REVIEW_END'
        )
        self.assertEqual(
            {"status": "ok", "verdict": "findings", "findings": ["B sin cargar"]},
            mod.parse_review(raw, "a1b2c3d4"),
        )

    def test_approve_sin_nonce_es_revision_a_ciegas(self):
        # #2016: el modelo no abrió el input y aun así devolvió JSON válido (#2038).
        raw = 'AGENT_REVIEW_BEGIN {"verdict":"approve","findings":[]} AGENT_REVIEW_END'
        self.assertEqual(
            {"status": "blind", "verdict": None, "findings": []},
            mod.parse_review(raw, "a1b2c3d4"),
        )

    def test_nonce_inventado_es_revision_a_ciegas(self):
        raw = (
            'AGENT_REVIEW_BEGIN {"input_nonce":"<código>","verdict":"findings",'
            '"findings":["no hay diff"]} AGENT_REVIEW_END'
        )
        self.assertEqual("blind", mod.parse_review(raw, "a1b2c3d4")["status"])

    def test_workflow_cablea_el_nonce_de_lectura(self):
        workflow = (
            ROOT / ".github" / "workflows" / "agent-worker.yml"
        ).read_text(encoding="utf-8")
        self.assertIn("review_nonce=", workflow)
        self.assertIn("steps.validate_diff.outputs.review_nonce", workflow)
        self.assertIn('--nonce "${REVIEW_NONCE:-}"', workflow)
        prompts = [
            line for line in workflow.splitlines() if ".agent-review-input.md" in line and "prompt:" in line
        ]
        self.assertEqual(2, len(prompts), "prompts Qwen y Gemini")
        for prompt in prompts:
            self.assertIn('"input_nonce"', prompt)

    def test_json_invalido_es_skipped(self):
        raw = "AGENT_REVIEW_BEGIN {mal json} AGENT_REVIEW_END"
        self.assertEqual("skipped", mod.parse_review(raw)["status"])


if __name__ == "__main__":
    unittest.main()
