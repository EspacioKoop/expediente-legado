from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = sorted((ROOT / ".github" / "workflows").glob("*.yml"))


class WorkflowRuntimeBoundsTest(unittest.TestCase):
    def test_todos_los_workflows_tienen_limite(self):
        self.assertTrue(WORKFLOWS)
        for ruta in WORKFLOWS:
            with self.subTest(workflow=ruta.name):
                self.assertIn(
                    "timeout-minutes:",
                    ruta.read_text(encoding="utf-8"),
                    f"{ruta.name} necesita un límite explícito de ejecución",
                )

    def test_backend_legacy_fija_actions_de_bootstrap(self):
        texto = (ROOT / ".github" / "workflows" / "backend-legacy.yml").read_text(
            encoding="utf-8"
        )
        for accion in ("actions/checkout@", "actions/setup-java@", "actions/setup-node@"):
            linea = next(line for line in texto.splitlines() if accion in line)
            referencia = linea.split("@", 1)[1].split()[0]
            self.assertRegex(referencia, r"^[0-9a-f]{40}$")
        self.assertIn("persist-credentials: false", texto)


if __name__ == "__main__":
    unittest.main()
