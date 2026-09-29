from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKER = ROOT / ".github" / "workflows" / "agent-worker.yml"
CI = ROOT / ".github" / "workflows" / "ci.yml"


def checkout_block(text: str) -> str:
    match = re.search(r"uses:\s*actions/checkout@[0-9a-f]{40}(?:\s*#.*)?", text)
    if match is None:
        raise AssertionError("el worker debe fijar actions/checkout a un SHA completo")
    rest = text[match.start():]
    next_step = rest.find("\n      - ", len(match.group(0)))
    return rest if next_step < 0 else rest[:next_step]


class AgentWorkerLfsTest(unittest.TestCase):
    def test_worker_y_ci_completo_materializan_lfs(self):
        worker_text = WORKER.read_text(encoding="utf-8")
        ci_text = CI.read_text(encoding="utf-8")
        worker = checkout_block(worker_text)

        # El worker siempre necesita los assets del repo al implementar.
        self.assertIn("lfs: true", worker)

        # El CI canónico difiere la descarga hasta saber si el diff requiere
        # el recorrido completo; el fast-path no debe pagar ese coste.
        self.assertIn("name: Materializar LFS para CI completo", ci_text)
        self.assertIn("if: steps.scope.outputs.mode == 'full'", ci_text)
        self.assertIn("git lfs pull", ci_text)

    def test_worker_conserva_checkout_de_main_y_sin_credencial_persistente(self):
        worker = checkout_block(WORKER.read_text(encoding="utf-8"))
        self.assertIn("ref: main", worker)
        self.assertIn("fetch-depth: 0", worker)
        self.assertIn("persist-credentials: false", worker)


if __name__ == "__main__":
    unittest.main()
