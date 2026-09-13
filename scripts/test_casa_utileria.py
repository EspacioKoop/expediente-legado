from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
UTILERIA = ROOT / "godot" / "guion" / "casa_utileria.gd"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"


class CasaUtileriaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.utileria = UTILERIA.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_se_monta_solo_en_casa(self):
        self.assertIn('elif fase == "casa":', self.dia)
        self.assertIn("CasaUtileria.montar(_mundo)", self.dia)

    def test_anade_mesita_y_lampara_reconocibles(self):
        self.assertIn('mesa.name = "MesitaCasa"', self.utileria)
        self.assertIn('lampara.name = "LamparaPieCasa"', self.utileria)
        self.assertIn("BoxMesh.new()", self.utileria)
        self.assertIn("CylinderMesh.new()", self.utileria)

    def test_no_introduce_estado_ni_assets_externos(self):
        for termino in (
            "Partida",
            "Jornada",
            "pistas_descubiertas",
            "load(",
            "preload(",
            ".glb",
            ".png",
        ):
            self.assertNotIn(termino, self.utileria)

    def test_no_interfiere_con_la_interaccion_existente(self):
        self.assertNotIn("Interactuable3D", self.utileria)
        self.assertNotIn("CollisionShape3D", self.utileria)


if __name__ == "__main__":
    unittest.main()
