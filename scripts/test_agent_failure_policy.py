import importlib.util
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_failure_policy.py"
SPEC = importlib.util.spec_from_file_location("agent_failure_policy", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class AgentFailurePolicyTest(unittest.TestCase):
    def test_quota_y_overload_rotan_provider(self):
        for text in (
            "HTTP 429",
            "503 Service temporarily overloaded",
            "RESOURCE_EXHAUSTED",
            "rate limit exceeded",
        ):
            with self.subTest(text=text):
                result = mod.classify_failure(stage="implementing", text=text)
                self.assertEqual("quota_or_overload", result["category"])
                self.assertEqual("rotate_provider", result["action"])

    def test_claim_drift_pide_expandir_claim_y_gana_a_texto(self):
        result = mod.classify_failure(
            stage="implementing",
            claim_drift=True,
            text="503 overloaded",
        )
        self.assertEqual("claim_drift", result["category"])
        self.assertEqual("expand_claim", result["action"])

    def test_no_changes_no_cambia_de_worker(self):
        result = mod.classify_failure(stage="implementing", no_changes=True)
        self.assertEqual("no_changes", result["category"])
        self.assertEqual("stop_noop", result["action"])

    def test_cancelacion_es_neutral(self):
        result = mod.classify_failure(
            stage="validating",
            job_status="cancelled",
            text="AssertionError",
        )
        self.assertEqual("cancelled", result["category"])
        self.assertEqual("requeue_neutral", result["action"])

    def test_timeout_o_turn_limit_no_se_trata_como_cuota(self):
        for text in ("operation timed out", "FatalTurnLimitedError", "maxSessionTurns"):
            with self.subTest(text=text):
                result = mod.classify_failure(stage="implementing", text=text)
                self.assertEqual("timeout", result["category"])
                self.assertEqual("split_or_same_worker", result["action"])

    def test_fallo_de_test_conserva_worker(self):
        for text in (
            "AssertionError: expected true",
            "would reformat godot/guion/x.gd",
            "gdlint: max-returns",
        ):
            with self.subTest(text=text):
                result = mod.classify_failure(stage="preflight", text=text)
                self.assertEqual("test_or_preflight", result["category"])
                self.assertEqual("same_worker_fix", result["action"])

    def test_transporte_roto_rota_provider(self):
        result = mod.classify_failure(
            stage="implementing",
            text="connection reset by peer",
        )
        self.assertEqual("provider_or_transport", result["category"])
        self.assertEqual("rotate_provider", result["action"])

    def test_desconocido_escala_a_humano(self):
        result = mod.classify_failure(stage="publishing", text="fallo raro")
        self.assertEqual("unknown", result["category"])
        self.assertEqual("human_review", result["action"])


if __name__ == "__main__":
    unittest.main()
