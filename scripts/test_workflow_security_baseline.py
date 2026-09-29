from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = sorted((ROOT / ".github" / "workflows").glob("*.yml"))


class WorkflowSecurityBaselineTest(unittest.TestCase):
    def test_todos_los_workflows_declaran_permissions(self):
        self.assertTrue(WORKFLOWS)
        for ruta in WORKFLOWS:
            with self.subTest(workflow=ruta.name):
                texto = ruta.read_text(encoding="utf-8")
                self.assertIn(
                    "permissions:",
                    texto,
                    f"{ruta.name} no debe depender de los permisos por defecto del repo",
                )
                self.assertNotRegex(texto, r"(?m)^\s*permissions:\s*write-all\s*$")

    def test_pull_request_target_esta_restringido_a_casos_auditados(self):
        encontrados = {
            ruta.name
            for ruta in WORKFLOWS
            if "pull_request_target:" in ruta.read_text(encoding="utf-8")
        }
        self.assertEqual(
            {"reservas.yml", "cleanup-merged-branches.yml"},
            encontrados,
        )

    def test_secrets_inherit_no_prolifera(self):
        encontrados = set()
        patron = re.compile(r"(?m)^\s*secrets:\s*inherit\s*$")
        for ruta in WORKFLOWS:
            if patron.search(ruta.read_text(encoding="utf-8")):
                encontrados.add(ruta.name)
        self.assertEqual({"agent-pool.yml"}, encontrados)


if __name__ == "__main__":
    unittest.main()
