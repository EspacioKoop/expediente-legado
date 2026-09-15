from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
MODELOS = RAIZ / "godot" / "guion" / "modelos.gd"


class RostroPuyiTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = MODELOS.read_text(encoding="utf-8")
        cls.puyi = cls.texto.split("static func _rasgos_puyi", 1)[1].split(
            "static func _aro_gafa", 1
        )[0]

    def test_emperador_resuelve_a_puyi(self):
        self.assertIn('"emperador": "Puyi"', self.texto)
        self.assertIn('if personaje == "Puyi":', self.texto)
        self.assertIn("_rasgos_puyi(", self.texto)

    def test_gafas_son_geometria_3d_y_no_retrato_plano(self):
        self.assertIn("_aro_gafa(", self.puyi)
        self.assertIn("TorusMesh.new()", self.texto)
        self.assertNotIn("QuadMesh", self.puyi)
        self.assertNotIn("albedo_texture", self.puyi)

    def test_gafas_y_cejas_siguen_la_curvatura_de_la_cabeza(self):
        self.assertGreaterEqual(self.puyi.count("_frente_cabeza("), 4)
        self.assertIn("hundido_gafas", self.puyi)
        self.assertIn("BoneAttachment3D.new()", self.texto)

    def test_puyi_tiene_silueta_de_pelo_especifica(self):
        self.assertIn("mechon_y", self.puyi)
        self.assertIn("mechon_x", self.puyi)
        self.assertIn("cabello", self.puyi)


if __name__ == "__main__":
    unittest.main()
