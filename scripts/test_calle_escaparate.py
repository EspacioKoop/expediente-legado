from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
CALLE = ROOT / "godot" / "guion" / "dia_calle_app.gd"
MODELO_TV = ROOT / "godot" / "assets" / "modelos" / "televisionVintage.glb"


class CalleEscaparateTest(unittest.TestCase):
    def test_la_escena_usa_la_capa_de_calle(self):
        texto = DIA.read_text(encoding="utf-8")
        self.assertIn('path="res://guion/dia_calle_app.gd"', texto)

    def test_la_calle_no_reutiliza_la_envolvente_de_habitacion(self):
        texto = CALLE.read_text(encoding="utf-8")
        self.assertIn('espacio.erase("suelo")', texto)
        self.assertIn('espacio["planta"] = []', texto)
        self.assertIn('espacio.erase("pantallas")', texto)

    def test_las_televisiones_forman_un_unico_escaparate_3d(self):
        texto = CALLE.read_text(encoding="utf-8")
        self.assertEqual(texto.count('"modelo": "televisionVintage"'), 3)
        self.assertIn("Un solo paño de escaparate", texto)
        self.assertTrue(MODELO_TV.exists())

    def test_conserva_el_destino_hacia_casa_en_la_cadena_base(self):
        texto = CALLE.read_text(encoding="utf-8")
        self.assertIn('extends "res://guion/dia_onboarding_app.gd"', texto)
        self.assertNotIn('jornada["fase"]', texto)
        self.assertNotIn("Partida", texto)


if __name__ == "__main__":
    unittest.main()
