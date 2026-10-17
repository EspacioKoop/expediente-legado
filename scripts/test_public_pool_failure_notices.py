"""Pruebas del recorte de información operativa en avisos públicos del pool.

Los identificadores worker/provider de los tres marcadores machine-readable
siguen intactos hasta contar con persistencia privada equivalente.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github/workflows/agent-worker.yml"


class PublicPoolNoticesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.worker = WORKFLOW.read_text(encoding="utf-8")

    def test_human_failure_notices_do_not_expose_slot_name(self):
        visible = re.findall(r'"(Agent pool[^"\n]+)"', self.worker)
        self.assertGreaterEqual(len(visible), 6)
        for message in visible:
            with self.subTest(message=message[:35]):
                self.assertNotIn("$WORKER", message)
                self.assertNotIn("$PROVIDER", message)

    def test_machine_markers_still_preserve_retry_contracts(self):
        for contract in [
            "AGENT_POOL_SAME_WORKER_RETRY category=$category worker=$WORKER",
            "AGENT_POOL_SLOT_UNHEALTHY worker=$WORKER provider=$PROVIDER",
            "AGENT_POOL_WORKER_FAILURE worker=$WORKER provider=$PROVIDER",
            'pattern=re.compile(r"^AGENT_POOL_WORKER_FAILURE',
        ]:
            with self.subTest(contract=contract):
                self.assertIn(contract, self.worker)

    def test_public_notices_still_explain_outcome(self):
        self.assertIn("sin diff para la tarea mono-fichero", self.worker)
        self.assertIn("se repitió en el mismo slot", self.worker)
        self.assertIn("agotó los workers compatibles", self.worker)
        self.assertIn("reencolado tras $category", self.worker)
        self.assertIn("AGENT_PLAN delegado no ejecutable; revisar el registro", self.worker)
        self.assertIn("se ha detectado un solape de CLAIM", self.worker)
        self.assertNotIn("AGENT_PLAN delegado no ejecutable ($reason)", self.worker)
        self.assertNotIn("$(grep '^reason='", self.worker)


if __name__ == "__main__":
    unittest.main()
