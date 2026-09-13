from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "dia_dialogo_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class DialogoIntegracionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.capa = CAPA.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_la_escena_activa_la_capa(self):
        self.assertIn('res://guion/dia_dialogo_app.gd', self.escena)
        self.assertIn('extends "res://guion/dia_clima_app.gd"', self.capa)

    def test_intervencion_real_usa_dialogo_diegetico(self):
        self.assertIn('salida.get_meta("frase", "")', self.capa)
        self.assertIn("DialogoDiegetico.mostrar", self.capa)
        self.assertIn("_hud", self.capa)
        self.assertIn("_mundo", self.capa)
        self.assertIn("_caminante", self.capa)

    def test_guardado_y_pantallas_siguen_en_la_capa_base(self):
        self.assertIn("partida.guardado_pendiente", self.capa)
        self.assertIn("_pantalla != null", self.capa)
        self.assertGreaterEqual(self.capa.count("super._al_pisar_salida"), 3)

    def test_no_duplica_contenido_ni_estado(self):
        for prohibido in (
            "Companeros.frase_de",
            "Jornada.",
            "Partida.guardar",
            "pistas_descubiertas",
            "_nomina.text",
        ):
            self.assertNotIn(prohibido, self.capa)


if __name__ == "__main__":
    unittest.main()
