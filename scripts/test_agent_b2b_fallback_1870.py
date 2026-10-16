"""Canario sin red: ejecuta el shell real del worker con el mailbox caído.

Git/gh se sustituyen por registros locales; el cliente B2B real recibe 503 o
timeout. No ejecuta modelos, publica PRs ni requiere credenciales/servicios.
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
WORKFLOW = ROOT / ".github/workflows/agent-worker.yml"


def paso(marcador):
    texto = WORKFLOW.read_text(encoding="utf-8")
    inicio = texto.index(marcador)
    fin = texto.find("\n      - ", inicio + len(marcador))
    bloque = texto[inicio:] if fin < 0 else texto[inicio:fin]
    shell = bloque.split("        run: |\n", 1)[1]
    return bloque, textwrap.dedent(shell)


@unittest.skipUnless(shutil.which("bash") and shutil.which("jq"), "requiere bash y jq")
class AgentB2BFallback1870Test(unittest.TestCase):
    def ejecutar_canario(self, fallo, verdict):
        with tempfile.TemporaryDirectory(prefix="b2b-canario-") as temporal:
            raiz = Path(temporal)
            binarios = raiz / "bin"
            binarios.mkdir()
            scratch = raiz / "tmp"
            scratch.mkdir()
            registro = raiz / "comandos.jsonl"
            intentos = raiz / "mailbox.jsonl"
            scripts = raiz / "scripts"
            scripts.mkdir()
            # El wrapper importa el cliente versionado; solo se intercepta red.
            cliente = scripts / "agent_b2b_mailbox.py"
            cliente.write_text(textwrap.dedent('''\
                import importlib.util
                import io
                import json
                import os
                from pathlib import Path
                import sys
                from unittest.mock import patch
                from urllib.error import HTTPError

                spec = importlib.util.spec_from_file_location("mailbox_canario", os.environ["CANARIO_CLIENTE"])
                mod = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(mod)

                def caida(request, timeout):
                    with open(os.environ["CANARIO_INTENTOS"], "a", encoding="utf-8") as out:
                        out.write(json.dumps({"url": request.full_url, "payload": json.loads(request.data)}) + "\\n")
                    if os.environ["CANARIO_FALLO"] == "timeout":
                        raise TimeoutError("canario aislado")
                    raise HTTPError(request.full_url, 503, "Unavailable", {}, io.BytesIO(b'{"error":"unavailable"}'))

                with patch.object(mod, "request_oidc_token", return_value="canario.oidc.ficticio"), patch.object(mod, "urlopen", caida):
                    sys.exit(mod.main())
                '''), encoding="utf-8")

            doble = textwrap.dedent('''\
                import json
                import os
                from pathlib import Path
                import sys

                nombre = Path(sys.argv[0]).name
                args = sys.argv[1:]
                with open(os.environ["CANARIO_REGISTRO"], "a", encoding="utf-8") as out:
                    out.write(json.dumps({"command": nombre, "args": args}) + "\\n")
                if nombre == "gh":
                    if args[:2] == ["issue", "view"]:
                        print("Canario mailbox aislado")
                    elif args[:2] == ["pr", "create"]:
                        print("https://github.com/example/canario/pull/7")
                    elif args[:2] == ["pr", "view"]:
                        print("7")
                ''')
            for nombre in ("git", "gh"):
                ruta = binarios / nombre
                ruta.write_text(f"#!{sys.executable}\n" + doble, encoding="utf-8")
                ruta.chmod(0o755)
            python = binarios / "python3"
            python.symlink_to(sys.executable)

            env = {
                "PATH": str(binarios) + os.pathsep + os.defpath,
                "CANARIO_CLIENTE": str(ROOT / "scripts/agent_b2b_mailbox.py"),
                "CANARIO_REGISTRO": str(registro),
                "CANARIO_INTENTOS": str(intentos),
                "CANARIO_FALLO": fallo,
                "SIGA98_FEEDBACK_FALLBACK_URL": "https://example.invalid/api/report",
                "TASK_ID": "example/canario#1870@abc123",
                "GITHUB_RUN_ID": "7",
                "GITHUB_REPOSITORY": "example/canario",
                "GITHUB_OUTPUT": str(raiz / "outputs"),
                "ISSUE": "1870",
                "PROVIDER": "qwen",
                "WORKER": "qwen-primary",
                "BRANCH": "feature/1870-canario",
                "RESULT_VALID": "true",
                "RESULT_STATUS": "done",
                "HANDOFF_LOSS": "0",
                "REVIEW_STATUS": "ok",
                "REVIEW_VERDICT": verdict,
            }
            entrada = "# Reviewer input\n\nPlan reservado y diff staged autoritativo.\n"
            (raiz / ".agent-review-input.md").write_text(entrada, encoding="utf-8")
            hallazgos = ["Corregir el contrato antes de integrar."] if verdict == "findings" else []
            (scratch / "agent-review.json").write_text(json.dumps({
                "status": "ok", "verdict": verdict, "findings": hallazgos,
            }), encoding="utf-8")
            (scratch / "agent-result.json").write_text(json.dumps({
                "result": {"summary": "Corte aislado", "evidence": [], "next_action": ""},
            }), encoding="utf-8")
            (scratch / "agent-result-changed.txt").write_text("scripts/canario.py\n", encoding="utf-8")

            def ejecutar(marcador, opcional=False):
                bloque, shell = paso(marcador)
                # Aísla únicamente las rutas temporales; el shell no se reescribe.
                shell = shell.replace("/tmp/", str(scratch) + "/")
                resultado = subprocess.run(
                    ["bash", "-c", shell], cwd=raiz, env=env,
                    capture_output=True, text=True, timeout=15,
                )
                if opcional:
                    # Actions tolera estos fallos solo mientras exista esta política.
                    self.assertRegex(bloque, r"(?m)^        continue-on-error: true$")
                    self.assertEqual(2, resultado.returncode, resultado.stderr)
                    self.assertIn("agent_b2b_mailbox:", resultado.stderr)
                    self.assertNotIn("canario.oidc.ficticio", resultado.stderr)
                    self.assertNotIn("Traceback", resultado.stderr)
                else:
                    self.assertEqual(0, resultado.returncode, resultado.stderr)
                return resultado

            ejecutar("- id: b2b_inbox\n", opcional=True)
            self.assertFalse((raiz / ".agent-b2b-inbox.md").exists())
            ejecutar("- id: b2b_review_handoff\n", opcional=True)
            self.assertEqual(entrada, (raiz / ".agent-review-input.md").read_text(encoding="utf-8"))
            ejecutar("- id: b2b_review_publish\n", opcional=True)
            ejecutar("- name: Publicar PR draft y lanzar CI canonica\n")

            solicitudes = [json.loads(linea) for linea in intentos.read_text().splitlines()]
            self.assertEqual(3, len(solicitudes))
            self.assertTrue(solicitudes[0]["url"].endswith("/b2b/inbox"))
            self.assertEqual("worker", solicitudes[0]["payload"]["recipient"])
            for solicitud, tipo, destino in zip(
                solicitudes[1:], ("EVIDENCE", "RESULT"), ("reviewer", "dispatcher")
            ):
                self.assertEqual(tipo, solicitud["payload"]["message_type"])
                self.assertEqual(destino, solicitud["payload"]["recipient"])
                self.assertEqual(env["TASK_ID"], solicitud["payload"]["task_id"])

            comandos = [json.loads(linea) for linea in registro.read_text().splitlines()]
            creacion = next(
                c for c in comandos
                if c["command"] == "gh" and c["args"][:2] == ["pr", "create"]
            )
            cuerpo = creacion["args"][creacion["args"].index("--body") + 1]
            self.assertIn("--draft", creacion["args"])
            self.assertIn("Closes #1870", cuerpo)
            self.assertIn(f"ok/{verdict}", cuerpo)
            self.assertIn("ResultPacket true/done", cuerpo)
            self.assertIn("handoff-loss proxy 0%", cuerpo)
            self.assertIn("sin auto-merge", cuerpo)
            self.assertTrue(any(
                c["command"] == "gh" and c["args"][:2] == ["issue", "comment"]
                and "https://github.com/example/canario/pull/7" in c["args"][-1]
                for c in comandos
            ))
            self.assertTrue(any(
                c["command"] == "gh"
                and c["args"][:3] == ["workflow", "run", "ci.yml"]
                for c in comandos
            ))
            self.assertFalse(any(
                c["command"] == "gh" and c["args"][:2] == ["pr", "merge"]
                for c in comandos
            ))
            comentarios = [
                c["args"][-1] for c in comandos
                if c["command"] == "gh" and c["args"][:2] == ["pr", "comment"]
            ]
            if hallazgos:
                self.assertTrue(any(hallazgos[0] in comentario for comentario in comentarios))
            else:
                self.assertEqual([], comentarios)

    def test_503_conserva_revision_y_publica_handoff_draft(self):
        self.ejecutar_canario("503", "approve")

    def test_timeout_conserva_hallazgos_en_fallback_github(self):
        self.ejecutar_canario("timeout", "findings")


if __name__ == "__main__":
    unittest.main()
