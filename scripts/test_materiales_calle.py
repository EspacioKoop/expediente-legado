from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
TEXTURAS = RAIZ / "godot" / "guion" / "textura_procedural.gd"
CATALOGO = RAIZ / "godot" / "guion" / "espacios_catalogo.gd"


class MaterialesCalleTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texturas = TEXTURAS.read_text(encoding="utf-8")
        cls.catalogo = CATALOGO.read_text(encoding="utf-8")
        cls.calle = cls.catalogo.split("const CALLE :=", 1)[1].split("const CASA :=", 1)[0]

    def test_asfalto_sigue_siendo_material_del_suelo(self):
        self.assertIn('"textura_suelo": "asfalto"', self.calle)
        self.assertIn("static func asfalto", self.texturas)

    def test_hay_revoco_urbano_reutilizable(self):
        self.assertIn("static func revoco_urbano", self.texturas)
        self.assertIn('"revoco_urbano":', self.texturas)

    def test_los_volumenes_de_fachada_declaran_material(self):
        self.assertEqual(self.calle.count('"textura": "revoco_urbano"'), 3)

    def test_el_corte_no_introduce_geometria_de_acera(self):
        self.assertNotIn('"rol": "acera"', self.calle)
        self.assertNotIn('"textura": "acera"', self.calle)


if __name__ == "__main__":
    unittest.main()
