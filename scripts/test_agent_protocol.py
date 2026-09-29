import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_protocol.py"
SPEC = importlib.util.spec_from_file_location("agent_protocol", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class AgentProtocolTest(unittest.TestCase):
    def packet(self):
        issue = {
            "number": 1866,
            "title": "Mejorar handoff",
            "body": "- [ ] conserva scope\n- [x] emite evidencia",
        }
        plan = {"files": ["scripts/a.py", "scripts/test_a.py"], "goal": "hacer contrato"}
        return mod.build_task_packet(
            issue,
            plan,
            repository="EspacioKoop/expediente-legado",
            base_sha="a" * 40,
            policy_sha="b" * 40,
            provider="qwen",
            worker="qwen-primary",
        )

    def test_task_packet_es_versionado_y_acotado(self):
        packet = self.packet()
        self.assertEqual(1, packet["schema"])
        self.assertEqual("TASK", packet["message_type"])
        self.assertEqual(12, packet["scope"]["max_files"])
        self.assertEqual(["scripts/a.py", "scripts/test_a.py"], packet["scope"]["allowed_files"])
        self.assertEqual(2, len(packet["acceptance_from_issue"]))

    def test_prompt_lleva_scope_y_result_contract(self):
        prompt = mod.render_worker_prompt(self.packet(), "qwen")
        self.assertIn("scripts/a.py", prompt)
        self.assertIn("AGENT_RESULT_BEGIN", prompt)
        self.assertIn('"message_type": "RESULT"', prompt)
        self.assertIn("No hagas commit, push, PR ni merge", prompt)

    def test_result_anidado_se_parsea_sin_regex_fragil(self):
        packet = self.packet()
        raw = """texto
AGENT_RESULT_BEGIN
{"schema":1,"message_type":"RESULT","task_id":"%s","base_sha":"%s","status":"done",
"summary":"ok","facts":["f"],"assumptions":[],"verified":["pytest: ok"],"unknowns":[],
"changes":[{"path":"scripts/a.py","reason":"fix"}],
"evidence":[{"kind":"test","detail":"1 passed"}],"unresolved":[],"next_action":"review"}
AGENT_RESULT_END
""" % (packet["task_id"], packet["base_sha"])
        result = mod.parse_result(raw)
        self.assertTrue(result["valid"])
        self.assertEqual("scripts/a.py", result["changes"][0]["path"])
        self.assertEqual(100.0, result["contract_coverage_pct"])

    def test_metric_detecta_cambio_no_reportado(self):
        packet = self.packet()
        result = {
            "valid": True,
            "task_id": packet["task_id"],
            "base_sha": packet["base_sha"],
            "changes": [{"path": "scripts/a.py", "reason": "x"}],
            "evidence": [{"kind": "test", "detail": "ok"}],
            "next_action": "review",
            "contract_coverage_pct": 100.0,
        }
        metrics = mod.result_metrics(packet, result, ["scripts/a.py", "scripts/test_a.py"])
        self.assertEqual(["scripts/test_a.py"], metrics["unreported_changed_files"])
        self.assertGreater(metrics["handoff_loss_proxy_pct"], 0)

    def test_sin_resultado_no_bloquea_parser_pero_mide_perdida_total(self):
        packet = self.packet()
        result = mod.parse_result("sin contrato")
        self.assertFalse(result["valid"])
        metrics = mod.result_metrics(packet, result, ["scripts/a.py"])
        self.assertEqual(100.0, metrics["handoff_loss_proxy_pct"])

    def test_b2b_rechaza_tipo_desconocido(self):
        self.assertIsNone(mod.normalize_message({"schema": 1, "message_type": "CHAT"}))
        self.assertEqual(
            "QUESTION",
            mod.normalize_message({"schema": 1, "message_type": "question"})["message_type"],
        )

    def test_cli_result_escribe_payload(self):
        packet = self.packet()
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            packet_path = root / "packet.json"
            packet_path.write_text(json.dumps(packet), encoding="utf-8")
            summary = root / "summary.txt"
            summary.write_text("sin contrato", encoding="utf-8")
            changed = root / "changed.txt"
            changed.write_text("scripts/a.py\n", encoding="utf-8")
            output = root / "out.json"
            old = sys.argv
            try:
                sys.argv = [
                    "agent_protocol.py", "result",
                    "--summary-file", str(summary),
                    "--packet", str(packet_path),
                    "--changed-files", str(changed),
                    "--output", str(output),
                ]
                self.assertEqual(0, mod.main())
            finally:
                sys.argv = old
            payload = json.loads(output.read_text(encoding="utf-8"))
            self.assertFalse(payload["result"]["valid"])


if __name__ == "__main__":
    unittest.main()
