"""Contrato real de selección mientras otros workers siguen ejecutando."""

import copy
import itertools
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest

from scripts.agent_pool_refill import build_refill_matrix


ROOT = Path(__file__).resolve().parents[1]


def issue(number, path=None, provider="auto"):
    return {"number": number, "labels": [f"agent:{provider}"],
            "plannedFiles": [path or f"scripts/{number}.py"]}


def lease(worker, number, files=None):
    return {"worker": worker, "issue": number, "files": files or []}


class RefillTest(unittest.TestCase):
    def setUp(self):
        self.workers = [{"worker": worker, "provider": "qwen"} for worker in "ABC"]
        self.status = {"ok": True, "leases": [lease("B", 2), lease("C", 3)]}

    def select(self, status=None, **kwargs):
        args = {"requested": 3, "queued": 0, "in_progress": 1, "budget": 12}
        args.update(kwargs)
        return build_refill_matrix([issue(n) for n in range(1, 8)], self.workers,
                                   self.status if status is None else status, **args)

    def test_a_libre_recibe_d_mientras_b_y_c_siguen(self):
        result = build_refill_matrix([issue(2), issue(3), issue(4)], self.workers,
                                    self.status, requested=3, queued=0,
                                    in_progress=1, budget=12)
        self.assertEqual(1, result["capacity"])
        self.assertEqual([(4, "A")], [(t["issue"], t["worker"]) for t in result["include"]])

    def test_todas_las_ocupaciones_respetan_limite_agregado(self):
        for mask, requested in itertools.product(range(8), range(7)):
            busy = {w for i, w in enumerate("ABC") if mask & (1 << i)}
            status = {"ok": True, "leases": [lease(w, i + 100) for i, w in enumerate(sorted(busy))]}
            result = self.select(status, requested=requested)
            selected = result["include"]
            self.assertFalse(busy & {t["worker"] for t in selected})
            self.assertLessEqual(len(selected), max(0, requested - len(busy)))
            self.assertEqual(min(3-len(busy), max(0, requested-len(busy))), len(selected))

    def test_actions_saturado_y_lecturas_ausentes_no_lanzan(self):
        for args in ({"queued": 10, "in_progress": 2}, {"queued": None},
                     {"in_progress": None}, {"queued": -1}, {"in_progress": True}):
            with self.subTest(args=args):
                self.assertEqual([], self.select(**args)["include"])

    def test_presupuesto_actions_limita_capacidad_positiva(self):
        result = self.select({"ok": True, "leases": []}, queued=10, in_progress=1)
        self.assertEqual(1, result["capacity"])
        self.assertEqual(1, len(result["include"]))

    def test_control_invalido_falla_cerrado(self):
        invalid = [{}, {"ok": False, "leases": []}, {"ok": True},
                   {"ok": True, "leases": {}}, {"ok": True, "leases": [None]},
                   {"ok": True, "leases": [lease("", 2)]},
                   {"ok": True, "leases": [lease("B", True)]},
                   {"ok": True, "leases": [lease("B", 2, [None])]},
                   {"ok": True, "leases": [lease("B", 2, ["../secreto"])]},
                   {"ok": True, "leases": [lease("B", 2, ["/absoluto"])]}]
        for status in invalid:
            with self.subTest(status=status):
                self.assertEqual({"include": [], "capacity": 0, "reason": "control_unavailable"},
                                 self.select(status))

    def test_lease_repetido_no_descuenta_slot_dos_veces(self):
        status = copy.deepcopy(self.status)
        status["leases"].append(lease("B", 2))
        self.assertEqual(self.select(), self.select(status))

    def test_slot_ya_no_configurado_tambien_consume_presupuesto(self):
        status = {"ok": True, "leases": [lease("retirado", 2), lease("B", 3)]}
        self.assertEqual(1, len(self.select(status)["include"]))

    def test_rutas_con_alias_y_directorios_quedan_bloqueados(self):
        status = {"ok": True, "leases": [lease("B", 2, ["./scripts//shared"])]}
        candidates = [issue(1, "scripts/shared/a.py"), issue(2),
                      issue(3, "scripts"), issue(4, "scripts/shared_extra/a.py")]
        result = build_refill_matrix(candidates, self.workers, status, requested=3,
                                    queued=0, in_progress=1, budget=12)
        self.assertEqual([4], [t["issue"] for t in result["include"]])

    def test_no_sobrescribe_cooldown_preferencia_ni_ocupacion_previa(self):
        workers = [{"worker": "A", "provider": "qwen", "healthy": False},
                   {"worker": "B", "provider": "gemini", "occupied": True},
                   {"worker": "C", "provider": "qwen"}]
        args = dict(requested=3, queued=0, in_progress=1, budget=12)
        self.assertEqual([], build_refill_matrix([issue(4, provider="gemini")], workers,
                                                {"ok": True, "leases": []}, **args)["include"])
        result = build_refill_matrix([issue(4)], workers, {"ok": True, "leases": []}, **args)
        self.assertEqual("C", result["include"][0]["worker"])

    def test_snapshot_legacy_sin_files_y_entradas_no_mutadas(self):
        status = {"ok": True, "leases": [{"worker": "B", "issue": 2}]}
        before = copy.deepcopy((self.workers, status))
        self.assertTrue(self.select(status)["include"])
        self.assertEqual(before, (self.workers, status))

    def test_ocupacion_previa_tambien_descuenta_presupuesto(self):
        workers = copy.deepcopy(self.workers)
        workers[0]["occupied"] = True
        result = build_refill_matrix([issue(4), issue(5)], workers,
                                    {"ok": True, "leases": []}, requested=1,
                                    queued=0, in_progress=1, budget=12)
        self.assertEqual(0, result["capacity"])
        self.assertEqual([], result["include"])

    def test_no_backlog_no_seleccion(self):
        result = build_refill_matrix([], self.workers, self.status, requested=3,
                                    queued=0, in_progress=1, budget=12)
        self.assertEqual([], result["include"])

    def test_refill_repone_solo_el_slot_liberado(self):
        for target, expected in (("A", ["A"]), ("B", []), ("desconocido", [])):
            result = self.select(refill_worker=target)
            self.assertEqual(expected, [t["worker"] for t in result["include"]])

    def test_cli_real_y_status_roto_degradan_sin_excepcion(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, data in (("issues", [issue(4)]), ("workers", self.workers),
                               ("status", self.status)):
                (root / name).write_text(json.dumps(data))
            cmd = [sys.executable, str(ROOT / "scripts/agent_pool_refill.py"),
                   "--issues", str(root / "issues"), "--workers", str(root / "workers"),
                   "--worker-status", str(root / "status"), "--requested", "3",
                   "--queued", "0", "--in-progress", "1", "--budget", "12"]
            run = subprocess.run(cmd, capture_output=True, text=True, check=True)
            self.assertEqual("A", json.loads(run.stdout)["include"][0]["worker"])
            (root / "status").write_text("bad json")
            run = subprocess.run(cmd, capture_output=True, text=True, check=True)
            self.assertEqual("control_unavailable", json.loads(run.stdout)["reason"])


@unittest.skipUnless(shutil.which("bash") and shutil.which("jq"), "requiere bash y jq")
class RefillWorkflowTest(unittest.TestCase):
    def setUp(self):
        self.pool = (ROOT / ".github/workflows/agent-pool.yml").read_text()
        self.worker = (ROOT / ".github/workflows/agent-worker.yml").read_text()

    def test_concurrencia_refill_es_distinta_y_estable_por_slot(self):
        import yaml
        group = yaml.safe_load(self.pool)["concurrency"]["group"]
        self.assertIn("inputs.refill_worker && format('refill-{0}', inputs.refill_worker)", group)
        self.assertIn("|| 'queue'", group)
        self.assertNotIn("github.run_id", group)

    def seleccionar_shell(self, *, occupancy=True, actions=True, target="A"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, data in (
                ("issues.json", [issue(2), issue(3), issue(4)]),
                ("workers.json", [{"worker": w, "provider": "qwen"} for w in "ABC"]),
                ("worker-occupancy-kv.json", {"ok": True, "leases": [lease("B", 2), lease("C", 3)]}
                 if occupancy else {}),
            ):
                (root / name).write_text(json.dumps(data))
            start = self.pool.index("          # #2239: el refill solo")
            end = self.pool.index('\n          matrix="', start)
            shell = textwrap.dedent(self.pool[start:end]).replace("/tmp/", f"{root}/")
            run = subprocess.run(["bash", "-euo", "pipefail", "-c", shell], cwd=ROOT,
                                 env={**os.environ, "REFILL_WORKER": target, "REQUESTED_MAX": "3",
                                      "effective_max": "3", "ACTIONS_BUDGET": "12",
                                      "queued_runs": "0", "active_runs": "1",
                                      "actions_from_github": str(actions).lower()},
                                 capture_output=True, text=True)
            self.assertEqual(0, run.returncode, run.stdout + run.stderr)
            return json.loads((root / "matrix.json").read_text())

    def test_shell_real_selecciona_a_antes_de_terminar_b_c(self):
        result = self.seleccionar_shell()
        self.assertEqual([(4, "A")], [(t["issue"], t["worker"]) for t in result["include"]])

    def test_shell_real_caida_deno_o_actions_no_genera_matrix(self):
        for args in ({"occupancy": False}, {"actions": False}, {"target": "B"}):
            with self.subTest(args=args):
                self.assertEqual([], self.seleccionar_shell(**args)["include"])

    def test_shell_real_flag_apagada_detiene_refill(self):
        start = self.pool.index('          if [[ -n "$REFILL_WORKER"')
        end = self.pool.index("\n          for label", start)
        shell = textwrap.dedent(self.pool[start:end])
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "out"
            run = subprocess.run(["bash", "-euo", "pipefail", "-c", shell],
                                 env={**os.environ, "REFILL_WORKER": "A", "REFILL_ENABLED": "false",
                                      "GITHUB_OUTPUT": str(output)}, capture_output=True, text=True)
            self.assertEqual(0, run.returncode, run.stderr)
            self.assertIn('matrix={"include":[]}', output.read_text())
            self.assertIn("count=0", output.read_text())

    def test_shell_worker_dispatch_incluye_slot_y_no_dispara_sin_backlog(self):
        start = self.worker.index("      - name: Refill opt-in tras liberar slot")
        shell = textwrap.dedent(self.worker[start:].split("        run: |\n", 1)[1])
        for pending in (False, True):
            with self.subTest(pending=pending), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                log = root / "log"
                stub = root / "gh"
                stub.write_text(f"#!{sys.executable}\n" + textwrap.dedent('''\
                    import json, os, sys
                    from pathlib import Path
                    if sys.argv[1:3] == ['issue', 'list']:
                        print(json.dumps([{'number': 4, 'labels': [{'name':'agent:auto'}]}]
                                         if os.environ['PENDING'] == 'true' else []))
                    elif sys.argv[1:3] == ['workflow', 'run']:
                        Path(os.environ['LOG']).write_text(json.dumps(sys.argv[1:]))
                    else:
                        raise SystemExit(4)
                    '''))
                stub.chmod(0o755)
                run = subprocess.run(["bash", "-euo", "pipefail", "-c",
                                      shell.replace("/tmp/", f"{root}/")],
                                     env={**os.environ, "PATH": f"{root}:{os.environ['PATH']}",
                                          "REFILL_WORKER": "A", "REQUESTED_MAX": "3",
                                          "GITHUB_REPOSITORY": "example/repo", "LOG": str(log),
                                          "PENDING": str(pending).lower()},
                                     capture_output=True, text=True)
                self.assertEqual(0, run.returncode, run.stdout + run.stderr)
                self.assertEqual(pending, log.exists())
                if pending:
                    args = json.loads(log.read_text())
                    self.assertIn("refill_worker=A", args)
                    self.assertIn("max_parallel=3", args)


if __name__ == "__main__":
    unittest.main()
