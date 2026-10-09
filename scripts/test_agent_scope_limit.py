"""El piloto multifichero es opt-in, con tres rutas como máximo."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("agent_scope_limit", ROOT / "scripts/agent_scope_limit.py")
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mod)


class ScopeLimitTest(unittest.TestCase):
    def test_sin_label_o_labels_rotas_es_un_fichero(self):
        for issue in (
            {"number": 1},
            {"labels": []},
            {"labels": None},
            {"labels": ["agent:auto"]},
            {"labels": [{"name": "agent:multi-file-experimental"}]},
            {"title": "agent:multi-file", "body": "agent:multi-file"},
        ):
            with self.subTest(issue=issue):
                self.assertEqual(1, mod.resolve_limit(issue))

    def test_exige_label_exacto(self):
        self.assertEqual(3, mod.resolve_limit({"labels": [{"name": "agent:multi-file"}]}))
        self.assertEqual(3, mod.resolve_limit({"labels": ["agent:multi-file"]}))
        self.assertEqual(1, mod.resolve_limit({"labels": [{"name": "Agent:multi-file"}]}))
        self.assertEqual(1, mod.resolve_limit({"labels": "agent:multi-file"}))

    def test_rechaza_issue_no_objeto(self):
        with self.assertRaises(ValueError):
            mod.resolve_limit([])

    def test_cli_lee_json_sin_evaluar_cadenas(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "issue.json"
            p.write_text(json.dumps({"number": 2569, "labels": [{"name": "agent:multi-file"}]}))
            output = subprocess.check_output([sys.executable, str(ROOT / "scripts/agent_scope_limit.py"),
                                              "--issue-json", str(p)], text=True).strip()
            self.assertEqual("3", output)

    def test_parser_0_1_2_3_4_con_y_sin_label(self):
        spec = importlib.util.spec_from_file_location("agent_plan_parse", ROOT / "scripts/agent_plan_parse.py")
        assert spec and spec.loader
        parser = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(parser)
        for label, limit in ((False, 1), (True, 3)):
            for size in range(5):
                files = [f"scripts/task_{i}.py" for i in range(size)]
                with self.subTest(label=label, size=size):
                    plan = {"files": files, "goal": "prueba"}
                    if size > limit:
                        with self.assertRaises(parser.PlanTooBig):
                            parser.normalize(plan, max_files=limit)
                    else:
                        self.assertEqual(files, parser.normalize(plan, max_files=limit)["files"])

    def test_workflows_revalidan_antes_de_reserva_packet_pr_y_fallback(self):
        worker = (ROOT / ".github/workflows/agent-worker.yml").read_text()
        jules = (ROOT / ".github/workflows/agent-jules.yml").read_text()
        self.assertEqual(2, worker.count("agent_scope_limit.py --issue-json /tmp/agent-issue.json"))
        self.assertEqual(3, jules.count("agent_scope_limit.py --issue-json /tmp/issue.json"))
        self.assertIn('--max-files "$MAX_FILES"', worker)
        self.assertIn('--max-files "$MAX_FILES"', jules)
        self.assertNotIn("vars.AGENT_POOL_MAX_FILES", worker + jules)


if __name__ == "__main__":
    unittest.main()
