from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
MODELOS = RAIZ / "godot" / "guion" / "modelos.gd"


class RostroCavafisTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = MODELOS.read_text(encoding="utf-8")
        cls.cavafis = cls.texto.split("static func _rasgos_cavafis", 1)[1].split(
            "static func _aro_gafa", 1
        )[0]

    def test_riegos_resuelve_a_constantino_cavafis(self):
        self.assertIn('"riegos": "Constantino Cavafis"', self.texto)
        self.assertIn('personaje == "Constantino Cavafis"', self.texto)
        self.assertIn("_rasgos_cavafis(", self.texto)

    def test_gafas_y_bigote_son_geometria_3d_integrada(self):
        self.assertIn("_aro_gafa(", self.cavafis)
        self.assertIn("bigote_y", self.cavafis)
        self.assertGreaterEqual(self.cavafis.count("_frente_cabeza("), 5)
        self.assertNotIn("QuadMesh", self.cavafis)
        self.assertNotIn("albedo_texture", self.cavafis)

    def test_frente_despejada_y_pelo_lateral_forman_silueta_propia(self):
        self.assertIn("sien_cabello_y", self.cavafis)
        self.assertIn("pelo_escala = Vector3(radio_x * 0.92, alto * 0.055, radio_z * 0.55)", self.texto)
        self.assertIn("BoneAttachment3D.new()", self.texto)


if __name__ == "__main__":
    unittest.main()
