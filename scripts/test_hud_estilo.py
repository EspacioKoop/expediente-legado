from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "hud_estilo.gd"


class HUDEstiloTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_roles_tutorial_y_dialogo_no_comparten_superficie(self):
        self.assertIn('const FONDO_TUTORIAL := Color("e8edf7")', self.source)
        self.assertIn('const FONDO_DIALOGO := Color("10151f")', self.source)
        self.assertIn("static func caja_tutorial()", self.source)
        self.assertIn("static func caja_dialogo()", self.source)
        self.assertIn("EstiloSiga.caja_saliente(FONDO_TUTORIAL)", self.source)

    def test_dialogo_tiene_contraste_y_silueta_propios(self):
        self.assertIn('const TEXTO_DIALOGO := Color("f4f4f0")', self.source)
        self.assertIn('const HABLANTE_DIALOGO := Color("b8d4ff")', self.source)
        self.assertIn("caja.border_color = BORDE_DIALOGO", self.source)
        self.assertIn("caja.shadow_size = 3", self.source)
        self.assertIn("caja.content_margin_left = 12.0", self.source)


if __name__ == "__main__":
    unittest.main()
