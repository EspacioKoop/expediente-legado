from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
MODELOS = RAIZ / "godot" / "guion" / "modelos.gd"


class RostroMelvilleTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = MODELOS.read_text(encoding="utf-8")
        cls.melville = cls.texto.split("static func _rasgos_melville", 1)[1].split(
            "static func _aro_gafa", 1
        )[0]

    def test_aduanero_ny_resuelve_a_herman_melville(self):
        self.assertIn('"aduanero_ny": "Herman Melville"', self.texto)
        self.assertIn('if personaje == "Herman Melville":', self.texto)
        self.assertIn("_rasgos_melville(", self.texto)

    def test_barba_y_bigote_son_geometria_3d_integrada(self):
        self.assertIn("barba_y", self.melville)
        self.assertIn("menton_y", self.melville)
        self.assertIn("bigote_y", self.melville)
        self.assertGreaterEqual(self.melville.count("_frente_cabeza("), 5)
        self.assertNotIn("QuadMesh", self.melville)
        self.assertNotIn("albedo_texture", self.melville)

    def test_melville_tiene_pelo_peinado_hacia_atras(self):
        self.assertIn("sien_y", self.melville)
        self.assertIn("cabello", self.melville)
        self.assertIn("BoneAttachment3D.new()", self.texto)


if __name__ == "__main__":
    unittest.main()
