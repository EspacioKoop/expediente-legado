"""Tests del contrato B2B entre agentes (#1866)."""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import agent_b2b

ROOT = Path(__file__).resolve().parents[1]
WORKER = ROOT / ".github" / "workflows" / "agent-worker.yml"


class AgentB2BTests(unittest.TestCase):
    def test_message_types_are_explicit(self):
        self.assertEqual(
            agent_b2b.MESSAGE_TYPES,
            {"TASK", "CLAIM", "EVIDENCE", "BLOCKER", "QUESTION", "RESULT", "REVIEW", "HANDOFF"},
        )

    def test_result_contract_is_advisory_and_measured(self):
        task = {
            "schema": 1,
            "type": "TASK",
            "issue": 1866,
            "handoff": {"from": "planner", "to": "implementer"},
            "provider": "qwen",
            "worker": "qwen-primary",
        }
        raw = (
            'AGENT_RESULT_BEGIN '
            '{"facts":["ok"],"changes":[],"next_action":"review"} '
            'AGENT_RESULT_END'
        )
        packet = agent_b2b.parse_result(raw, task)
        self.assertEqual(packet["type"], "RESULT")
        self.assertEqual(packet["contract_status"], "partial")
        self.assertEqual(packet["coverage_percent"], 50)

    def test_missing_result_does_not_raise(self):
        task = {
            "schema": 1,
            "type": "TASK",
            "issue": 1,
            "handoff": {"from": "planner", "to": "implementer"},
        }
        packet = agent_b2b.parse_result("sin bloque", task)
        self.assertEqual(packet["contract_status"], "missing")
        self.assertEqual(packet["coverage_percent"], 0)

    def test_task_artifact_fingerprint_detects_stale_handoff(self):
        with tempfile.TemporaryDirectory() as td:
            artifact = Path(td) / "task.md"
            artifact.write_text("uno", encoding="utf-8")
            meta = agent_b2b._artifact(artifact)
            packet = {
                "schema": 1,
                "type": "TASK",
                "issue": 9,
                "artifacts": {"task": meta},
                "handoff": {"from": "planner", "to": "implementer"},
            }
            agent_b2b.verify_task_artifacts(packet)
            artifact.write_text("dos", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "cambio despues del handoff"):
                agent_b2b.verify_task_artifacts(packet)

    def test_review_is_typed_and_keeps_compatibility_fields(self):
        task = {
            "schema": 1,
            "type": "TASK",
            "issue": 9,
            "handoff": {"from": "planner", "to": "implementer"},
        }
        result = {"contract_status": "complete", "coverage_percent": 100}
        review = {"status": "ok", "verdict": "findings", "findings": ["falta test"]}
        packet = agent_b2b.build_review(review, task, result)
        self.assertEqual(packet["type"], "REVIEW")
        self.assertEqual(packet["verdict"], "findings")
        self.assertEqual(packet["findings"], ["falta test"])

    def test_prompt_contains_scope_and_result_contract(self):
        with tempfile.TemporaryDirectory() as td:
            packet = Path(td) / "task.json"
            packet.write_text(
                json.dumps(
                    {
                        "schema": 1,
                        "type": "TASK",
                        "issue": 9,
                        "scope": {"files": ["a.py"]},
                        "handoff": {"from": "planner", "to": "implementer"},
                    }
                ),
                encoding="utf-8",
            )
            prompt = agent_b2b.compile_prompt("implement", "qwen", packet)
            self.assertIn("a.py", prompt)
            self.assertIn("AGENT_RESULT_BEGIN", prompt)
            self.assertIn("#1713", prompt)

    def test_worker_wires_task_result_review_handoffs(self):
        text = WORKER.read_text(encoding="utf-8")
        self.assertIn("Compilar TaskPacket B2B", text)
        self.assertIn("agent_b2b.py result", text)
        self.assertIn("agent_b2b.py review", text)
        self.assertIn(".agent-task-packet.json", text)
        self.assertIn(".agent-implement-prompt.md", text)
        self.assertIn(".agent-review-prompt.md", text)


if __name__ == "__main__":
    unittest.main()
