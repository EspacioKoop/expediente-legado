import importlib.util
from datetime import datetime, timezone
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_handoff_metrics.py"
POOL_WORKFLOW = (ROOT / ".github" / "workflows" / "agent-pool.yml").read_text(encoding="utf-8")
SPEC = importlib.util.spec_from_file_location("agent_handoff_metrics", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)

NOW = datetime(2026, 9, 29, 20, 0, tzinfo=timezone.utc)


def ci_rollup(conclusion="SUCCESS", status="COMPLETED"):
    return [
        {
            "__typename": "CheckRun",
            "workflowName": "CI",
            "name": "Python",
            "status": status,
            "conclusion": conclusion,
        }
    ]


def agent_pr(
    *,
    number=100,
    provider="qwen",
    worker="qwen-primary",
    valid="true",
    status="done",
    loss="0",
    review_status="ok",
    review_verdict="approve",
    commits=1,
    updated_at="2026-09-29T12:00:00Z",
    ci_conclusion="SUCCESS",
    ci_status="COMPLETED",
):
    tick = chr(96)
    return {
        "number": number,
        "title": f"agent({provider}): #42 corte seguro",
        "body": (
            f"Implementacion autonoma mediante worker {tick}{worker}{tick}. "
            f"Reviewer acotado: {tick}{review_status}/{review_verdict}{tick}. "
            f"Protocolo v1: ResultPacket {valid}/{status}; "
            f"handoff-loss proxy {loss}%. PR draft, sin auto-merge."
        ),
        "commits": commits,
        "updatedAt": updated_at,
        "statusCheckRollup": ci_rollup(ci_conclusion, ci_status),
    }


class AgentHandoffMetricsTest(unittest.TestCase):
    def test_parsea_telemetria_compacta_y_ci(self):
        parsed = mod.parse_agent_pr(agent_pr(loss="16.7"))
        self.assertIsNotNone(parsed)
        self.assertEqual("qwen-primary", parsed["worker"])
        self.assertEqual("qwen", parsed["provider"])
        self.assertEqual(16.7, parsed["handoff_loss_proxy_pct"])
        self.assertEqual("success", parsed["ci_state"])
        self.assertEqual(
            datetime(2026, 9, 29, 12, 0, tzinfo=timezone.utc),
            parsed["observed_at"],
        )
        self.assertFalse(parsed["rework_signal"])

    def test_ignora_prs_anteriores_al_protocolo(self):
        pr = agent_pr()
        pr["body"] = "Implementacion autonoma sin telemetria v1"
        self.assertIsNone(mod.parse_agent_pr(pr))

    def test_findings_o_commit_extra_marcan_rework(self):
        findings = mod.parse_agent_pr(agent_pr(review_verdict="findings"))
        extra_commit = mod.parse_agent_pr(agent_pr(number=101, commits=2))
        self.assertTrue(findings["rework_signal"])
        self.assertTrue(extra_commit["rework_signal"])

    def test_ci_separa_success_failure_pending_y_missing(self):
        self.assertEqual("success", mod.parse_agent_pr(agent_pr())["ci_state"])
        self.assertEqual(
            "failure",
            mod.parse_agent_pr(agent_pr(ci_conclusion="FAILURE"))["ci_state"],
        )
        self.assertEqual(
            "pending",
            mod.parse_agent_pr(agent_pr(ci_conclusion="", ci_status="IN_PROGRESS"))["ci_state"],
        )
        missing = agent_pr()
        missing["statusCheckRollup"] = [
            {
                "__typename": "CheckRun",
                "workflowName": "Secretos",
                "name": "scan",
                "status": "COMPLETED",
                "conclusion": "SUCCESS",
            }
        ]
        self.assertEqual("missing", mod.parse_agent_pr(missing)["ci_state"])

    def test_agrega_rates_por_worker_en_ventana(self):
        prs = [
            agent_pr(number=1, loss="0", valid="true", status="done"),
            agent_pr(
                number=2,
                loss="50",
                valid="false",
                status="partial",
                review_verdict="findings",
                commits=2,
                ci_conclusion="FAILURE",
            ),
            agent_pr(
                number=3,
                worker="gemini",
                provider="gemini",
                loss="25",
                ci_conclusion="",
                ci_status="IN_PROGRESS",
            ),
        ]
        result = mod.aggregate_prs(prs, window_days=30, now=NOW)
        qwen = result["qwen-primary"]
        self.assertEqual(2, qwen["samples"])
        self.assertEqual(30, qwen["window_days"])
        self.assertEqual(25.0, qwen["handoff_loss_proxy_pct"])
        self.assertEqual(50.0, qwen["contract_valid_rate_pct"])
        self.assertEqual(50.0, qwen["rework_rate_pct"])
        self.assertEqual(50.0, qwen["review_findings_rate_pct"])
        self.assertEqual(50.0, qwen["partial_or_blocked_rate_pct"])
        self.assertEqual(100.0, qwen["ci_observed_rate_pct"])
        self.assertEqual(50.0, qwen["ci_success_rate_pct"])
        self.assertEqual(50.0, qwen["ci_failure_rate_pct"])
        self.assertEqual(0, qwen["ci_pending_samples"])
        self.assertEqual(1, result["gemini"]["ci_pending_samples"])

    def test_ventana_excluye_muestras_antiguas(self):
        prs = [
            agent_pr(number=1, updated_at="2026-08-01T12:00:00Z", loss="100"),
            agent_pr(number=2, updated_at="2026-09-28T12:00:00Z", loss="10"),
        ]
        result = mod.aggregate_prs(prs, window_days=30, now=NOW)["qwen-primary"]
        self.assertEqual(1, result["samples"])
        self.assertEqual(10.0, result["handoff_loss_proxy_pct"])

    def test_commit_count_admite_lista_de_api(self):
        parsed = mod.parse_agent_pr(agent_pr(commits=[{"oid": "a"}, {"oid": "b"}]))
        self.assertEqual(2, parsed["commit_count"])
        self.assertTrue(parsed["rework_signal"])

    def test_dispatcher_carga_ci_y_ventana_sin_reemplazar_score_historico(self):
        self.assertIn("scripts/agent_handoff_metrics.py", POOL_WORKFLOW)
        self.assertIn(
            "--json number,title,body,commits,updatedAt,statusCheckRollup",
            POOL_WORKFLOW,
        )
        self.assertIn("--window-days 30", POOL_WORKFLOW)
        self.assertIn("handoff_loss_proxy_pct:", POOL_WORKFLOW)
        self.assertIn("rework_rate_pct:", POOL_WORKFLOW)
        self.assertIn("ci_success_rate_pct:", POOL_WORKFLOW)
        self.assertIn("ci_failure_rate_pct:", POOL_WORKFLOW)
        self.assertIn("telemetry_window_days:", POOL_WORKFLOW)
        self.assertIn("score: (($scores[0][.worker].score) // 50)", POOL_WORKFLOW)

    def test_limita_a_50_muestras_dentro_de_ventana(self):
        prs = [
            agent_pr(
                number=number,
                loss="100" if number <= 2 else "0",
                updated_at=(
                    "2026-09-01T12:00:00Z"
                    if number <= 2
                    else "2026-09-29T12:00:00Z"
                ),
            )
            for number in range(1, 53)
        ]
        result = mod.aggregate_prs(prs, window_days=30, now=NOW)["qwen-primary"]
        self.assertEqual(50, result["samples"])
        self.assertEqual(0.0, result["handoff_loss_proxy_pct"])

    def test_rechaza_ventana_no_positiva(self):
        with self.assertRaises(ValueError):
            mod.aggregate_prs([agent_pr()], window_days=0, now=NOW)


if __name__ == "__main__":
    unittest.main()
