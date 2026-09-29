import importlib.util
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
    }


class AgentHandoffMetricsTest(unittest.TestCase):
    def test_parsea_telemetria_compacta(self):
        parsed = mod.parse_agent_pr(agent_pr(loss="16.7"))
        self.assertIsNotNone(parsed)
        self.assertEqual("qwen-primary", parsed["worker"])
        self.assertEqual("qwen", parsed["provider"])
        self.assertEqual(16.7, parsed["handoff_loss_proxy_pct"])
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

    def test_agrega_rates_por_worker(self):
        prs = [
            agent_pr(number=1, loss="0", valid="true", status="done"),
            agent_pr(
                number=2,
                loss="50",
                valid="false",
                status="partial",
                review_verdict="findings",
                commits=2,
            ),
            agent_pr(number=3, worker="gemini", provider="gemini", loss="25"),
        ]
        result = mod.aggregate_prs(prs)
        qwen = result["qwen-primary"]
        self.assertEqual(2, qwen["samples"])
        self.assertEqual(25.0, qwen["handoff_loss_proxy_pct"])
        self.assertEqual(50.0, qwen["contract_valid_rate_pct"])
        self.assertEqual(50.0, qwen["rework_rate_pct"])
        self.assertEqual(50.0, qwen["review_findings_rate_pct"])
        self.assertEqual(50.0, qwen["partial_or_blocked_rate_pct"])
        self.assertEqual(1, result["gemini"]["samples"])

    def test_commit_count_admite_lista_de_api(self):
        parsed = mod.parse_agent_pr(agent_pr(commits=[{"oid": "a"}, {"oid": "b"}]))
        self.assertEqual(2, parsed["commit_count"])
        self.assertTrue(parsed["rework_signal"])

    def test_dispatcher_carga_metricas_sin_reemplazar_score_historico(self):
        self.assertIn("scripts/agent_handoff_metrics.py", POOL_WORKFLOW)
        self.assertIn("--json number,title,body,commits", POOL_WORKFLOW)
        self.assertIn("handoff_loss_proxy_pct:", POOL_WORKFLOW)
        self.assertIn("rework_rate_pct:", POOL_WORKFLOW)
        self.assertIn("score: (($scores[0][.worker].score) // 50)", POOL_WORKFLOW)

    def test_limita_a_las_50_muestras_mas_recientes(self):
        prs = [
            agent_pr(number=number, loss="100" if number == 1 else "0")
            for number in range(1, 53)
        ]
        result = mod.aggregate_prs(prs)["qwen-primary"]
        self.assertEqual(50, result["samples"])
        self.assertEqual(0.0, result["handoff_loss_proxy_pct"])


if __name__ == "__main__":
    unittest.main()
