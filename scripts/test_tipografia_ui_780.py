from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ESTILO = ROOT / "godot" / "guion" / "estilo_siga.gd"
PROJECT = ROOT / "godot" / "project.godot"


class TipografiaUi780Test(unittest.TestCase):
    def setUp(self):
        self.estilo = ESTILO.read_text(encoding="utf-8")
        self.project = PROJECT.read_text(encoding="utf-8")

    def test_interfaz_no_depende_de_fuentes_windows_instaladas(self):
        self.assertNotIn("MS Sans Serif", self.estilo)
        self.assertNotIn("Tahoma", self.estilo)
        self.assertNotIn("Verdana", self.estilo)
        self.assertNotIn("tema.default_font =", self.estilo)

    def test_interfaz_no_fuerza_texto_sin_antialiasing(self):
        self.assertNotIn("FONT_ANTIALIASING_NONE", self.estilo)
        self.assertNotIn("SUBPIXEL_POSITIONING_DISABLED", self.estilo)
        self.assertNotIn("_sin_suavizar", self.estilo)

    def test_hay_roles_tipograficos_independientes(self):
        self.assertIn("static func fuente_documento()", self.estilo)
        self.assertIn("static func fuente_mono()", self.estilo)
        self.assertIn(
            'preload("res://assets/fonts/MFBOldstyle-Regular.otf")', self.estilo
        )
        self.assertIn(
            'tema.set_font("document_font", "RichTextLabel", documento)', self.estilo
        )
        self.assertIn('tema.set_font("mono_font", "RichTextLabel", mono)', self.estilo)

    def test_documento_no_es_la_fuente_global_del_proyecto(self):
        self.assertNotIn("theme/custom_font=", self.project)


if __name__ == "__main__":
    unittest.main()
