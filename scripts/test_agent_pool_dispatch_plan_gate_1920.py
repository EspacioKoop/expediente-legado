import importlib.util
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
POOL_PATH = ROOT / "scripts" / "agent_pool.py"
SPEC = importlib.util.spec_from_file_location("agent_pool_1920", POOL_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)

WORKFLOW = (ROOT / ".github" / "workflows" / "agent-pool.yml").read_text(
    encoding="utf-8"
)


class DispatcherPlanGate1920Test(unittest.TestCase):
    def test_decompose_es_label_bloqueante_para_workers(self):
        issue = {
            "number": 1920,
            "labels": [{"name": "agent:auto"}, {"name": "agent:decompose"}],
        }
        eligible, provider = mod.eligible_issue(issue)
        self.assertFalse(eligible)
        self.assertIsNone(provider)
        self.assertIn("agent:decompose", mod.BLOCKING_LABELS)

    def test_dispatcher_resuelve_plan_antes_de_agent_pool(self):
        resolve = WORKFLOW.index("python3 scripts/agent_delegated_plan.py")
        matrix = WORKFLOW.index("python3 scripts/agent_pool.py")
        self.assertLess(resolve, matrix)
        self.assertIn("plannedFiles:$planned", WORKFLOW)

    def test_sin_plan_deriva_a_decompose_y_lanza_workflow(self):
        self.assertIn("--add-label agent:decompose", WORKFLOW)
        self.assertIn("gh workflow run agent-decompose.yml", WORKFLOW)
        self.assertIn('--ref main -f issue="$issue"', WORKFLOW)
        self.assertIn(
            "Los eventos generados con GITHUB_TOKEN no encadenan workflows",
            WORKFLOW,
        )
        self.assertIn("no hay AGENT_PLAN delegado", WORKFLOW)

    def test_plan_vacio_escala_sin_asignar_worker(self):
        self.assertIn('if [[ "$(jq \'length\' <<<"$planned")" -eq 0 ]]', WORKFLOW)
        self.assertIn("--add-label agent:needs-human", WORKFLOW)
        self.assertIn("map(select(.number != $issue))", WORKFLOW)
        self.assertIn("evitar un bucle sin corte ejecutable", WORKFLOW)

    def test_fallo_de_api_o_parser_es_fail_open(self):
        self.assertIn(
            "No se pudo validar AGENT_PLAN de #$issue; fail-open al guard del worker",
            WORKFLOW,
        )
        # Un fallo del parser no debe etiquetar needs-human/decompose por sí solo.
        loop = WORKFLOW.split('for issue in "${candidates[@]}"; do', 1)[1].split(
            "python3 scripts/agent_pool.py", 1
        )[0]
        failure = loop.split("if (( plan_status == 0 )); then", 1)[1].split(
            "fi\n            fi", 1
        )[0]
        self.assertIn("plan_status", loop)
        self.assertIn("fail-open", loop)

    def test_derivacion_conserva_preferencia_de_provider(self):
        loop = WORKFLOW.split('for issue in "${candidates[@]}"; do', 1)[1].split(
            "python3 scripts/agent_pool.py", 1
        )[0]
        no_plan = loop.split('if [[ "$already_decompose" != true ]]; then', 1)[1].split(
            "continue", 1
        )[0]
        self.assertNotIn("--remove-label agent:qwen", no_plan)
        self.assertNotIn("--remove-label agent:gemini", no_plan)


if __name__ == "__main__":
    unittest.main()
