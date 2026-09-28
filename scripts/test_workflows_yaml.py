"""Los workflows deben ser YAML válido.

Un workflow que no parsea no avisa en su PR: GitHub lo marca como fallo en
cada push de cualquier rama, `main` incluida. Pasó con agent-decompose.yml
(#1632): el cuerpo de un heredoc en columna 0 cerraba el bloque `run: |`.
"""

from pathlib import Path
import re
import unittest


def _escapado(texto: str, indice: int) -> bool:
    barras = 0
    indice -= 1
    while indice >= 0 and texto[indice] == "\\":
        barras += 1
        indice -= 1
    return barras % 2 == 1


def backtick_peligroso(linea: str) -> bool:
    """Detecta sustitución con $ dentro de backticks contenidos en comillas dobles."""
    dentro_dobles = False
    indice = 0
    while indice < len(linea):
        caracter = linea[indice]
        if caracter == '"' and not _escapado(linea, indice):
            dentro_dobles = not dentro_dobles
        elif caracter == "`" and not _escapado(linea, indice):
            cierre = indice + 1
            while cierre < len(linea):
                if linea[cierre] == "`" and not _escapado(linea, cierre):
                    break
                cierre += 1
            if cierre >= len(linea):
                return False
            if dentro_dobles and "$" in linea[indice + 1 : cierre]:
                return True
            indice = cierre
        indice += 1
    return False


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

    def test_sin_backticks_ejecutables_en_comillas_dobles(self):
        """Ninguna línea de los workflows debe contener un backtick peligroso."""
        for ruta in WORKFLOWS:
            for numero, linea in enumerate(ruta.read_text(encoding="utf-8").splitlines(), 1):
                with self.subTest(workflow=ruta.name, linea=numero):
                    self.assertFalse(
                        backtick_peligroso(linea),
                        f"Backtick peligroso en {ruta.name}:{numero}: {linea!r}",
                    )

    def test_backtick_peligroso_casos(self):
        """Casos específicos para la detección de backticks peligrosos."""
        # Casos que deben devolver True
        self.assertTrue(backtick_peligroso('--body "reparado (`$reason`). fin"'))
        self.assertTrue(backtick_peligroso('echo "en `$WORKER`; x"'))
        # Casos que deben devolver False
        self.assertFalse(backtick_peligroso('--body "worker \\`$WORKER\` ok"'))
        self.assertFalse(backtick_peligroso('core.notice(`Deleted: ${ref}`;)'))
        self.assertFalse(backtick_peligroso("echo 'literal `$x` sin expandir'"))
        self.assertFalse(backtick_peligroso('echo "sin dolar `abc`"'))


if __name__ == "__main__":
    unittest.main()
