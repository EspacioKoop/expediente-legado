"""Los workflows deben ser YAML válido.

Un workflow que no parsea no avisa en su PR: GitHub lo marca como fallo en
cada push de cualquier rama, `main` incluida. Pasó con agent-decompose.yml
(#1632): el cuerpo de un heredoc en columna 0 cerraba el bloque `run: |`.
"""

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = sorted((ROOT / ".github" / "workflows").glob("*.yml"))
# En columna 0 solo caben claves de primer nivel, comentarios o `---`.
COLUMNA_CERO_VALIDA = re.compile(r"^(?:[A-Za-z_][\w-]*:|#|---\s*$)")


class WorkflowsYamlTest(unittest.TestCase):
    def test_hay_workflows(self):
        self.assertTrue(WORKFLOWS)

    def test_sin_texto_suelto_en_columna_cero(self):
        # Sin dependencias: detecta heredocs o texto que se escapa de un bloque.
        for ruta in WORKFLOWS:
            for numero, linea in enumerate(ruta.read_text(encoding="utf-8").splitlines(), 1):
                if linea and not linea[0].isspace():
                    with self.subTest(workflow=ruta.name, linea=numero):
                        self.assertRegex(linea, COLUMNA_CERO_VALIDA)

    def test_parsean_como_yaml(self):
        try:
            import yaml
        except ImportError:
            self.skipTest("PyYAML no disponible; cubre test_sin_texto_suelto_en_columna_cero")
        for ruta in WORKFLOWS:
            with self.subTest(workflow=ruta.name):
                datos = yaml.safe_load(ruta.read_text(encoding="utf-8"))
                self.assertIsInstance(datos, dict)
                self.assertIn("jobs", datos)


    def test_acciones_privilegiadas_clave_fijadas_por_sha(self):
        casos = {
            "cleanup-merged-branches.yml": (
                "actions/github-script",
                "3a2844b7e9c422d3c10d287c895573f7108da1b3",
            ),
            "alpha-playtest.yml": (
                "softprops/action-gh-release",
                "efb35369e0ad2afab669f228072c1b0d510eae64",
            ),
        }
        for nombre, (accion, sha) in casos.items():
            texto = (ROOT / ".github" / "workflows" / nombre).read_text(encoding="utf-8")
            with self.subTest(workflow=nombre, action=accion):
                self.assertIn(f"uses: {accion}@{sha}", texto)
                self.assertNotRegex(texto, rf"uses:\s*{re.escape(accion)}@v\d+")


if __name__ == "__main__":
    unittest.main()
