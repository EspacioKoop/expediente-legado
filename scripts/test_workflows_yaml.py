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


    def test_checkout_privilegiado_no_persiste_credenciales(self):
        """Los workflows con capacidad de escritura/OIDC no dejan el token en git."""
        privilegiados = {
            "agent-autopilot.yml",
            "agent-worker.yml",
            "agent-feeder.yml",
            "agent-ci-repair.yml",
            "agent-decompose.yml",
            "agent-pool.yml",
            "agent-reconciler.yml",
            "agent-provider-smoke.yml",
            "label-areas.yml",
            "reservas.yml",
            "alpha-playtest.yml",
        }

        for nombre in sorted(privilegiados):
            ruta = ROOT / ".github" / "workflows" / nombre
            lineas = ruta.read_text(encoding="utf-8").splitlines()
            encontrados = 0
            for indice, linea in enumerate(lineas):
                match = re.match(r"^(\\s*)(?:-\\s*)?uses:\\s*actions/checkout@", linea)
                if not match:
                    continue

                encontrados += 1
                indentacion = len(match.group(1))
                bloque = [linea]
                for siguiente in lineas[indice + 1 :]:
                    texto = siguiente.strip()
                    indentacion_siguiente = len(siguiente) - len(siguiente.lstrip())
                    if texto.startswith("- ") and indentacion_siguiente <= indentacion:
                        break
                    bloque.append(siguiente)

                with self.subTest(workflow=nombre, checkout=indice + 1):
                    self.assertRegex(
                        "\\n".join(bloque),
                        r"(?m)^\\s*persist-credentials:\\s*false\\s*$",
                        f"{nombre}:{indice + 1} debe usar persist-credentials: false",
                    )

            with self.subTest(workflow=nombre):
                self.assertGreater(encontrados, 0, f"{nombre} debería tener checkout")

    def test_pull_request_target_no_hace_checkout_del_head(self):
        """Un token privilegiado nunca debe ejecutar el head de una PR no confiable."""
        for ruta in WORKFLOWS:
            texto = ruta.read_text(encoding="utf-8")
            if "pull_request_target:" not in texto:
                continue
            with self.subTest(workflow=ruta.name):
                self.assertNotRegex(
                    texto,
                    r"ref:\\s*\\$\\{\\{\\s*github\\.event\\.pull_request\\.head\\.(?:sha|ref)",
                )


if __name__ == "__main__":
    unittest.main()
