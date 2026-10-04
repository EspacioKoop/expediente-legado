"""Canario offline del cleanup real: rotación, cooldown y retry acotado.

Solo gh/curl y el registro de reservas son dobles locales. La política y el
selector son los scripts versionados; no se ejecutan modelos ni Actions.
"""

from pathlib import Path
import json
import os
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("bash") and shutil.which("jq"), "requiere bash y jq")
class AgentFailureCanary1907Test(unittest.TestCase):
    def ejecutar(self, fallo, stage="implementing", etiqueta="agent:auto", previous=False):
        with tempfile.TemporaryDirectory(prefix="failure-canario-") as temporal:
            raiz = Path(temporal)
            scratch = raiz / "tmp"
            scratch.mkdir()
            binarios = raiz / "bin"
            binarios.mkdir()
            scripts = raiz / "scripts"
            scripts.mkdir()
            for nombre in ("agent_failure_policy.py", "agent_slots.py"):
                shutil.copyfile(ROOT / "scripts" / nombre, scripts / nombre)
            (scripts / "gestionar_reservas_rollover.py").write_text("print(1713)\n")
            estado = raiz / "estado.json"
            registro = raiz / "comandos.jsonl"
            plan = "AGENT_PLAN: modificar scripts/canario.py; validar contrato existente."
            comentarios = [{"body": "AGENT_POOL_SAME_WORKER_RETRY category=test_or_preflight worker=qwen-primary stage=preflight run=6"}] if previous else []
            estado.write_text(json.dumps({
                "number": 1907, "body": plan,
                "labels": [etiqueta, "agent:working"], "comments": comentarios,
            }))
            doble = textwrap.dedent('''\
                import json
                import os
                from pathlib import Path
                import sys

                args = sys.argv[1:]
                nombre = Path(sys.argv[0]).name
                with open(os.environ["CANARIO_REGISTRO"], "a") as out:
                    out.write(json.dumps({"command": nombre, "args": args}) + "\\n")
                estado = Path(os.environ["CANARIO_ESTADO"])
                data = json.loads(estado.read_text())
                if nombre == "gh" and args[:2] == ["pr", "list"]:
                    pass
                elif nombre == "gh" and args[:2] == ["issue", "comment"]:
                    if args[2] == "1907":
                        data["comments"].append({"body": args[args.index("--body") + 1]})
                        estado.write_text(json.dumps(data))
                elif nombre == "gh" and args[:2] == ["issue", "edit"]:
                    for i, arg in enumerate(args):
                        if arg == "--remove-label" and args[i+1] in data["labels"]:
                            data["labels"].remove(args[i+1])
                        elif arg == "--add-label" and args[i+1] not in data["labels"]:
                            data["labels"].append(args[i+1])
                    estado.write_text(json.dumps(data))
                elif nombre == "gh" and args[:2] == ["issue", "view"]:
                    field = args[args.index("--json") + 1]
                    if field == "comments":
                        print(json.dumps({"comments": data["comments"]}))
                    elif field == "labels":
                        print(" ".join(data["labels"]))
                    else:
                        raise SystemExit("Consulta no prevista: " + field)
                elif nombre == "gh" and args[:3] == ["workflow", "run", "agent-worker.yml"]:
                    pass
                else:
                    raise SystemExit("Comando no previsto: " + nombre + " " + str(args))
                ''')
            for nombre in ("gh", "curl", "git"):
                ruta = binarios / nombre
                ruta.write_text(f"#!{sys.executable}\n" + doble)
                ruta.chmod(0o755)
            (binarios / "python3").symlink_to(sys.executable)
            env = {
                "PATH": str(binarios) + os.pathsep + os.defpath,
                "CANARIO_ESTADO": str(estado), "CANARIO_REGISTRO": str(registro),
                "GITHUB_REPOSITORY": "example/canario", "GITHUB_RUN_ID": "7",
                "ISSUE": "1907", "BRANCH": "agent/canario-1907", "RESERVED": "true",
                "WORKER": "qwen-primary", "PROVIDER": "qwen",
                "HAS_QWEN": "true", "HAS_GEMINI": "true",
                "VARS_JSON": "{}", "POOL_FALLBACK_KEYS": "", "CONTROL_URL": "",
                "JOB_STATUS": "failure", "RETRY_STAGE": stage,
                "RUNNER_TEMP": str(scratch), "AGENT_PROVIDER_COOLDOWN_SECONDS": "3600",
            }
            log = scratch / "agent-preflight-failure.log" if stage == "preflight" else scratch / "agent-output-implement/stderr.log"
            log.parent.mkdir(exist_ok=True)
            log.write_text(fallo)
            workflow = (ROOT / ".github/workflows/agent-worker.yml").read_text()
            inicio = workflow.index("      - name: Limpiar fallo o cancelacion\n")
            fin = workflow.index("\n      - name: Liberar lease Deno KV", inicio)
            shell = textwrap.dedent(workflow[inicio:fin].split("        run: |\n", 1)[1])
            # Solo se redirigen los temporales del shell y sus Python inline.
            shell = shell.replace("/tmp/", str(scratch) + "/")
            resultado = subprocess.run(["bash", "-c", shell], cwd=raiz, env=env,
                                       capture_output=True, text=True, timeout=15)
            self.assertEqual(0, resultado.returncode, resultado.stderr)
            data = json.loads(estado.read_text())
            comandos = [json.loads(linea) for linea in registro.read_text().splitlines()]
            self.assertEqual(plan, data["body"])
            self.assertNotIn("agent:working", data["labels"])
            self.assertTrue(any(c["args"][:3] == ["issue", "comment", "1713"]
                                and c["args"][-1].startswith("RELEASE issue=#1907 ") for c in comandos))
            self.assertTrue(all(c["command"] == "gh" for c in comandos))
            issues = raiz / "issues.json"
            workers = raiz / "workers.json"
            issues.write_text(json.dumps([data]))
            workers.write_text(json.dumps([
                {"worker": "qwen-primary", "provider": "qwen", "healthy": True},
                {"worker": "gemini", "provider": "gemini", "healthy": True},
            ]))
            seleccion = subprocess.run([
                sys.executable, str(ROOT / "scripts/agent_pool.py"), "--issues", str(issues),
                "--workers", str(workers), "--max-parallel", "1",
            ], capture_output=True, text=True, timeout=10)
            self.assertEqual(0, seleccion.returncode, seleccion.stderr)
            return data, comandos, json.loads(seleccion.stdout)["include"]

    def test_cuota_y_sobrecarga_liberan_y_rotan_con_cooldown(self):
        for fallo in ("HTTP 429 Too Many Requests", "HTTP 503 overloaded"):
            with self.subTest(fallo=fallo):
                data, comandos, seleccion = self.ejecutar(fallo)
                self.assertNotIn("agent:needs-human", data["labels"])
                self.assertEqual("gemini", seleccion[0]["worker"])
                self.assertTrue(any("category=quota_or_overload" in c["body"] for c in data["comments"]))
                self.assertTrue(any("AGENT_POOL_SLOT_UNHEALTHY worker=qwen-primary" in c["args"][-1]
                                    for c in comandos))
                self.assertFalse(any(c["args"][:2] == ["workflow", "run"] for c in comandos))

    def test_transporte_rota_sin_penalizacion_de_cuota(self):
        data, comandos, seleccion = self.ejecutar("connection reset by peer")
        self.assertEqual("gemini", seleccion[0]["worker"])
        self.assertTrue(any("category=provider_or_transport" in c["body"] for c in data["comments"]))
        self.assertFalse(any("AGENT_POOL_SLOT_UNHEALTHY" in c["args"][-1] for c in comandos))
        self.assertFalse(any(c["args"][:2] == ["workflow", "run"] for c in comandos))

    def test_preflight_reintenta_mismo_worker_con_feedback_acotado(self):
        data, comandos, _ = self.ejecutar("AssertionError: expected true\n" * 50, "preflight")
        runs = [c["args"] for c in comandos if c["args"][:2] == ["workflow", "run"]]
        self.assertEqual(1, len(runs))
        self.assertIn("worker=qwen-primary", runs[0])
        self.assertIn("provider=qwen", runs[0])
        hint = next(a for a in runs[0] if a.startswith("retry_hint="))
        self.assertIn("AssertionError: expected true", hint)
        self.assertLess(len(hint), 900)
        self.assertNotIn("agent:needs-human", data["labels"])
        self.assertFalse(any("AGENT_POOL_WORKER_FAILURE" in c["body"] for c in data["comments"]))
        self.assertFalse(any("AGENT_POOL_SLOT_UNHEALTHY" in c["args"][-1] for c in comandos))

    def test_preflight_repetido_se_detiene_sin_castigar_worker(self):
        data, comandos, seleccion = self.ejecutar("AssertionError: expected true", "preflight", previous=True)
        self.assertIn("agent:needs-human", data["labels"])
        self.assertEqual([], seleccion)
        self.assertFalse(any(c["args"][:2] == ["workflow", "run"] for c in comandos))
        self.assertFalse(any("AGENT_POOL_WORKER_FAILURE" in c["body"] for c in data["comments"]))
        self.assertFalse(any("AGENT_POOL_SLOT_UNHEALTHY" in c["args"][-1] for c in comandos))

    def test_proveedor_explicito_agotado_no_cruza_a_gemini(self):
        data, _, seleccion = self.ejecutar("HTTP 429 Too Many Requests", etiqueta="agent:qwen")
        self.assertIn("agent:needs-human", data["labels"])
        self.assertEqual([], seleccion)


if __name__ == "__main__":
    unittest.main()
