import importlib.util
import itertools
import json
import subprocess
import tempfile
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
    planned_files=None,
    planned_bytes=None,
    body="",
):
    result = {
        "number": number,
        "createdAt": created,
        "labels": [{"name": label} for label in labels],
        "body": body,
    }
    if preferred is not None:
        result["preferredProvider"] = preferred
    if comments is not None:
        result["comments"] = [{"body": body} for body in comments]
    if planned_files is not None:
        result["plannedFiles"] = planned_files
    if planned_bytes is not None:
        result["plannedBytes"] = planned_bytes
    return result


class AgentPoolTest(unittest.TestCase):
    def test_reasigna_tarea_corta_para_no_dejar_slot_compatible_ocioso(self):
        workers = [
            {"worker": "amplio", "provider": "qwen", "score": 90},
            {"worker": "corto", "provider": "qwen", "score": 40, "max_task_bytes": 100},
        ]
        for label in ("agent:auto", "agent:qwen"):
            with self.subTest(label=label):
                tasks = mod.select_tasks([
                    issue(1, label, planned_bytes=50, planned_files=["scripts/a.py"]),
                    issue(2, label, planned_bytes=200, planned_files=["scripts/b.py"]),
                ], workers)
                self.assertEqual([(1, "corto"), (2, "amplio")],
                                 [(t["issue"], t["worker"]) for t in tasks])

    def test_reasignacion_encadenada_llena_seis_slots(self):
        workers = [{"worker": f"w{i}", "provider": "qwen", "score": 100-i,
                    "max_task_bytes": (6-i)*100} for i in range(6)]
        issues = [issue(i, "agent:qwen", planned_bytes=i*100,
                        planned_files=[f"scripts/{i}.py"]) for i in range(1, 7)]
        tasks = mod.select_tasks(issues, workers)
        self.assertEqual(list(range(1, 7)), [t["issue"] for t in tasks])
        self.assertEqual([f"w{i}" for i in range(5, -1, -1)], [t["worker"] for t in tasks])

    def test_reasignacion_puede_mover_preferencia_blanda_entre_proveedores(self):
        workers = [{"worker": "q", "provider": "qwen", "score": 90},
                   {"worker": "g", "provider": "gemini", "score": 40}]
        tasks = mod.select_tasks([
            issue(1, "agent:auto", preferred="qwen"),
            issue(2, "agent:auto", comments=[
                "AGENT_POOL_WORKER_FAILURE worker=g provider=gemini stage=implement"
            ]),
        ], workers)
        self.assertEqual([(1, "gemini"), (2, "qwen")],
                         [(t["issue"], t["provider"]) for t in tasks])

    def test_todas_las_compatibilidades_de_tres_tareas_alcanzan_capacidad_posible(self):
        # Oráculo independiente: enumera asignaciones en lugar de repetir la
        # búsqueda de cadenas. Incluye grafos sin hueco y con ciclos.
        workers = [{"worker": f"w{i}", "provider": "qwen"} for i in range(3)]
        opciones = list(itertools.product((-1, 0, 1, 2), repeat=3))
        for mascara in range(1 << 9):
            compatibles = [{j for j in range(3) if mascara & (1 << (i*3+j))}
                          for i in range(3)]
            issues = [issue(i+1, "agent:qwen") for i in range(3)]
            for i, candidato in enumerate(issues):
                candidato["avoidWorkers"] = [f"w{j}" for j in range(3)
                                               if j not in compatibles[i]]
            maximo = max(
                sum(w >= 0 for w in asignacion)
                for asignacion in opciones
                if len({w for w in asignacion if w >= 0}) == sum(w >= 0 for w in asignacion)
                and all(w < 0 or w in compatibles[i] for i, w in enumerate(asignacion))
            )
            tasks = mod.select_tasks(issues, workers)
            with self.subTest(mascara=mascara):
                self.assertEqual(maximo, len(tasks))
                self.assertEqual(len(tasks), len({t["worker"] for t in tasks}))
                self.assertEqual(len(tasks), len({t["issue"] for t in tasks}))
                for tarea in tasks:
                    self.assertIn(int(tarea["worker"][1:]), compatibles[tarea["issue"]-1])

    def test_reasignacion_respeta_evitar_worker_y_salud(self):
        workers = [{"worker": w, "provider": "qwen", "score": score,
                    "healthy": w != "caido"}
                   for w, score in (("amplio", 90), ("reserva", 40), ("caido", 100))]
        tasks = mod.select_tasks([
            issue(1, "agent:qwen", planned_files=["scripts/a.py"]),
            issue(2, "agent:qwen", planned_files=["scripts/b.py"], comments=[
                "AGENT_POOL_WORKER_FAILURE worker=reserva provider=qwen stage=implement"
            ]),
        ], workers)
        self.assertEqual(["reserva", "amplio"], [t["worker"] for t in tasks])

    def test_reasignacion_fallida_conserva_provider_y_asignaciones_previas(self):
        workers = [{"worker": "q", "provider": "qwen", "score": 90},
                   {"worker": "g", "provider": "gemini", "score": 40}]
        tasks = mod.select_tasks([
            issue(1, "agent:qwen", planned_files=["scripts/a.py"]),
            issue(2, "agent:auto", planned_files=["scripts/b.py"], comments=[
                "AGENT_POOL_WORKER_FAILURE worker=g provider=gemini stage=implement"
            ]),
            issue(3, "agent:auto", planned_files=["scripts/c.py"]),
        ], workers)
        self.assertEqual([(1, "q"), (3, "g")], [(t["issue"], t["worker"]) for t in tasks])

    def test_reasignacion_no_habilita_rutas_solapadas(self):
        workers = [{"worker": "amplio", "provider": "qwen", "score": 90},
                   {"worker": "corto", "provider": "qwen", "max_task_bytes": 100}]
        tasks = mod.select_tasks([
            issue(1, "agent:qwen", planned_bytes=50, planned_files=["scripts/a.py"]),
            issue(2, "agent:qwen", planned_bytes=200, planned_files=["scripts/a.py"]),
            issue(3, "agent:qwen", planned_bytes=200, planned_files=["scripts/b.py"]),
        ], workers)
        self.assertEqual([(1, "corto"), (3, "amplio")],
                         [(t["issue"], t["worker"]) for t in tasks])

    def test_capacidad_libre_conserva_score_tier_y_preferencia(self):
        workers = [{"worker": "mejor", "provider": "qwen", "score": 90},
                   {"worker": "corto", "provider": "qwen", "score": 40,
                    "tier": 2, "max_task_bytes": 100}]
        self.assertEqual("mejor", mod.select_tasks([issue(1, "agent:qwen")], workers)[0]["worker"])
        self.assertEqual(1, len(mod.select_tasks([
            issue(1, "agent:qwen", planned_bytes=50),
            issue(2, "agent:qwen", planned_bytes=200),
        ], workers, max_parallel=1)))

    def test_cli_publica_dos_workers_compatibles_en_vez_de_uno(self):
        with tempfile.TemporaryDirectory() as temporal:
            raiz = Path(temporal)
            issues = raiz / "issues.json"
            workers = raiz / "workers.json"
            issues.write_text(json.dumps([
                issue(1, "agent:auto", planned_bytes=50),
                issue(2, "agent:auto", planned_bytes=200),
            ]))
            workers.write_text(json.dumps([
                {"worker": "amplio", "provider": "qwen", "score": 90},
                {"worker": "corto", "provider": "qwen", "max_task_bytes": 100},
            ]))
            result = subprocess.run([
                sys.executable, str(MODULE_PATH), "--issues", str(issues),
                "--workers", str(workers),
            ], capture_output=True, text=True, timeout=10)
            self.assertEqual(0, result.returncode, result.stderr)
            tasks = json.loads(result.stdout)["include"]
            self.assertEqual(["corto", "amplio"], [t["worker"] for t in tasks])

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
            [{"issue": 57, "provider": "qwen", "backend": "qwen", "worker": "qwen-fallback-1"}],
            tasks,
        )

    def test_score_elige_mejor_slot_dentro_del_provider_explicito(self):
        workers = [
            {"worker": "qwen-primary", "provider": "qwen", "score": 35},
            {"worker": "qwen-fallback-1", "provider": "qwen", "score": 88},
        ]

        tasks = mod.select_tasks([issue(57, "agent:qwen")], workers)

        self.assertEqual("qwen-fallback-1", tasks[0]["worker"])

    def test_telemetria_insuficiente_no_penaliza_routing(self):
        worker = mod._worker(
            {
                "worker": "qwen-primary",
                "provider": "qwen",
                "score": 80,
                "telemetry_samples": 2,
                "contract_valid_rate_pct": 0,
                "handoff_loss_proxy_pct": 100,
                "rework_rate_pct": 100,
            }
        )
        self.assertEqual(80.0, worker["routing_score"])
        self.assertEqual(2, worker["telemetry_samples"])

    def test_calidad_handoff_modula_score_tras_tres_muestras(self):
        workers = [
            {
                "worker": "qwen-ruidoso",
                "provider": "qwen",
                "score": 80,
                "telemetry_samples": 3,
                "contract_valid_rate_pct": 0,
                "handoff_loss_proxy_pct": 100,
                "rework_rate_pct": 100,
            },
            {
                "worker": "qwen-estable",
                "provider": "qwen",
                "score": 60,
                "telemetry_samples": 3,
                "contract_valid_rate_pct": 100,
                "handoff_loss_proxy_pct": 0,
                "rework_rate_pct": 0,
            },
        ]

        normalizado = mod._worker(workers[0])
        self.assertEqual(50.0, normalizado["routing_score"])
        tasks = mod.select_tasks([issue(570, "agent:qwen")], workers)
        self.assertEqual("qwen-estable", tasks[0]["worker"])

    def test_telemetria_ausente_o_invalida_es_fail_open(self):
        for samples in ("x", True, -1, None):
            with self.subTest(samples=samples):
                worker = mod._worker(
                    {
                        "worker": "qwen-primary",
                        "provider": "qwen",
                        "score": 72,
                        "telemetry_samples": samples,
                        "contract_valid_rate_pct": "mal",
                        "handoff_loss_proxy_pct": None,
                    }
                )
                self.assertEqual(72.0, worker["routing_score"])
                self.assertEqual(0, worker["telemetry_samples"])

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

    def test_slot_limitado_gana_empate_en_tarea_pequena(self):
        workers = [
            {"worker": "qwen-primary", "provider": "qwen", "score": 50},
            {
                "worker": "qwen-fallback-groq",
                "provider": "qwen",
                "score": 50,
                "max_task_bytes": 20000,
            },
        ]

        tasks = mod.select_tasks(
            [issue(590, "agent:qwen", planned_bytes=6000, body="x" * 1000)],
            workers,
        )

        self.assertEqual("qwen-fallback-groq", tasks[0]["worker"])

    def test_slot_limitado_no_recibe_tarea_sobredimensionada(self):
        workers = [
            {"worker": "qwen-primary", "provider": "qwen", "score": 50},
            {
                "worker": "qwen-fallback-groq",
                "provider": "qwen",
                "score": 99,
                "max_task_bytes": 8000,
            },
        ]

        tasks = mod.select_tasks(
            [issue(591, "agent:qwen", planned_bytes=9000, body="instrucciones")],
            workers,
        )

        self.assertEqual("qwen-primary", tasks[0]["worker"])

    def test_score_historico_sigue_mandando_antes_que_especializacion(self):
        workers = [
            {"worker": "qwen-primary", "provider": "qwen", "score": 51},
            {
                "worker": "qwen-fallback-groq",
                "provider": "qwen",
                "score": 50,
                "max_task_bytes": 20000,
            },
        ]
        tasks = mod.select_tasks(
            [issue(592, "agent:qwen", planned_bytes=1000)],
            workers,
        )
        self.assertEqual("qwen-primary", tasks[0]["worker"])

    def test_presupuesto_invalido_se_normaliza_a_sin_limite(self):
        for value in (-1, "x", True, None):
            with self.subTest(value=value):
                worker = mod._worker(
                    {"worker": "w", "provider": "qwen", "max_task_bytes": value}
                )
                self.assertEqual(0, worker["max_task_bytes"])

    def test_backend_se_propaga_sin_cambiar_provider(self):
        workers = [
            {
                "worker": "qwen-fallback-groq",
                "provider": "qwen",
                "backend": "groq",
                "score": 50,
            }
        ]
        tasks = mod.select_tasks([issue(593, "agent:qwen")], workers)
        self.assertEqual(
            [{"issue": 593, "provider": "qwen", "backend": "groq", "worker": "qwen-fallback-groq"}],
            tasks,
        )

    def test_backend_invalido_se_reduce_a_custom(self):
        worker = mod._worker(
            {"worker": "slot", "provider": "qwen", "backend": "https://privado.local/token"}
        )
        self.assertEqual("custom", worker["backend"])

    def test_worker_sin_backend_conserva_compatibilidad(self):
        worker = mod._worker({"worker": "qwen-primary", "provider": "qwen"})
        self.assertEqual("qwen", worker["backend"])

    def test_slot_no_saludable_sale_de_rotacion_para_tarea_flexible(self):
        workers = [
            {"worker": "gemini", "provider": "gemini", "healthy": False},
            {"worker": "qwen-primary", "provider": "qwen", "healthy": True},
        ]
        candidate = issue(58, "agent:auto", preferred="gemini")

        tasks = mod.select_tasks([candidate], workers)

        self.assertEqual(
            [{"issue": 58, "provider": "qwen", "backend": "qwen", "worker": "qwen-primary"}],
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

    def test_no_selecciona_dos_issues_con_ruta_planificada_solapada(self):
        issues = [
            issue(62, "agent:auto", planned_files=["godot/guion/dia.gd"]),
            issue(63, "agent:auto", planned_files=["godot/guion/dia.gd"]),
            issue(64, "agent:auto", planned_files=["godot/guion/casa.gd"]),
        ]

        tasks = mod.select_tasks(issues, self.workers, max_parallel=3)

        self.assertEqual([62, 64], [task["issue"] for task in tasks])

    def test_directorio_y_descendiente_no_comparten_dispatch(self):
        pares = [
            ("godot/assets/audio/chip", "godot/assets/audio/chip/ui_error.ogg"),
            ("godot/assets/audio/chip", "godot/assets/audio/chip/subdir"),
            ("./godot//assets/audio/chip/", "godot/assets/audio/./chip/ui_error.ogg"),
            ("godot/assets/audio/chip/ui_error.ogg", "./godot//assets/audio/chip/ui_error.ogg"),
            ("godot\\assets\\audio\\chip", "godot/assets/audio/chip/ui_error.ogg"),
        ]
        for primera, segunda in pares:
            for rutas in ((primera, segunda), (segunda, primera)):
                with self.subTest(rutas=rutas):
                    issues = [
                        issue(101, "agent:auto", planned_files=[rutas[0]]),
                        issue(102, "agent:auto", planned_files=[rutas[1]]),
                        issue(103, "agent:auto", planned_files=["scripts/independiente.py"]),
                    ]
                    tasks = mod.select_tasks(issues, self.workers, max_parallel=3)
                    self.assertEqual([101, 103], [t["issue"] for t in tasks])

    def test_directorios_hermanos_y_prefijos_lexicos_son_independientes(self):
        rutas = ["godot/assets/audio/chip", "godot/assets/audio/chip_extra/a.ogg",
                 "godot/assets/audio/kenney/a.ogg", "godot/assets/audio/chip.gd"]
        issues = [issue(101 + i, "agent:auto", planned_files=[ruta])
                  for i, ruta in enumerate(rutas)]
        tasks = mod.select_tasks(issues, self.workers)
        self.assertEqual([101, 102, 103, 104], [t["issue"] for t in tasks])

    def test_proveedor_explicito_reserva_directorio_antes_de_tarea_flexible(self):
        issues = [
            issue(101, "agent:auto", planned_files=["godot/assets/audio/chip/a.ogg"]),
            issue(102, "agent:gemini", planned_files=["godot/assets/audio/chip"]),
            issue(103, "agent:auto", planned_files=["scripts/independiente.py"]),
        ]
        tasks = mod.select_tasks(issues, self.workers)
        self.assertEqual([102, 103], [t["issue"] for t in tasks])
        self.assertEqual("gemini", tasks[0]["provider"])

    def test_cli_publica_matrix_sin_solape_de_directorios(self):
        with tempfile.TemporaryDirectory() as temporal:
            raiz = Path(temporal)
            issues = raiz / "issues.json"
            workers = raiz / "workers.json"
            output = raiz / "matrix.json"
            issues.write_text(json.dumps([
                issue(101, "agent:auto", planned_files=["./godot/assets/audio/chip/"]),
                issue(102, "agent:auto", planned_files=["godot/assets/audio/chip/a.ogg"]),
                issue(103, "agent:auto", planned_files=["godot/assets/audio/chip_extra/a.ogg"]),
            ]))
            workers.write_text(json.dumps(self.workers))
            result = subprocess.run([
                sys.executable, str(MODULE_PATH), "--issues", str(issues),
                "--workers", str(workers), "--output", str(output),
            ], capture_output=True, text=True, timeout=10)
            self.assertEqual(0, result.returncode, result.stderr)
            matrix = json.loads(result.stdout)
            self.assertEqual([101, 103], [t["issue"] for t in matrix["include"]])
            self.assertEqual(matrix, json.loads(output.read_text()))

    def test_plan_sin_rutas_no_bloquea_paralelismo(self):
        issues = [
            issue(65, "agent:auto", planned_files=[]),
            issue(66, "agent:auto", planned_files=[]),
        ]

        tasks = mod.select_tasks(issues, self.workers, max_parallel=2)

        self.assertEqual([65, 66], [task["issue"] for task in tasks])

    def test_rutas_invalidas_no_entran_en_afinidad(self):
        candidate = issue(
            67,
            "agent:auto",
            planned_files=["../escape", "/absoluta", "godot/guion/segura.gd"],
        )
        self.assertEqual({"godot/guion/segura.gd"}, mod._planned_files(candidate))

    def test_slot_ocupado_no_entra_en_la_matrix(self):
        issues = [issue(201, "agent:auto"), issue(202, "agent:auto")]
        workers = [
            {"worker": "qwen-primary", "provider": "qwen", "occupied": True},
            {"worker": "gemini", "provider": "gemini", "occupied": False},
        ]

        tasks = mod.select_tasks(issues, workers, max_parallel=2)

        self.assertEqual(1, len(tasks))
        self.assertEqual("gemini", tasks[0]["worker"])

    def test_slot_liberado_vuelve_a_ser_elegible(self):
        issues = [issue(203, "agent:qwen")]
        ocupado = [{"worker": "qwen-primary", "provider": "qwen", "occupied": True}]
        libre = [{"worker": "qwen-primary", "provider": "qwen", "occupied": False}]

        self.assertEqual([], mod.select_tasks(issues, ocupado))
        self.assertEqual("qwen-primary", mod.select_tasks(issues, libre)[0]["worker"])

    def test_ocupacion_no_booleana_no_fabrica_un_bloqueo(self):
        issues = [issue(204, "agent:auto")]
        workers = [{"worker": "qwen-primary", "provider": "qwen", "occupied": "unknown"}]

        tasks = mod.select_tasks(issues, workers)

        self.assertEqual("qwen-primary", tasks[0]["worker"])

    def test_max_parallel_cero_aplica_backpressure_total(self):
        tasks = mod.select_tasks(
            [issue(68, "agent:auto")],
            self.workers,
            max_parallel=0,
        )
        self.assertEqual([], tasks)

    def test_max_parallel_no_puede_superar_seis(self):
        issues = [issue(n, "agent:auto") for n in range(70, 80)]
        workers = self.workers + [
            {"worker": "extra-1", "provider": "qwen"},
            {"worker": "extra-2", "provider": "qwen"},
        ]
        self.assertEqual(6, len(mod.select_tasks(issues, workers, max_parallel=99)))

    def test_slot_ocupado_no_entra_en_matrix(self):
        workers = [
            {"worker": "qwen-primary", "provider": "qwen", "occupied": True},
            {"worker": "gemini", "provider": "gemini", "occupied": False},
        ]
        tasks = mod.select_tasks(
            [issue(81, "agent:auto"), issue(82, "agent:auto")],
            workers,
            max_parallel=2,
        )
        self.assertEqual(1, len(tasks))
        self.assertEqual("gemini", tasks[0]["worker"])

    def test_todos_los_slots_ocupados_dejan_matrix_vacia(self):
        workers = [
            {"worker": "qwen-primary", "provider": "qwen", "occupied": True},
            {"worker": "gemini", "provider": "gemini", "occupied": True},
        ]
        self.assertEqual(
            [],
            mod.select_tasks([issue(83, "agent:auto")], workers, max_parallel=2),
        )

    def test_occupied_ausente_o_false_es_fail_open(self):
        workers = [
            {"worker": "qwen-primary", "provider": "qwen"},
            {"worker": "gemini", "provider": "gemini", "occupied": False},
        ]
        tasks = mod.select_tasks(
            [issue(84, "agent:auto"), issue(85, "agent:auto")],
            workers,
            max_parallel=2,
        )
        self.assertEqual(2, len(tasks))
        self.assertEqual({"qwen-primary", "gemini"}, {t["worker"] for t in tasks})

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
        self.assertIn('issues/$issue/comments?per_page=100', pool)
        self.assertIn("scripts/agent_delegated_plan.py", pool)
        self.assertIn("AGENT_POOL_WORKER_FAILURE", worker)
        self.assertIn("AGENT_POOL_SLOT_UNHEALTHY", worker)
        self.assertIn("AGENT_PROVIDER_COOLDOWN_SECONDS", worker)
        self.assertIn("gemini-client-error-", worker)
        self.assertIn("AGENT_POOL_SLOT_UNHEALTHY", pool)
        self.assertIn("healthy", pool)
        self.assertIn("/api/agent-pool/worker-status", pool)
        self.assertIn("occupied", pool)
        self.assertIn("Ocupación KV no disponible", pool)
        self.assertIn("scripts/agent_pool_backpressure.py", pool)
        self.assertIn("AGENT_POOL_ACTIONS_BUDGET", pool)
        self.assertIn("plannedFiles", pool)
        self.assertIn("plannedBytes", pool)
        self.assertIn('wc -c < "$path"', pool)
        self.assertIn('backend=\\(.backend // .provider)', pool)
        self.assertIn('"route issue=#\\(.issue)', pool)
        self.assertIn("scripts/agent_delegated_plan.py", pool)
        self.assertNotIn('maxSessionTurns":16', worker)
        self.assertIn('maxSessionTurns":40', worker)
        self.assertNotIn("- id: plan_qwen\n", worker)
        self.assertNotIn("- id: plan_gemini\n", worker)
        self.assertRegex(worker, r"tailscale/github-action@[0-9a-f]{40}")
        self.assertIn("steps.omniroute.outputs.ready", worker)
        self.assertNotIn("\n  schedule:\n", autopilot)
        self.assertNotIn("\n  issues:\n", autopilot)

    def test_score_historico_ignora_dispatchers_sin_worker(self):
        pool = (ROOT / ".github" / "workflows" / "agent-pool.yml").read_text(
            encoding="utf-8"
        )
        self.assertIn(
            "runs?event=workflow_dispatch&status=completed&per_page=100",
            pool,
        )
        self.assertIn("history_worker_runs=0", pool)
        self.assertIn('if (( worker_jobs == 0 )); then', pool)
        self.assertIn("history_worker_runs=$((history_worker_runs + 1))", pool)
        self.assertIn("if (( history_worker_runs >= 8 )); then", pool)
        self.assertNotIn("runs?status=completed&per_page=40", pool)
        self.assertNotIn("runs?status=completed&per_page=8", pool)

    def test_fallo_se_clasifica_antes_de_decidir_retry_o_rotacion(self):
        worker = (ROOT / ".github" / "workflows" / "agent-worker.yml").read_text(
            encoding="utf-8"
        )
        self.assertIn("id: validate_diff", worker)
        self.assertIn('echo "retry_stage=implement" >> "$GITHUB_OUTPUT"', worker)
        self.assertIn('echo "retry_stage=no-changes" >> "$GITHUB_OUTPUT"', worker)
        self.assertIn('echo "retry_stage=preflight" >> "$GITHUB_OUTPUT"', worker)
        self.assertIn("RETRY_STAGE: ${{ steps.validate_diff.outputs.retry_stage }}", worker)

        cleanup = worker.split("- name: Limpiar fallo o cancelacion", 1)[1]
        self.assertIn('if [[ "${RESERVED:-}" == true', cleanup)
        self.assertIn('retry_stage="$RETRY_STAGE"', cleanup)
        self.assertIn("scripts/agent_failure_policy.py", cleanup)
        self.assertIn("same_worker_fix|split_or_same_worker", cleanup)
        self.assertIn("rotate_provider)", cleanup)
        self.assertIn("stop_noop)", cleanup)
        self.assertIn("AGENT_POOL_SAME_WORKER_RETRY", cleanup)
        self.assertIn("-f retry_hint=", cleanup)
        self.assertIn("AGENT_POOL_WORKER_FAILURE", cleanup)
        self.assertIn("solo esta clase de fallo rota worker/proveedor", cleanup)

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
            'retry_stage=""', 1
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
