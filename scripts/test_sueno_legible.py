from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
SUENO = ROOT / "godot" / "guion" / "sueno.gd"


class SuenoLegibleTest(unittest.TestCase):
    def setUp(self):
        self.sueno = SUENO.read_text(encoding="utf-8")

    def test_la_salida_sigue_sin_marca_visible(self):
        self.assertIn('"visible": false', self.sueno)
        self.assertNotIn('"visible": true', self.sueno)

    def test_la_pista_ambiental_nace_de_la_misma_posicion_de_salida(self):
        self.assertIn("var posicion_salida := Planta.centro_en_metros(bloques, salida)", self.sueno)
        self.assertIn('"pos": posicion_salida', self.sueno)
        self.assertIn('"pos": posicion_salida + Vector3(0, 0.8, 0)', self.sueno)

    def test_la_pista_es_local_y_no_un_waypoint(self):
        self.assertIn("ALCANCE_PISTA_SALIDA := 4.2", self.sueno)
        self.assertIn('"alcance": ALCANCE_PISTA_SALIDA', self.sueno)
        self.assertIn('"carcasa": false', self.sueno)
        self.assertNotIn("SALIDA_DESPERTAR_VISIBLE", self.sueno)

    def test_conserva_las_luces_propias_de_cada_forma(self):
        self.assertIn('var luces: Array = forma.get("luces", []).duplicate(true)', self.sueno)
        self.assertRegex(self.sueno, re.compile(r"luces\s*\.\s*append\s*\("))
        self.assertIn('"luces": luces', self.sueno)


if __name__ == "__main__":
    unittest.main()
