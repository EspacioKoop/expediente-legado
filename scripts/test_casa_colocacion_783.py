from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GILGAMESH = ROOT / "godot" / "guion" / "gilgamesh_vigilia.gd"
LAMPARA = ROOT / "godot" / "guion" / "lampara_interactiva_3d.gd"
SOBREMESA = ROOT / "godot" / "guion" / "consola_sobremesa_98.gd"
TELEVISOR = ROOT / "godot" / "guion" / "television_interactiva_3d.gd"


class CasaColocacion783Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gilgamesh = GILGAMESH.read_text(encoding="utf-8")
        cls.lampara = LAMPARA.read_text(encoding="utf-8")
        cls.sobremesa = SOBREMESA.read_text(encoding="utf-8")
        cls.televisor = TELEVISOR.read_text(encoding="utf-8")

    def test_libro_tiene_escala_domestica_y_descansa_en_la_mesa(self):
        self.assertIn("TAM_LIBRO := Vector3(0.25, 0.04, 0.18)", self.gilgamesh)
        self.assertIn("POS_CASA := Vector3(1.45, 0.763, -0.70)", self.gilgamesh)
        self.assertIn('if name == "GilgameshVigiliaCasa":', self.gilgamesh)
        self.assertIn("position = POS_CASA", self.gilgamesh)
        self.assertIn("forma.size = Vector3(0.29, 0.10, 0.22)", self.gilgamesh)
        self.assertNotIn("Vector3(2.45, 0.12, 1.72)", self.gilgamesh)
        self.assertNotIn("Vector3(2.4, 0.38, 1.7)", self.gilgamesh)

    def test_lampara_apagada_no_tiene_energia_luminosa(self):
        self.assertIn("ENERGIA_ENCENDIDA := 1.1", self.lampara)
        self.assertIn("_luz.light_energy = 0.0", self.lampara)
        self.assertIn(
            "_luz.light_energy = ENERGIA_ENCENDIDA if _encendida else 0.0",
            self.lampara,
        )
        self.assertIn("_luz.visible = _encendida", self.lampara)

    def test_cartuchos_quedan_apoyados_en_el_mueble(self):
        self.assertEqual(self.sobremesa.count("Vector3(0.34, -0.006, -0.10)"), 1)
        self.assertEqual(self.sobremesa.count("Vector3(0.37, -0.006, 0.00)"), 1)
        self.assertEqual(self.sobremesa.count("Vector3(0.33, -0.006, 0.10)"), 1)

    def test_rincon_de_tv_reagrupa_los_objetos_en_superficies(self):
        self.assertIn("mando.position = position + OFFSET_MANDO_MESA", self.televisor)
        self.assertIn("portatil.position = position + OFFSET_PORTATIL_MESA", self.televisor)
        self.assertIn("pieza.rotation_degrees.y = 90.0", self.televisor)


if __name__ == "__main__":
    unittest.main()
