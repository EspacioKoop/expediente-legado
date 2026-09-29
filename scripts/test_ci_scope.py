import importlib.util
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "ci_scope.py"
CI = ROOT / ".github" / "workflows" / "ci.yml"

SPEC = importlib.util.spec_from_file_location("ci_scope", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class CiScopeTest(unittest.TestCase):
    def test_infra_agentes_es_fast(self):
        result = mod.classify(
            [
                ".github/workflows/agent-pool.yml",
                "scripts/agent_pool.py",
                "scripts/test_agent_pool.py",
                "docs/agents/parallel-pool.md",
            ]
        )
        self.assertEqual("fast", result["mode"])
        self.assertEqual([], result["outside"])

    def test_gateway_deno_es_fast(self):
        result = mod.classify(
            [
                "infra/feedback-deno/main.ts",
                ".github/workflows/feedback-deno.yml",
                "scripts/check_deno_production.py",
            ]
        )
        self.assertEqual("fast", result["mode"])

    def test_sala_de_mando_deno_es_fast(self):
        # #1778: app Deno aparte con su propio workflow de fmt/check/test.
        result = mod.classify(
            [
                "infra/mando-deno/mando.ts",
                ".github/workflows/mando-deno.yml",
            ]
        )
        self.assertEqual("fast", result["mode"])

    def test_runtime_o_script_generico_fuerza_full(self):
        for path in (
            "godot/main.gd",
            "gbc/src/core.cpp",
            "backend/pom.xml",
            "scripts/verificar_godot.py",
            ".github/workflows/ci.yml",
        ):
            with self.subTest(path=path):
                result = mod.classify(["scripts/agent_pool.py", path])
                self.assertEqual("full", result["mode"])
                self.assertIn(path, result["outside"])

    def test_diff_vacio_fuerza_full(self):
        result = mod.classify([])
        self.assertEqual("full", result["mode"])
        self.assertEqual("diff-vacio", result["reason"])

    def test_ci_conserva_mismo_job_requerido_y_salta_pesado_solo_en_fast(self):
        workflow = CI.read_text(encoding="utf-8")
        self.assertIn("  godot:", workflow)
        self.assertIn("id: scope", workflow)
        self.assertIn("python scripts/ci_scope.py", workflow)
        self.assertIn("Preflight infra rápido", workflow)
        fast = workflow.split("- name: Preflight infra rápido", 1)[1].split(
            "- name: Materializar LFS para CI completo", 1
        )[0]
        self.assertIn(
            "python -m unittest discover -s scripts -p 'test_agent_*.py'",
            fast,
        )
        for test in (
            "test_ci_scope.py",
            "test_deno_production_freshness.py",
            "test_parte_incidencias.py",
            "test_workflows_yaml.py",
        ):
            with self.subTest(test=test):
                self.assertIn(f"python scripts/{test}", fast)
        self.assertIn("if [[ -f scripts/test_deno_deploy_workflow.py ]]", fast)
        self.assertNotIn(
            "python -m unittest discover -s scripts -p 'test_*.py'",
            fast,
        )
        self.assertNotIn("git lfs pull", fast)
        self.assertIn("steps.scope.outputs.mode == 'full'", workflow)
        self.assertIn("steps.scope.outputs.mode == 'fast'", workflow)
        self.assertIn("git lfs pull", workflow)

    def test_pull_request_usa_merge_base_actual_y_no_payload_stale(self):
        workflow = CI.read_text(encoding="utf-8")
        scope = workflow.split("- id: scope", 1)[1].split(
            "- name: Preflight infra rápido", 1
        )[0]
        self.assertIn('if [[ "$EVENT_NAME" == pull_request ]]', scope)
        self.assertIn("git fetch origin main --no-tags", scope)
        self.assertIn('base="$(git merge-base HEAD origin/main)"', scope)
        self.assertNotIn("PR_BASE_SHA", scope)
        self.assertNotIn("github.event.pull_request.base.sha", scope)


if __name__ == "__main__":
    unittest.main()
