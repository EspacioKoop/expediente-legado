import importlib.util
import sys
import unittest
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_reconciler.py"
SPEC = importlib.util.spec_from_file_location("agent_reconciler", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


def issue(number, *labels, updated="2026-09-28T12:00:00Z"):
    return {
        "number": number,
        "updatedAt": updated,
        "labels": [{"name": label} for label in labels],
    }


def comment(body):
    return {"body": body}


class AgentReconcilerTest(unittest.TestCase):
    def setUp(self):
        self.now = datetime(2026, 9, 28, 16, 0, tzinfo=timezone.utc)

    def test_cancelled_pool_run_reencola(self):
        issues = [issue(667, "agent:auto", "agent:working")]
        comments = [
            comment(
                "CLAIM issue=#667 agent=Pool-qwen "
                "branch=agent/qwen-667-36422891769 "
                "files=a.gd,b.gd goal=x lease=48h"
            )
        ]
        runs = [
            {"id": 36422891769, "status": "completed", "conclusion": "cancelled"}
        ]
        actions = mod.reconcile(
            issues, comments, [], runs, now=self.now, ttl_minutes=90
        )
        self.assertEqual("requeue", actions[0]["action"])
        self.assertEqual("run-cancelled", actions[0]["reason"])

    def test_open_pr_normaliza_pr_open(self):
        issues = [issue(10, "agent:auto", "agent:working")]
        comments = [
            comment(
                "CLAIM issue=#10 agent=Pool-qwen "
                "branch=agent/qwen-10-12345 files=a goal=x lease=48h"
            )
        ]
        prs = [{"state": "OPEN", "headRefName": "agent/qwen-10-12345"}]
        actions = mod.reconcile(issues, comments, prs, [], now=self.now)
        self.assertEqual("pr_open", actions[0]["action"])

    def test_no_toca_claim_humano(self):
        issues = [issue(11, "agent:auto", "agent:working")]
        comments = [
            comment(
                "CLAIM issue=#11 agent=Odiseo "
                "branch=feature/11-x files=a goal=x lease=48h"
            )
        ]
        actions = mod.reconcile(issues, comments, [], [], now=self.now)
        self.assertEqual("keep", actions[0]["action"])
        self.assertEqual("non-pool-claim", actions[0]["reason"])

    def test_working_sin_claim_reencola(self):
        actions = mod.reconcile(
            [issue(12, "agent:auto", "agent:working")],
            [],
            [],
            [],
            now=self.now,
        )
        self.assertEqual("working-without-claim", actions[0]["reason"])

    def test_run_activo_se_conserva(self):
        issues = [issue(13, "agent:auto", "agent:working")]
        comments = [
            comment(
                "CLAIM issue=#13 agent=Pool-qwen "
                "branch=agent/qwen-13-99 files=a goal=x lease=48h"
            )
        ]
        runs = [{"id": 99, "status": "in_progress", "conclusion": None}]
        actions = mod.reconcile(issues, comments, [], runs, now=self.now)
        self.assertEqual("keep", actions[0]["action"])
        self.assertEqual("run-in_progress", actions[0]["reason"])

    def test_run_desconocido_solo_reencola_si_stale(self):
        issues = [
            issue(
                14,
                "agent:auto",
                "agent:working",
                updated="2026-09-28T12:00:00Z",
            )
        ]
        comments = [
            comment(
                "CLAIM issue=#14 agent=Pool-qwen "
                "branch=agent/qwen-14-100 files=a goal=x lease=48h"
            )
        ]
        actions = mod.reconcile(
            issues, comments, [], [], now=self.now, ttl_minutes=90
        )
        self.assertEqual("requeue", actions[0]["action"])
        self.assertEqual("stale-working", actions[0]["reason"])

    def test_release_elimina_claim_activo(self):
        comments = [
            comment(
                "CLAIM issue=#15 agent=Pool-qwen "
                "branch=agent/qwen-15-101 files=a goal=x lease=48h"
            ),
            comment(
                "RELEASE issue=#15 branch=agent/qwen-15-101 motivo=cancelled"
            ),
        ]
        self.assertEqual({}, mod.active_claims(comments))

    def test_discover_solo_runs_pool_working(self):
        issues = [
            issue(16, "agent:working"),
            issue(17, "agent:working"),
            issue(18, "agent:auto"),
        ]
        comments = [
            comment(
                "CLAIM issue=#16 agent=Pool-qwen "
                "branch=agent/qwen-16-102 files=a goal=x lease=48h"
            ),
            comment(
                "CLAIM issue=#17 agent=humano "
                "branch=feature/17-x files=a goal=x lease=48h"
            ),
        ]
        self.assertEqual([102], mod.discover_run_ids(issues, comments))


if __name__ == "__main__":
    unittest.main()
