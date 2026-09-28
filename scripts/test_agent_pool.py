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
    comments=None,
):
    result = {
        "number": number,
        "createdAt": created,
        "labels": [{"name": label} for label in labels],
    }
    if preferred is not None:
        result["preferredProvider"] = preferred
    if comments is not None:
        result["comments"] = [{"body": body} for body in comments]
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

    def test_reserva_gemini_explicito_antes_de_tarea_flexible(self):
        workers = [
            {"worker": "gemini-unico", "provider": "gemini"},
            {"worker": "qwen-unico", "provider": "qwen"},
        ]
        issues = [
            issue(
                51,
                "agent:auto",
                created="2026-09-28T00:00:00Z",
                preferred="gemini",
            ),
            issue(
                52,
                "agent:gemini",
                created="2026-09-28T01:00:00Z",
            ),
        ]

        tasks = mod.select_tasks(issues, workers)

        self.assertEqual(
            {
                51: ("qwen", "qwen-unico"),
                52: ("gemini", "gemini-unico"),
            },
            {
                task["issue"]: (task["provider"], task["worker"])
                for task in tasks
            },
        )

    def test_reserva_qwen_explicito_antes_de_tarea_flexible(self):
        workers = [
            {"worker": "qwen-unico", "provider": "qwen"},
            {"worker": "gemini-unico", "provider": "gemini"},
        ]
        issues = [
            issue(53, "agent:auto", created="2026-09-28T00:00:00Z"),
            issue(54, "agent:qwen", created="2026-09-28T01:00:00Z"),
        ]

        tasks = mod.select_tasks(issues, workers)

        self.assertEqual(
            {
                53: ("gemini", "gemini-unico"),
                54: ("qwen", "qwen-unico"),
            },
            {
                task["issue"]: (task["provider"], task["worker"])
                for task in tasks
            },
        )

    def test_evitar_worker_que_ya_fallo_planificando(self):
        candidate = issue(
            55,
            "agent:auto",
            preferred="gemini",
            comments=[
                "AGENT_POOL_WORKER_FAILURE worker=gemini provider=gemini stage=plan run=1"
            ],
        )

        tasks = mod.select_tasks([candidate], self.workers)

        self.assertEqual("qwen-primary", tasks[0]["worker"])
        self.assertEqual("qwen", tasks[0]["provider"])

    def test_retry_reset_permite_reutilizar_worker(self):
        candidate = issue(
            56,
            "agent:auto",
            preferred="gemini",
            comments=[
                "AGENT_POOL_WORKER_FAILURE worker=gemini provider=gemini stage=plan run=1",
                "AGENT_POOL_RETRY_RESET motivo=cuota-recuperada",
            ],
        )

        tasks = mod.select_tasks([candidate], self.workers)

        self.assertEqual("gemini", tasks[0]["worker"])

    def test_provider_explicito_evade_worker_fallido_del_mismo_provider(self):
        workers = [
            {"worker": "qwen-primary", "provider": "qwen"},
            {"worker": "qwen-fallback-1", "provider": "qwen"},
        ]
        candidate = issue(
            57,
            "agent:qwen",
            comments=[
                "AGENT_POOL_WORKER_FAILURE worker=qwen-primary provider=qwen stage=plan run=1"
            ],
        )

        tasks = mod.select_tasks([candidate], workers)

        self.assertEqual(
            [{"issue": 57, "provider": "qwen", "worker": "qwen-fallback-1"}],
            tasks,
        )

    def test_score_elige_mejor_slot_dentro_del_provider_explicito(self):
        workers = [
            {"worker": "qwen-primary", "provider": "qwen", "score": 35},
            {"worker": "qwen-fallback-1", "provider": "qwen", "score": 88},
        ]

        tasks = mod.select_tasks([issue(57, "agent:qwen")], workers)

        self.assertEqual("qwen-fallback-1", tasks[0]["worker"])

    def test_tier_superior_solo_recibe_trabajo_si_el_anterior_no_tiene_hueco(self):
        # #1685: un backend flojo (tier 2) queda de último recurso aunque su
        # score histórico sea mejor que el de los preferentes.
        workers = [
            {"worker": "qwen-fallback-1", "provider": "qwen", "score": 95, "tier": 2},
            {"worker": "qwen-fallback-2", "provider": "qwen", "score": 40},
            {"worker": "qwen-fallback-3", "provider": "qwen", "score": 60, "tier": 1},
        ]
        issues = [issue(n, "agent:qwen") for n in (57, 58, 59)]

        tasks = mod.select_tasks(issues, workers)

        self.assertEqual(
            ["qwen-fallback-3", "qwen-fallback-2", "qwen-fallback-1"],
            [t["worker"] for t in tasks],
        )

    def test_tier_invalido_cuenta_como_preferente(self):
        for tier in (0, -3, "x", True, None):
            with self.subTest(tier=tier):
                normalizado = mod._worker({"worker": "w", "provider": "qwen", "tier": tier})
                self.assertEqual(1, normalizado["tier"])

    def test_score_respeta_preferencia_kev_y_solo_desempata_slot(self):
        workers = [
            {"worker": "qwen-primary", "provider": "qwen", "score": 99},
            {"worker": "gemini-a", "provider": "gemini", "score": 30},
            {"worker": "gemini-b", "provider": "gemini", "score": 80},
        ]

        tasks = mod.select_tasks(
            [issue(58, "agent:auto", preferred="gemini")],
            workers,
        )

        self.assertEqual("gemini-b", tasks[0]["worker"])

    def test_sin_score_conserva_orden_historico(self):
        workers = [
            {"worker": "qwen-primary", "provider": "qwen"},
            {"worker": "qwen-fallback-1", "provider": "qwen"},
        ]

        tasks = mod.select_tasks([issue(59, "agent:qwen")], workers)

        self.assertEqual("qwen-primary", tasks[0]["worker"])

    def test_slot_no_saludable_sale_de_rotacion_para_tarea_flexible(self):
        workers = [
            {"worker": "gemini", "provider": "gemini", "healthy": False},
            {"worker": "qwen-primary", "provider": "qwen", "healthy": True},
        ]
        candidate = issue(58, "agent:auto", preferred="gemini")

        tasks = mod.select_tasks([candidate], workers)

        self.assertEqual(
            [{"issue": 58, "provider": "qwen", "worker": "qwen-primary"}],
            tasks,
        )

    def test_provider_explicito_no_salta_a_otro_provider_si_slot_no_saludable(self):
        workers = [
            {"worker": "gemini", "provider": "gemini", "healthy": False},
            {"worker": "qwen-primary", "provider": "qwen", "healthy": True},
        ]

        tasks = mod.select_tasks([issue(59, "agent:gemini")], workers)

        self.assertEqual([], tasks)

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

    def test_workflows_comparten_cola_y_failover(self):
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
        self.assertIn("--json comments", pool)
        self.assertIn("AGENT_POOL_WORKER_FAILURE", worker)
        self.assertIn("AGENT_POOL_SLOT_UNHEALTHY", worker)
        self.assertIn("AGENT_PROVIDER_COOLDOWN_SECONDS", worker)
        self.assertIn("gemini-client-error-", worker)
        self.assertIn("AGENT_POOL_SLOT_UNHEALTHY", pool)
        self.assertIn("healthy", pool)
        self.assertIn('maxSessionTurns":40', worker)
        self.assertIn("tailscale/github-action@v4", worker)
        self.assertIn("steps.omniroute.outputs.ready", worker)
        self.assertNotIn("\n  schedule:\n", autopilot)
        self.assertNotIn("\n  issues:\n", autopilot)

    def test_fallo_de_implementacion_es_reintentable_por_otro_worker(self):
        worker = (ROOT / ".github" / "workflows" / "agent-worker.yml").read_text(
            encoding="utf-8"
        )
        self.assertIn("id: validate_diff", worker)
        self.assertIn('echo "retry_stage=implement" >> "$GITHUB_OUTPUT"', worker)
        self.assertIn('echo "retry_stage=no-changes" >> "$GITHUB_OUTPUT"', worker)
        self.assertIn("RETRY_STAGE: ${{ steps.validate_diff.outputs.retry_stage }}", worker)
        self.assertIn("stage=$retry_stage", worker)
        self.assertIn("agent-pool-${retry_stage}-retry", worker)
        self.assertIn("reencolado tras fallo de $retry_stage", worker)
        self.assertIn("agotó los workers compatibles durante $retry_stage", worker)

        cleanup = worker.split("- name: Limpiar fallo o cancelacion", 1)[1]
        self.assertIn('elif [[ "${RESERVED:-}" == true', cleanup)
        self.assertIn('retry_stage="$RETRY_STAGE"', cleanup)
        # Un fallo de preflight real, sin retry_stage, conserva la escalada humana.
        self.assertIn(
            '"Agent pool ($WORKER) se detuvo después de reservar/implementar:',
            cleanup,
        )

    def test_worker_cancelado_libera_estado_sin_penalizar_slot(self):
        worker = (ROOT / ".github" / "workflows" / "agent-worker.yml").read_text(
            encoding="utf-8"
        )
        self.assertIn("failure() || cancelled()", worker)
        self.assertIn("JOB_STATUS: ${{ job.status }}", worker)
        self.assertIn('if [[ "$JOB_STATUS" == cancelled ]]', worker)
        self.assertIn("motivo=agent-pool-cancelado-sin-PR", worker)
        self.assertIn("vuelve a cola sin penalizar al worker", worker)
        self.assertNotIn("en `$WORKER`", worker)

        cancel_block = worker.split('if [[ "$JOB_STATUS" == cancelled ]]', 1)[1].split(
            'if [[ "${RESERVED:-}" != true && -z "$pr" ]]', 1
        )[0]
        self.assertNotIn("AGENT_POOL_WORKER_FAILURE", cancel_block)
        self.assertNotIn("AGENT_POOL_SLOT_UNHEALTHY", cancel_block)

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
