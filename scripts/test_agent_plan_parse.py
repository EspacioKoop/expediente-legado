import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_plan_parse.py"
SPEC = importlib.util.spec_from_file_location("agent_plan_parse", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


PLAN = {"files": ["godot/guion/a.gd", "godot/pruebas/pruebas_a.gd"], "goal": "corte"}

# Salidas reales de los runs 36601702585 y 36620441784 (#1881), recortadas.
SALIDA_933_SIN_MARCADORES = """Ah, this is a plan-only phase without an active Goal. I just need to output the `AGENT_PLAN` block.

**Estado actual de #933:**
- Vertical slice **completa**

```json
{
  "files": [
    "godot/guion/dialogo_religion_933.gd",
    "godot/datos/textos.csv"
  ],
  "goal": "Tercer actor de diálogo religioso"
}
```"""

SALIDA_935_DECORADA_Y_TRUNCADA = """**AGENT_PLAN_BEGIN**
```json
{
  "files": [],
  "goal": "No implementation work required for #935. Technical vertical complete via PR #1359 with distinct SuenoCi
}
```
**AGENT_PLAN_END**"""


def qwen_stdout(*texts):
    events = [{"type": "system", "subtype": "init"}]
    for text in texts:
        events.append(
            {
                "type": "assistant",
                "message": {"content": [{"type": "text", "text": text}]},
            }
        )
    events.append({"type": "result", "result": texts[-1] if texts else ""})
    return json.dumps(events)


class ExtraccionTest(unittest.TestCase):
    def test_formato_canonico(self):
        text = "AGENT_PLAN_BEGIN\n" + json.dumps(PLAN) + "\nAGENT_PLAN_END"
        plan, strategy = mod.extract_plan(text)
        self.assertEqual(PLAN, plan)
        self.assertEqual("marcadores", strategy)

    def test_marcadores_en_negrita_con_fence(self):
        text = (
            "Análisis...\n**AGENT_PLAN_BEGIN**\n```json\n"
            + json.dumps(PLAN, indent=2)
            + "\n```\n**AGENT_PLAN_END**"
        )
        plan, strategy = mod.extract_plan(text)
        self.assertEqual(PLAN["files"], plan["files"])
        self.assertEqual("marcadores", strategy)

    def test_bloque_json_sin_marcadores(self):
        plan, strategy = mod.extract_plan(SALIDA_933_SIN_MARCADORES)
        self.assertEqual(
            ["godot/guion/dialogo_religion_933.gd", "godot/datos/textos.csv"],
            plan["files"],
        )
        self.assertEqual("bloque-json", strategy)

    def test_objeto_suelto_sin_fence(self):
        text = "El plan es " + json.dumps(PLAN) + " y nada más."
        plan, strategy = mod.extract_plan(text)
        self.assertEqual(PLAN, plan)
        self.assertEqual("objeto-json", strategy)

    def test_rescata_files_vacio_con_goal_truncado(self):
        plan, strategy = mod.extract_plan(SALIDA_935_DECORADA_Y_TRUNCADA)
        self.assertEqual([], plan["files"])
        self.assertIn("No implementation work required", plan["goal"])
        self.assertEqual("rescate", strategy)

    def test_no_inventa_rutas_de_una_lista_truncada(self):
        text = 'AGENT_PLAN_BEGIN {"files": ["godot/a.gd", "godot/b'
        self.assertIsNone(mod.extract_plan(text))

    def test_texto_sin_plan(self):
        self.assertIsNone(mod.extract_plan("No he encontrado nada que hacer."))
        self.assertIsNone(mod.extract_plan(""))

    def test_ignora_json_que_no_es_plan(self):
        text = '{"ok": true}\n' + "AGENT_PLAN_BEGIN\n" + json.dumps(PLAN) + "\nAGENT_PLAN_END"
        plan, _ = mod.extract_plan(text)
        self.assertEqual(PLAN, plan)

    def test_marcadores_prevalecen_sobre_ejemplos_previos(self):
        ejemplo = '```json\n{"files": ["ejemplo.gd"], "goal": "ejemplo"}\n```\n'
        text = ejemplo + "AGENT_PLAN_BEGIN\n" + json.dumps(PLAN) + "\nAGENT_PLAN_END"
        plan, _ = mod.extract_plan(text)
        self.assertEqual(PLAN, plan)


class FuentesTest(unittest.TestCase):
    def test_eventos_qwen_prueba_mensajes_anteriores(self):
        raw = qwen_stdout(
            "AGENT_PLAN_BEGIN\n" + json.dumps(PLAN) + "\nAGENT_PLAN_END",
            "Listo, ese es el plan.",
        )
        texts = mod.source_texts(raw)
        self.assertEqual("Listo, ese es el plan.", texts[0])
        self.assertTrue(any(mod.extract_plan(t) for t in texts))

    def test_respuesta_gemini(self):
        raw = json.dumps({"response": "AGENT_PLAN_BEGIN " + json.dumps(PLAN) + " AGENT_PLAN_END"})
        self.assertEqual(PLAN, mod.extract_plan(mod.source_texts(raw)[0])[0])

    def test_plan_delegado(self):
        raw = json.dumps({"found": True, "source": "comment", "plan": PLAN})
        self.assertEqual(PLAN, mod.extract_plan(mod.source_texts(raw)[0])[0])
        self.assertEqual([], mod.source_texts(json.dumps({"found": False})))

    def test_stdout_no_json_se_trata_como_texto(self):
        self.assertEqual(["texto libre"], mod.source_texts("texto libre"))


class ValidacionTest(unittest.TestCase):
    def test_alias_se_canonicalizan_antes_de_deduplicar_y_limitar(self):
        plan = {
            "files": ["./scripts/./a.py", "scripts//a.py", "scripts\\a.py"],
            "goal": "corte",
        }
        self.assertEqual(["scripts/a.py"], mod.normalize(plan, 1)["files"])

    def test_alias_no_eluden_rutas_protegidas(self):
        for ruta in (
            "./AGENTS.md", ".//QWEN.md", "./GEMINI.md",
            "docs/./agents-autonomos.md", ".//.github/workflows/ci.yml",
            "./.agent-plan.json", ".\\.github\\workflows\\ci.yml", "./.github/",
            ".github", ".github/",
        ):
            with self.subTest(ruta=ruta):
                with self.assertRaisesRegex(mod.PlanError, "ruta protegida"):
                    mod.normalize({"files": [ruta], "goal": "x"})

    def test_alias_de_raiz_y_traversal_siguen_invalidos(self):
        for ruta in (".", "./", ".//./", "./scripts/../a.py", "//etc/passwd"):
            with self.subTest(ruta=ruta):
                with self.assertRaisesRegex(mod.PlanError, "ruta invalida"):
                    mod.normalize({"files": [ruta], "goal": "x"})

    def test_normaliza_y_deduplica(self):
        plan = {"files": [" godot\\a.gd ", "godot/a.gd"], "goal": "x" * 500}
        normalized = mod.normalize(plan)
        self.assertEqual(["godot/a.gd"], normalized["files"])
        self.assertEqual(mod.MAX_GOAL, len(normalized["goal"]))

    def test_rechaza_rutas_peligrosas(self):
        for ruta, motivo in (
            ("/etc/passwd", "ruta invalida"),
            ("godot/../x", "ruta invalida"),
            ("godot/*.gd", "ruta invalida"),
            (".github/workflows/ci.yml", "ruta protegida"),
            (".agent-plan.json", "ruta protegida"),
            ("AGENTS.md", "ruta protegida"),
        ):
            with self.subTest(ruta=ruta):
                with self.assertRaisesRegex(mod.PlanError, motivo):
                    mod.normalize({"files": [ruta], "goal": "x"})

    def test_rechaza_demasiadas_rutas(self):
        files = [f"godot/f{i}.gd" for i in range(mod.MAX_FILES + 1)]
        with self.assertRaisesRegex(mod.PlanError, "plan invalido"):
            mod.normalize({"files": files, "goal": "x"})


class CliTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_cli_canonico_conserva_cambio_permitido_en_claim_real(self):
        def git(*args):
            subprocess.run(["git", *args], cwd=self.dir, check=True, capture_output=True)

        git("init", "-q")
        git("config", "user.email", "test@example.invalid")
        git("config", "user.name", "Test")
        (self.dir / "scripts").mkdir()
        permitido = self.dir / "scripts/a.py"
        ajeno = self.dir / "scripts/b.py"
        permitido.write_text("base\n", encoding="utf-8")
        ajeno.write_text("base\n", encoding="utf-8")
        git("add", ".")
        git("commit", "-qm", "base")

        fuente = self.dir / ".agent-source.json"
        fuente.write_text(json.dumps({"found": True, "plan": {
            "files": ["./scripts/./a.py"], "goal": "corte"
        }}), encoding="utf-8")
        plan = self.dir / ".agent-plan.json"
        parser = subprocess.run([
            sys.executable, str(MODULE_PATH), "--source", str(fuente), "--output", str(plan)
        ], capture_output=True, text=True)
        self.assertEqual(parser.returncode, mod.EXIT_OK, parser.stderr)
        self.assertEqual(json.loads(plan.read_text())["files"], ["scripts/a.py"])

        permitido.write_text("cambio válido\n", encoding="utf-8")
        ajeno.write_text("desvío\n", encoding="utf-8")
        reporte = self.dir / ".agent-guard.json"
        guard = subprocess.run([
            sys.executable, str(ROOT / "scripts/agent_claim_guard.py"),
            "--root", str(self.dir), "--plan", str(plan), "--report", str(reporte), "--restore"
        ], capture_output=True, text=True)
        self.assertEqual(guard.returncode, 0, guard.stderr)
        resultado = json.loads(reporte.read_text())
        self.assertEqual(resultado["changed_allowed"], ["scripts/a.py"])
        self.assertEqual(resultado["outside"], ["scripts/b.py"])
        self.assertEqual(permitido.read_text(), "cambio válido\n")
        self.assertEqual(ajeno.read_text(), "base\n")

    def test_cli_rechaza_alias_protegido_sin_publicar_plan(self):
        fuente = self.dir / "source.json"
        fuente.write_text(json.dumps({"files": ["./AGENTS.md"], "goal": "x"}))
        plan = self.dir / "plan.json"
        resultado = subprocess.run([
            sys.executable, str(MODULE_PATH), "--source", str(fuente), "--output", str(plan)
        ], capture_output=True, text=True)
        self.assertEqual(resultado.returncode, mod.EXIT_INVALID, resultado.stderr)
        self.assertFalse(plan.exists())

    def test_primera_fuente_con_plan_gana_y_salta_las_ausentes(self):
        delegado = self.dir / "delegado.json"
        delegado.write_text(json.dumps({"found": False}), encoding="utf-8")
        stdout = self.dir / "stdout.log"
        stdout.write_text(qwen_stdout(SALIDA_933_SIN_MARCADORES), encoding="utf-8")
        output = self.dir / ".agent-plan.json"
        code = mod.main(
            [
                "--source", str(self.dir / "no-existe.json"),
                "--source", str(delegado),
                "--source", str(stdout),
                "--output", str(output),
                "--max-files", "2",
            ]
        )
        self.assertEqual(mod.EXIT_OK, code)
        written = json.loads(output.read_text(encoding="utf-8"))
        self.assertEqual(2, len(written["files"]))
        self.assertEqual({"files", "goal"}, set(written))

    def test_por_defecto_una_tarea_es_un_fichero(self):
        # #1901: dos ficheros ya no son una tarea del pool; no se escribe plan.
        stdout = self.dir / "stdout.log"
        stdout.write_text(qwen_stdout(SALIDA_933_SIN_MARCADORES), encoding="utf-8")
        output = self.dir / ".agent-plan.json"
        code = mod.main(["--source", str(stdout), "--output", str(output)])
        self.assertEqual(mod.EXIT_TOO_BIG, code)
        self.assertFalse(output.exists())

    def test_plan_de_un_fichero_pasa_con_el_limite_por_defecto(self):
        stdout = self.dir / "stdout.log"
        uno = {"files": ["scripts/a.py"], "goal": "corte"}
        stdout.write_text(
            "AGENT_PLAN_BEGIN " + json.dumps(uno) + " AGENT_PLAN_END", encoding="utf-8"
        )
        output = self.dir / ".agent-plan.json"
        code = mod.main(["--source", str(stdout), "--output", str(output)])
        self.assertEqual(mod.EXIT_OK, code)
        self.assertEqual(["scripts/a.py"], json.loads(output.read_text())["files"])

    def test_max_files_se_acota_al_maximo_duro(self):
        files = [f"godot/f{i}.gd" for i in range(mod.MAX_FILES + 1)]
        stdout = self.dir / "stdout.log"
        stdout.write_text(
            "AGENT_PLAN_BEGIN " + json.dumps({"files": files, "goal": "x"}) + " AGENT_PLAN_END",
            encoding="utf-8",
        )
        output = self.dir / ".agent-plan.json"
        code = mod.main(
            ["--source", str(stdout), "--output", str(output), "--max-files", "99"]
        )
        self.assertNotEqual(mod.EXIT_OK, code)

    def test_plan_vacio_conserva_el_formato_que_busca_el_workflow(self):
        stdout = self.dir / "stdout.log"
        stdout.write_text(SALIDA_935_DECORADA_Y_TRUNCADA, encoding="utf-8")
        output = self.dir / ".agent-plan.json"
        self.assertEqual(
            mod.EXIT_OK, mod.main(["--source", str(stdout), "--output", str(output)])
        )
        # El worker detecta «sin corte seguro» con grep '"files": \[\]'.
        self.assertIn('"files": []', output.read_text(encoding="utf-8"))

    def test_sin_plan_sale_con_codigo_propio_y_sin_escribir(self):
        stdout = self.dir / "stdout.log"
        stdout.write_text("nada", encoding="utf-8")
        output = self.dir / ".agent-plan.json"
        code = mod.main(["--source", str(stdout), "--output", str(output)])
        self.assertEqual(mod.EXIT_UNPARSEABLE, code)
        self.assertFalse(output.exists())

    def test_ruta_protegida_sale_con_codigo_de_invalido(self):
        stdout = self.dir / "stdout.log"
        stdout.write_text(
            "AGENT_PLAN_BEGIN " + json.dumps({"files": ["AGENTS.md"], "goal": "x"}) + " AGENT_PLAN_END",
            encoding="utf-8",
        )
        output = self.dir / ".agent-plan.json"
        code = mod.main(["--source", str(stdout), "--output", str(output)])
        self.assertEqual(mod.EXIT_INVALID, code)
        self.assertFalse(output.exists())

    def test_salida_enorme_no_es_problema(self):
        # Run 36620441784: >128 KB por env rompía el paso antes de empezar.
        stdout = self.dir / "stdout.log"
        relleno = "razonamiento " * 40000
        stdout.write_text(
            qwen_stdout(relleno + "AGENT_PLAN_BEGIN " + json.dumps(PLAN) + " AGENT_PLAN_END"),
            encoding="utf-8",
        )
        output = self.dir / ".agent-plan.json"
        self.assertEqual(
            mod.EXIT_OK,
            mod.main(["--source", str(stdout), "--output", str(output), "--max-files", "2"]),
        )


if __name__ == "__main__":
    unittest.main()
