import importlib.util
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_plan_parse.py"
SPEC = importlib.util.spec_from_file_location("agent_plan_parse", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class TestAgentPlanParseBoundaryJules(unittest.TestCase):
    """Regresión monofichero: validación de límites de rutas y reservas en agent_plan_parse."""

    def test_normalize_rechaza_rutas_absolutas(self):
        rutas_absolutas = [
            "/etc/passwd",
            "/scripts/test.py",
            "//server/share/file.txt",
            "/",
        ]
        for ruta in rutas_absolutas:
            with self.subTest(ruta=ruta):
                with self.assertRaises(mod.PlanError) as ctx:
                    mod.normalize({"files": [ruta], "goal": "test_absoluta"})
                self.assertIn("ruta invalida", str(ctx.exception))

    def test_normalize_rechaza_traversal_puntos(self):
        rutas_traversal = [
            "../file.py",
            "scripts/../file.py",
            "a/b/../../file.py",
            "..",
            "scripts/..",
        ]
        for ruta in rutas_traversal:
            with self.subTest(ruta=ruta):
                with self.assertRaises(mod.PlanError) as ctx:
                    mod.normalize({"files": [ruta], "goal": "test_traversal"})
                self.assertIn("ruta invalida", str(ctx.exception))

    def test_normalize_rechaza_traversal_con_backslashes(self):
        rutas_backslashes = [
            "..\\file.py",
            "scripts\\..\\file.py",
            "a\\b\\..\\..\\file.py",
            "..\\",
            "scripts\\..",
        ]
        for ruta in rutas_backslashes:
            with self.subTest(ruta=ruta):
                with self.assertRaises(mod.PlanError) as ctx:
                    mod.normalize({"files": [ruta], "goal": "test_backslash_traversal"})
                self.assertIn("ruta invalida", str(ctx.exception))

    def test_normalize_rechaza_rutas_protegidas(self):
        rutas_protegidas = [
            "AGENTS.md",
            "./AGENTS.md",
            ".//AGENTS.md",
            ".github/",
            ".github",
            ".github/workflows/ci.yml",
            "./.github/workflows/ci.yml",
            "docs/agents-autonomos.md",
            ".agent-plan.json",
        ]
        for ruta in rutas_protegidas:
            with self.subTest(ruta=ruta):
                with self.assertRaises(mod.PlanError) as ctx:
                    mod.normalize({"files": [ruta], "goal": "test_protegida"})
                self.assertIn("ruta protegida", str(ctx.exception))

    def test_normalize_rechaza_glob(self):
        rutas_glob = [
            "scripts/*.py",
            "godot/test?.gd",
            "src/[a-z].py",
            "a]b.py",
        ]
        for ruta in rutas_glob:
            with self.subTest(ruta=ruta):
                with self.assertRaises(mod.PlanError) as ctx:
                    mod.normalize({"files": [ruta], "goal": "test_glob"})
                self.assertIn("ruta invalida", str(ctx.exception))

    def test_control_max_files_reserva(self):
        tres_ficheros = [
            "scripts/a.py",
            "scripts/b.py",
            "scripts/c.py",
        ]

        # Sin opt-in explícito (por defecto max_files=1)
        with self.assertRaises(mod.PlanTooBig) as ctx:
            mod.normalize({"files": tres_ficheros, "goal": "reserva_multiple"}, max_files=1)
        self.assertIn("maximo 1", str(ctx.exception))

        # Con opt-in explícito de 3
        res = mod.normalize({"files": tres_ficheros, "goal": "reserva_multiple"}, max_files=3)
        self.assertEqual(res["files"], tres_ficheros)

        # Exceder el opt-in explícito de 3 con 4 ficheros
        cuatro_ficheros = tres_ficheros + ["scripts/d.py"]
        with self.assertRaises(mod.PlanTooBig) as ctx:
            mod.normalize({"files": cuatro_ficheros, "goal": "reserva_excesiva"}, max_files=3)
        self.assertIn("maximo 3", str(ctx.exception))

    def test_deduplicacion_y_normalizacion_alias(self):
        alias_ficheros = [
            "./scripts/./a.py",
            "scripts//a.py",
            "scripts\\a.py",
            " scripts/a.py ",
        ]
        res = mod.normalize({"files": alias_ficheros, "goal": "test_alias"}, max_files=1)
        self.assertEqual(res["files"], ["scripts/a.py"])

    def test_goal_truncado_sin_alterar_rutas(self):
        goal_largo = "G" * 300
        rutas = ["scripts/a.py", "scripts/b.py"]
        res = mod.normalize({"files": rutas, "goal": goal_largo}, max_files=2)
        self.assertEqual(res["files"], rutas)
        self.assertEqual(len(res["goal"]), mod.MAX_GOAL)
        self.assertEqual(res["goal"], "G" * mod.MAX_GOAL)


if __name__ == "__main__":
    unittest.main()
