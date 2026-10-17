"""Regresión: el proveedor queda fuera de la metadata publicada en GitHub.

Los IDs de issue, run y tipo de coordinador son suficientes para trazar la
tarea; no es necesario exponer cuentas/slots en título, rama, CLAIM o enlace.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1] / ".github" / "workflows"


class PublicAgentMetadataTest(unittest.TestCase):
    def test_pool_uses_neutral_public_identifiers(self):
        src = (ROOT / "agent-worker.yml").read_text(encoding="utf-8")
        self.assertIn('branch="agent/pool-${ISSUE}-${GITHUB_RUN_ID}"', src)
        self.assertIn('agent=Pool branch=$BRANCH', src)
        self.assertIn('--title "agent: #$ISSUE $title"', src)
        self.assertIn('"Agent pool: $url"', src)
        self.assertNotIn('agent($PROVIDER): #$ISSUE', src)
        self.assertNotIn('agent=Pool-$PROVIDER', src)
        self.assertNotIn('agent/${PROVIDER}', src)
        self.assertNotIn('con $WORKER"', src)
        self.assertIn('git commit -m "agent: avanzar #$ISSUE con pool"', src)

    def test_autopilot_uses_neutral_public_identifiers(self):
        src = (ROOT / "agent-autopilot.yml").read_text(encoding="utf-8")
        self.assertIn('branch=agent/autopilot-${ISSUE}-${GITHUB_RUN_ID}', src)
        self.assertIn('agent=Autopilot branch=$BRANCH', src)
        self.assertIn('--title "agent: #$ISSUE $title"', src)
        self.assertIn('"Agent autopilot: $url"', src)
        self.assertNotIn('agent($PROVIDER): #$ISSUE', src)
        self.assertNotIn('agent=Autopilot-$PROVIDER', src)
        self.assertNotIn('branch=agent/${provider}-', src)
        self.assertIn('git commit -m "agent: avanzar #$ISSUE con autopilot"', src)

    def test_run_id_still_remains_last_for_reconciler(self):
        # El parser de agent_reconciler._run_id depende de sufijo -<run>.
        self.assertRegex("agent/pool-123-456", r"-(\d+)$")
        self.assertRegex("agent/autopilot-123-456", r"-(\d+)$")


if __name__ == "__main__":
    unittest.main()
