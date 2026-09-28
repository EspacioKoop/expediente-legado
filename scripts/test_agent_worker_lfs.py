from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKER = ROOT / ".github" / "workflows" / "agent-worker.yml"
CI = ROOT / ".github" / "workflows" / "ci.yml"


def checkout_block(text: str) -> str:
    marker = "uses: actions/checkout@v4"
    start = text.index(marker)
    rest = text[start:]
    next_step = rest.find("\n      - ", len(marker))
    return rest if next_step < 0 else rest[:next_step]


class AgentWorkerLfsTest(unittest.TestCase):
    def test_worker_materializa_lfs_igual_que_ci_canonico(self):
        worker = checkout_block(WORKER.read_text(encoding="utf-8"))
        canonical = checkout_block(CI.read_text(encoding="utf-8"))
        self.assertIn("lfs: true", canonical)
        self.assertIn("lfs: true", worker)

    def test_worker_conserva_checkout_de_main_y_sin_credencial_persistente(self):
        worker = checkout_block(WORKER.read_text(encoding="utf-8"))
        self.assertIn("ref: main", worker)
        self.assertIn("fetch-depth: 0", worker)
        self.assertIn("persist-credentials: false", worker)


if __name__ == "__main__":
    unittest.main()
