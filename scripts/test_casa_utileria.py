from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
UTILERIA = ROOT / "godot" / "guion" / "casa_utileria.gd"
LAMPARA = ROOT / "godot" / "guion" / "lampara_interactiva_3d.gd"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"


class CasaUtileriaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.utileria = UTILERIA.read_text(encoding="utf-8")
        cls.lampara = LAMPARA.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_se_monta_solo_en_casa(self):
        self.assertIn('elif fase == "casa":', self.dia)
        self.assertIn("CasaUtileria.montar(_mundo)", self.dia)

    def test_anade_mesita_y_lampara_reconocibles(self):
        self.assertIn('mesa.name = "MesitaCasa"', self.utileria)
        self.assertIn('lampara.name = "LamparaPieCasa"', self.utileria)
        self.assertIn("LamparaInteractiva3D.new()", self.utileria)
        self.assertIn("BoxMesh.new()", self.utileria)
        self.assertIn("CylinderMesh.new()", self.utileria)

    def test_lampara_reutiliza_interaccion_y_luz_real(self):
        self.assertIn("extends Interactuable3D", self.lampara)
        self.assertIn("verbo = Verbo.ENCENDER", self.lampara)
        self.assertIn("OmniLight3D.new()", self.lampara)
        self.assertIn("CollisionShape3D.new()", self.lampara)
        self.assertIn('return "Apagar lámpara"', self.lampara)
        self.assertIn("_luz.visible = _encendida", self.lampara)

    def test_toggle_es_local_y_no_toca_estado_de_juego(self):
        combinado = self.utileria + self.lampara
        for termino in (
            "Partida",
            "Jornada",
            "pistas_descubiertas",
            "inventario",
            "guardar(",
        ):
            self.assertNotIn(termino, combinado)

    def test_no_introduce_assets_externos(self):
        combinado = self.utileria + self.lampara
        for termino in (
            "load(",
            "preload(",
            ".glb",
            ".png",
        ):
            self.assertNotIn(termino, combinado)


if __name__ == "__main__":
    unittest.main()
