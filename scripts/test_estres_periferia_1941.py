import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
PERIFERIA = ROOT / "godot/guion/estres_periferia.gd"
HUD = ROOT / "godot/guion/hud_layer.gd"


class EstresPeriferia1941Test(unittest.TestCase):
    def test_consumidor_es_estatico_y_no_intercepta_input(self):
        fuente = PERIFERIA.read_text(encoding="utf-8")
        self.assertIn("Control.MOUSE_FILTER_IGNORE", fuente)
        self.assertIn("clampf(nivel, 0.0, 1.0)", fuente)
        self.assertIn("ALPHA_MAX", fuente)
        self.assertNotIn("Timer", fuente)
        self.assertNotIn("Tween", fuente)
        self.assertNotIn("jornada[", fuente)

    def test_hud_sigue_sin_semantica_de_estres(self):
        fuente = HUD.read_text(encoding="utf-8")
        self.assertNotIn("Estres.", fuente)
        self.assertNotIn("EstresPeriferia", fuente)


if __name__ == "__main__":
    unittest.main()
