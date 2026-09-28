import importlib.util
import json
from datetime import datetime, timezone
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_feeder.py"
WORKFLOW = ROOT / ".github" / "workflows" / "agent-feeder.yml"
DECOMPOSE = ROOT / ".github" / "workflows" / "agent-decompose.yml"
DEPENDENCY = ROOT / ".github" / "workflows" / "agent-dependency-unblock.yml"

SPEC = importlib.util.spec_from_file_location("agent_feeder", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


NOW = datetime(2026, 9, 28, 21, 30, tzinfo=timezone.utc)


def issue(number, title, labels=(), body="Contexto suficiente " * 10, updated="2026-09-28T18:00:00Z"):
    return {
        "number": number,
        "title": title,
        "body": body,
        "labels": [{"name": label} for label in labels],
        "createdAt": f"2026-09-{number % 20 + 1:02d}T00:00:00Z",
        "updatedAt": updated,
    }


class AgentFeederTest(unittest.TestCase):
    def test_excluye_gates_agente_p0_playtest_epica_y_pr(self):
        prs = [{"body": "Refs #6"}]
        candidates = [
            issue(1, "Bug normal", ["estado:validacion-humana"]),
            issue(2, "Bug normal", ["agent:no-auto"]),
            issue(3, "Bug normal", ["agent:pr-open"]),
            issue(4, "Bug P0", ["prioridad:P0"]),
            issue(5, "Playtest: validar algo", ["bug"]),
            issue(6, "Bug con PR", ["bug"]),
            issue(7, "Épica: sistema enorme"),
            issue(8, "Bug elegible", ["bug", "prioridad:P2"]),
        ]
        result = mod.select_candidate(candidates, prs, now=NOW)
        self.assertEqual(8, result["selected"]["number"])
        self.assertEqual(1, result["eligible"])

    def test_excluye_issue_activo_recientemente(self):
        result = mod.select_candidate(
            [issue(10, "Bug reciente", ["bug"], updated="2026-09-28T21:00:00Z")],
            [],
            now=NOW,
            min_age_minutes=90,
        )
        self.assertIsNone(result["selected"])
        self.assertEqual(1, result["rejected"]["activo-reciente"])

    def test_prioriza_bug_infra_y_prioridad_baja(self):
        candidates = [
            issue(11, "Feature normal"),
            issue(12, "infra: mejora de cola", ["prioridad:P3"]),
            issue(13, "Bug funcional", ["bug", "prioridad:P2"]),
        ]
        result = mod.select_candidate(candidates, [], now=NOW)
        self.assertEqual(12, result["selected"]["number"])

    def test_refs_de_pr_reconoce_formas_comunes(self):
        refs = mod.referenced_issues([
            {"body": "Refs #21\nFixes #22"},
            {"body": "Closes #23; resolves #24"},
        ])
        self.assertEqual({21, 22, 23, 24}, refs)

    def test_cli_es_determinista_con_now(self):
        issues = [issue(31, "test: candidato", ["prioridad:P3"])]
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            issues_path = root / "issues.json"
            prs_path = root / "prs.json"
            output = root / "out.json"
            issues_path.write_text(json.dumps(issues), encoding="utf-8")
            prs_path.write_text("[]", encoding="utf-8")
            old_argv = sys.argv
            try:
                sys.argv = [
                    "agent_feeder.py",
                    "--issues", str(issues_path),
                    "--prs", str(prs_path),
                    "--output", str(output),
                    "--now", "2026-09-28T21:30:00Z",
                ]
                self.assertEqual(0, mod.main())
            finally:
                sys.argv = old_argv
            self.assertEqual(31, json.loads(output.read_text())["selected"]["number"])

    def test_workflow_alimenta_solo_si_cola_vacia_y_despacha_planner(self):
        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("cron: '19 * * * *'", workflow)
        self.assertIn("agent:no-auto", workflow)
        self.assertIn("agent:decompose", workflow)
        self.assertIn("queued > 0", workflow)
        self.assertIn("python3 scripts/agent_feeder.py", workflow)
        self.assertIn("gh workflow run agent-decompose.yml", workflow)
        self.assertNotIn("--add-label agent:auto", workflow)

    def test_decompose_despacha_pool_sin_confiar_en_evento_recursivo(self):
        decompose = DECOMPOSE.read_text(encoding="utf-8")
        self.assertIn("actions: write", decompose)
        self.assertGreaterEqual(decompose.count("gh workflow run agent-pool.yml"), 2)

    def test_unblock_despacha_pool_si_libera_subtareas(self):
        dependency = DEPENDENCY.read_text(encoding="utf-8")
        self.assertIn("actions: write", dependency)
        self.assertIn("/tmp/agent-unblocked.txt", dependency)
        self.assertIn("gh workflow run agent-pool.yml", dependency)


if __name__ == "__main__":
    unittest.main()
