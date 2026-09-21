import hashlib
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ESTILO = ROOT / "godot" / "guion" / "estilo_siga.gd"
ACUSACION = ROOT / "godot" / "guion" / "acusacion_app.gd"
RECONSTRUCCION = ROOT / "godot" / "guion" / "reconstruccion_expediente_app.gd"
VENTANILLA = ROOT / "godot" / "guion" / "ventanilla_app.gd"
PROJECT = ROOT / "godot" / "project.godot"
PROVENANCE = ROOT / "godot" / "assets" / "procedencia.json"
GODOT_TEXT_EXTENSIONS = {".gd", ".godot", ".tres", ".tscn"}
FUENTES_SISTEMA_PROHIBIDAS = ("SystemFont", "MS Sans Serif", "Tahoma", "Verdana")


class TipografiaUi780Test(unittest.TestCase):
    def setUp(self):
        self.estilo = ESTILO.read_text(encoding="utf-8")
        self.acusacion = ACUSACION.read_text(encoding="utf-8")
        self.reconstruccion = RECONSTRUCCION.read_text(encoding="utf-8")
        self.ventanilla = VENTANILLA.read_text(encoding="utf-8")
        self.project = PROJECT.read_text(encoding="utf-8")

    def test_codigo_godot_no_reintroduce_fuentes_del_sistema(self):
        incidencias = []
        for ruta in sorted((ROOT / "godot").rglob("*")):
            if not ruta.is_file() or ruta.suffix not in GODOT_TEXT_EXTENSIONS:
                continue
            texto = ruta.read_text(encoding="utf-8")
            for marcador in FUENTES_SISTEMA_PROHIBIDAS:
                if marcador in texto:
                    incidencias.append(f"{ruta.relative_to(ROOT)}: {marcador}")

        self.assertEqual(
            [],
            incidencias,
            "La UI de Godot debe usar fuentes empaquetadas; se reintrodujo una fuente del sistema.",
        )

    def test_interfaz_usa_una_fuente_empaquetada_y_no_el_respaldo_del_motor(self):
        self.assertIn(
            'const RUTA_FUENTE_INTERFAZ := "res://assets/fonts/AtkinsonHyperlegible-Regular.ttf"',
            self.estilo,
        )
        self.assertIn("tema.default_font = fuente_interfaz()", self.estilo)

    def test_interfaz_no_fuerza_texto_sin_antialiasing(self):
        self.assertNotIn("FONT_ANTIALIASING_NONE", self.estilo)
        self.assertNotIn("SUBPIXEL_POSITIONING_DISABLED", self.estilo)
        self.assertNotIn("_sin_suavizar", self.estilo)

    def test_hay_roles_tipograficos_independientes(self):
        self.assertIn("static func fuente_documento()", self.estilo)
        self.assertIn("static func fuente_titulo()", self.estilo)
        self.assertIn("static func fuente_mono()", self.estilo)
        self.assertIn(
            'const RUTA_FUENTE_DOCUMENTO := "res://assets/fonts/MFBOldstyle-Regular.otf"',
            self.estilo,
        )
        self.assertIn(
            'const RUTA_FUENTE_TITULO := "res://assets/fonts/AtkinsonHyperlegible-Bold.ttf"',
            self.estilo,
        )
        self.assertIn("return load(RUTA_FUENTE_DOCUMENTO) as Font", self.estilo)
        self.assertIn("return load(RUTA_FUENTE_TITULO) as Font", self.estilo)
        self.assertNotIn(
            'preload("res://assets/fonts/MFBOldstyle-Regular.otf")', self.estilo
        )
        self.assertIn('tema.set_font("title_font", "Label", titulo)', self.estilo)
        self.assertIn(
            'tema.set_font("document_font", "RichTextLabel", documento)', self.estilo
        )
        self.assertIn('tema.set_font("mono_font", "RichTextLabel", mono)', self.estilo)

    def test_titulo_se_propaga_a_ventanas_nativas_os98(self):
        self.assertIn('tema.set_font("title_font", "Window", titulo)', self.estilo)

    def test_a7_aplica_el_rol_tipografico_de_titulo(self):
        self.assertIn(
            'etiqueta.add_theme_font_override("font", theme.get_font("title_font", "Label"))',
            self.acusacion,
        )

    def test_reconstruccion_aplica_el_rol_tipografico_de_titulo(self):
        self.assertIn(
            'etiqueta.add_theme_font_override("font", theme.get_font("title_font", "Label"))',
            self.reconstruccion,
        )

    def test_ventanilla_aplica_el_rol_tipografico_de_titulo(self):
        self.assertIn(
            'etiqueta.add_theme_font_override("font", theme.get_font("title_font", "Label"))',
            self.ventanilla,
        )

    def test_documento_no_es_la_fuente_global_del_proyecto(self):
        self.assertNotIn("theme/custom_font=", self.project)

    def test_las_fuentes_empaquetadas_tienen_procedencia_libre_registrada(self):
        registro = {
            item["ruta"]: item
            for item in json.loads(PROVENANCE.read_text(encoding="utf-8"))["assets"]
        }
        for ruta in (
            "fonts/AtkinsonHyperlegible-Regular.ttf",
            "fonts/AtkinsonHyperlegible-Bold.ttf",
            "fonts/IBMPlexMono-Regular.ttf",
        ):
            with self.subTest(ruta=ruta):
                ficha = registro[ruta]
                self.assertEqual(ficha["licencia"], "OFL-1.1")
                fichero = ROOT / "godot" / "assets" / ruta
                actual = hashlib.sha256(fichero.read_bytes()).hexdigest()
                self.assertEqual(ficha["sha256"], actual)


if __name__ == "__main__":
    unittest.main()
