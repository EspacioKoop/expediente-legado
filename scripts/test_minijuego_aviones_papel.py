from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "godot" / "guion" / "minijuego_aviones_papel.gd"
SCENE = ROOT / "godot" / "escenas" / "minijuego_aviones_papel.tscn"


class MinijuegoAvionesPapelTest(unittest.TestCase):
    def setUp(self):
        self.script = SCRIPT.read_text(encoding="utf-8")
        self.scene = SCENE.read_text(encoding="utf-8")

    def test_escena_consumidora_del_nucleo(self):
        self.assertIn("AvionesPapel.nueva", self.script)
        self.assertIn("AvionesPapel.lanzar(", self.script)
        self.assertIn("AvionesPapel.lanzar_companero", self.script)
        self.assertIn("AvionesPapel.resultado", self.script)
        self.assertNotIn("const GRAVEDAD", self.script)
        self.assertNotIn("const LIMITE_FONDO", self.script)

    def test_superficie_jugable_con_controles_nativos(self):
        self.assertIn('type="OptionButton"', self.scene)
        self.assertEqual(self.scene.count('type="HSlider"'), 3)
        self.assertIn('text = "Lanzar"', self.scene)
        self.assertIn('text = "Abandonar"', self.scene)
        self.assertIn("Teclado/mando", self.scene)
        self.assertIn("modelo.grab_focus()", self.script)

    def test_pasillo_y_tres_modalidades(self):
        self.assertIn("const PISTA := Rect2", self.script)
        self.assertIn("OBJETIVO_PAPELERA", self.script)
        self.assertIn('const MODALIDADES := ["distancia", "precision", "zona"]', self.script)
        self.assertIn('const MODELOS := ["estable", "rapido", "impredecible"]', self.script)

    def test_abandono_no_persiste_recompensas(self):
        self.assertIn("AvionesPapel.abandonar", self.script)
        self.assertIn("el ciclo diario no cambia", self.script)
        self.assertNotIn("Partida", self.script)
        self.assertNotIn("sello", self.script.lower())
        self.assertNotIn("guardar", self.script.lower())


if __name__ == "__main__":
    unittest.main()
