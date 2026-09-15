from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
MODELOS = RAIZ / "godot" / "guion" / "modelos.gd"


class RostroPessoaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = MODELOS.read_text(encoding="utf-8")
        cls.pessoa = cls.texto.split("static func _rasgos_pessoa", 1)[1].split(
            "static func _aro_gafa", 1
        )[0]

    def test_correspondencia_resuelve_a_fernando_pessoa(self):
        self.assertIn('"correspondencia": "Fernando Pessoa"', self.texto)
        self.assertIn('if personaje == "Fernando Pessoa":', self.texto)
        self.assertIn("_rasgos_pessoa(", self.texto)

    def test_gafas_y_bigote_son_geometria_3d(self):
        self.assertIn("_aro_gafa(", self.pessoa)
        self.assertIn("bigote_y", self.pessoa)
        self.assertGreaterEqual(self.pessoa.count("_frente_cabeza("), 5)
        self.assertNotIn("QuadMesh", self.pessoa)
        self.assertNotIn("albedo_texture", self.pessoa)

    def test_sombrero_es_volumen_y_no_textura(self):
        self.assertIn("CylinderMesh.new()", self.pessoa)
        self.assertIn("ala", self.pessoa)
        self.assertIn("copa", self.pessoa)
        self.assertIn("BoneAttachment3D.new()", self.texto)


if __name__ == "__main__":
    unittest.main()
