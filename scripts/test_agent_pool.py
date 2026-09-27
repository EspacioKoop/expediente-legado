import importlib.util
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_pool.py"
SPEC = importlib.util.spec_from_file_location("agent_pool", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


def issue(number, *labels, created="2026-09-28T00:00:00Z"):
    return {
        "number": number,
        "createdAt": created,
        "labels": [{"name": label} for label in labels],
    }


class AgentPoolTest(unittest.TestCase):
    def setUp(self):
        self.workers = [
            {"worker": "qwen-primary", "provider": "qwen"},
            {"worker": "gemini", "provider": "gemini"},
            {"worker": "qwen-fallback-1", "provider": "qwen"},
            {"worker": "qwen-fallback-2", "provider": "qwen"},
            {"worker": "qwen-fallback-3", "provider": "qwen"},
            {"worker": "qwen-fallback-4", "provider": "qwen"},
        ]

    def test_hasta_seis_issues_usando_un_worker_por_backend(self):
        issues = [
            issue(n, "agent:pool", created=f"2026-09-27T{n:02d}:00:00Z")
            for n in range(1, 8)
        ]
        tasks = mod.select_tasks(issues, self.workers)
        self.assertEqual(6, len(tasks))
        self.assertEqual(6, len({task["worker"] for task in tasks}))
        self.assertEqual([1, 2, 3, 4, 5, 6], [task["issue"] for task in tasks])

    def test_respeta_provider_explicito(self):
        issues = [
            issue(10, "agent:pool", "agent:gemini"),
            issue(11, "agent:pool", "agent:qwen"),
        ]
        tasks = mod.select_tasks(issues, self.workers)
        self.assertEqual("gemini", tasks[0]["provider"])
        self.assertEqual("qwen", tasks[1]["provider"])

    def test_no_compite_con_autopilot_legacy(self):
        issues = [
            issue(20, "agent:pool", "agent:auto"),
            issue(21, "agent:pool"),
        ]
        tasks = mod.select_tasks(issues, self.workers)
        self.assertEqual([21], [task["issue"] for task in tasks])

    def test_bloquea_estados_que_ya_tienen_trabajo(self):
        issues = [
            issue(30, "agent:pool", "agent:working"),
            issue(31, "agent:pool", "agent:pr-open"),
            issue(32, "agent:pool", "agent:needs-human"),
            issue(33, "agent:pool"),
        ]
        self.assertEqual([33], [task["issue"] for task in mod.select_tasks(issues, self.workers)])

    def test_dos_labels_de_provider_son_ambiguos(self):
        issues = [issue(40, "agent:pool", "agent:qwen", "agent:gemini")]
        self.assertEqual([], mod.select_tasks(issues, self.workers))

    def test_capacidad_provider_no_se_sobreasigna(self):
        workers = [{"worker": "gemini", "provider": "gemini"}]
        issues = [
            issue(50, "agent:pool", "agent:gemini"),
            issue(51, "agent:pool", "agent:gemini"),
        ]
        tasks = mod.select_tasks(issues, workers)
        self.assertEqual(1, len(tasks))
        self.assertEqual("gemini", tasks[0]["worker"])

    def test_max_parallel_no_puede_superar_seis(self):
        issues = [issue(n, "agent:pool") for n in range(60, 70)]
        workers = self.workers + [
            {"worker": "extra-1", "provider": "qwen"},
            {"worker": "extra-2", "provider": "qwen"},
        ]
        self.assertEqual(6, len(mod.select_tasks(issues, workers, max_parallel=99)))

    def test_memoria_oidc_reconoce_worker_reusable_sin_abrir_dispatcher(self):
        memory = (ROOT / "infra" / "feedback-deno" / "agent_memory.ts").read_text(
            encoding="utf-8"
        )
        self.assertIn("job_workflow_ref?: string;", memory)
        self.assertIn('/.github/workflows/agent-worker.yml@";', memory)
        self.assertIn('/.github/workflows/agent-pool.yml@";', memory)
        self.assertIn("jobWorkflowRef.startsWith(workerPrefix)", memory)


if __name__ == "__main__":
    unittest.main()
