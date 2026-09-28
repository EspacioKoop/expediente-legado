import importlib.util
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_pool.py"
SPEC = importlib.util.spec_from_file_location("agent_pool", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


def issue(
    number,
    *labels,
    created="2026-09-28T00:00:00Z",
    preferred=None,
):
    result = {
        "number": number,
        "createdAt": created,
        "labels": [{"name": label} for label in labels],
    }
    if preferred is not None:
        result["preferredProvider"] = preferred
    return result


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
            issue(n, "agent:auto", created=f"2026-09-27T{n:02d}:00:00Z")
            for n in range(1, 8)
        ]
        tasks = mod.select_tasks(issues, self.workers)
        self.assertEqual(6, len(tasks))
        self.assertEqual(6, len({task["worker"] for task in tasks}))
        self.assertEqual([1, 2, 3, 4, 5, 6], [task["issue"] for task in tasks])

    def test_todas_las_etiquetas_de_cola_son_elegibles(self):
        cases = [
            (issue(10, "agent:auto"), None),
            (issue(11, "agent:pool"), None),
            (issue(12, "agent:qwen"), "qwen"),
            (issue(13, "agent:gemini"), "gemini"),
        ]
        for candidate, provider in cases:
            with self.subTest(issue=candidate["number"]):
                self.assertEqual((True, provider), mod.eligible_issue(candidate))

    def test_auto_y_pool_pueden_coexistir_durante_migracion(self):
        tasks = mod.select_tasks([issue(20, "agent:auto", "agent:pool")], self.workers)
        self.assertEqual([20], [task["issue"] for task in tasks])

    def test_respeta_provider_explicito(self):
        issues = [
            issue(30, "agent:auto", "agent:gemini"),
            issue(31, "agent:auto", "agent:qwen"),
        ]
        tasks = mod.select_tasks(issues, self.workers)
        self.assertEqual("gemini", tasks[0]["provider"])
        self.assertEqual("qwen", tasks[1]["provider"])

    def test_provider_explicito_prevalece_sobre_preferencia_kev(self):
        tasks = mod.select_tasks(
            [issue(32, "agent:qwen", preferred="gemini")],
            self.workers,
        )
        self.assertEqual("qwen", tasks[0]["provider"])

    def test_preferencia_kev_es_blanda(self):
        tasks = mod.select_tasks(
            [issue(33, "agent:auto", preferred="gemini")],
            self.workers,
        )
        self.assertEqual("gemini", tasks[0]["provider"])

        workers = [{"worker": "qwen-only", "provider": "qwen"}]
        fallback = mod.select_tasks(
            [issue(34, "agent:auto", preferred="gemini")],
            workers,
        )
        self.assertEqual("qwen", fallback[0]["provider"])

    def test_bloquea_estados_que_ya_tienen_trabajo(self):
        issues = [
            issue(40, "agent:auto", "agent:working"),
            issue(41, "agent:auto", "agent:pr-open"),
            issue(42, "agent:auto", "agent:needs-human"),
            issue(43, "agent:auto"),
        ]
        selected = mod.select_tasks(issues, self.workers)
        self.assertEqual([43], [task["issue"] for task in selected])

    def test_dos_labels_de_provider_son_ambiguos(self):
        issues = [issue(50, "agent:auto", "agent:qwen", "agent:gemini")]
        self.assertEqual([], mod.select_tasks(issues, self.workers))

    def test_capacidad_provider_no_se_sobreasigna(self):
        workers = [{"worker": "gemini", "provider": "gemini"}]
        issues = [
            issue(60, "agent:gemini"),
            issue(61, "agent:gemini"),
        ]
        tasks = mod.select_tasks(issues, workers)
        self.assertEqual(1, len(tasks))
        self.assertEqual("gemini", tasks[0]["worker"])

    def test_max_parallel_no_puede_superar_seis(self):
        issues = [issue(n, "agent:auto") for n in range(70, 80)]
        workers = self.workers + [
            {"worker": "extra-1", "provider": "qwen"},
            {"worker": "extra-2", "provider": "qwen"},
        ]
        self.assertEqual(6, len(mod.select_tasks(issues, workers, max_parallel=99)))

    def test_workflows_comparten_cola_y_kev(self):
        pool = (ROOT / ".github" / "workflows" / "agent-pool.yml").read_text(
            encoding="utf-8"
        )
        worker = (ROOT / ".github" / "workflows" / "agent-worker.yml").read_text(
            encoding="utf-8"
        )
        autopilot = (
            ROOT / ".github" / "workflows" / "agent-autopilot.yml"
        ).read_text(encoding="utf-8")

        for label in ("agent:auto", "agent:pool", "agent:qwen", "agent:gemini"):
            self.assertIn(label, pool)
            self.assertIn(label, worker)

        self.assertIn("python3 scripts/kev_router.py", pool)
        self.assertIn("preferredProvider", pool)
        self.assertIn("tailscale/github-action@v4", worker)
        self.assertIn("steps.omniroute.outputs.ready", worker)
        self.assertNotIn("\n  schedule:\n", autopilot)
        self.assertNotIn("\n  issues:\n", autopilot)

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
