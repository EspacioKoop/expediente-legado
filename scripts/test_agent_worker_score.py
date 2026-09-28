import importlib.util
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_worker_score.py"
SPEC = importlib.util.spec_from_file_location("agent_worker_score", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class AgentWorkerScoreTest(unittest.TestCase):
    def test_success_supera_failure(self):
        scores = mod.score_jobs(
            [
                {"name": "run (1, qwen, qwen-primary) / worker", "conclusion": "success"},
                {"name": "run (2, qwen, qwen-fallback-1) / worker", "conclusion": "failure"},
            ]
        )
        self.assertGreater(
            scores["qwen-primary"]["score"],
            scores["qwen-fallback-1"]["score"],
        )

    def test_recencia_pesa_mas(self):
        scores = mod.score_jobs(
            [
                {"name": "run (3, gemini, gemini) / worker", "conclusion": "success"},
                {"name": "run (4, gemini, gemini) / worker", "conclusion": "failure"},
            ]
        )
        self.assertGreater(scores["gemini"]["score"], 50.0)

    def test_cancelled_penaliza_menos_que_failure(self):
        scores = mod.score_jobs(
            [
                {"name": "run (5, qwen, a) / worker", "conclusion": "cancelled"},
                {"name": "run (6, qwen, b) / worker", "conclusion": "failure"},
            ]
        )
        self.assertGreater(scores["a"]["score"], scores["b"]["score"])

    def test_ignora_jobs_no_worker(self):
        scores = mod.score_jobs(
            [{"name": "godot", "conclusion": "success"}]
        )
        self.assertEqual({}, scores)


if __name__ == "__main__":
    unittest.main()
