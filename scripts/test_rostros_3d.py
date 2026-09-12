from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
MODELOS = RAIZ / "godot" / "guion" / "modelos.gd"


class Rostros3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = MODELOS.read_text(encoding="utf-8")

    def test_no_superpone_fotografia_plana(self):
        bloque = self.texto.split("static func _poner_cara", 1)[1].split(
            "static func _esqueleto", 1
        )[0]
        self.assertNotIn("QuadMesh", bloque)
        self.assertNotIn("albedo_texture", bloque)
        self.assertNotIn("load(ruta)", bloque)

    def test_los_rasgos_tienen_volumen(self):
        self.assertIn("SphereMesh.new()", self.texto)
        self.assertIn("BoxMesh.new()", self.texto)
        self.assertIn("BoneAttachment3D.new()", self.texto)

    def test_la_identidad_es_determinista(self):
        self.assertIn("absi(hash(retrato))", self.texto)
        self.assertNotIn("randf()", self.texto.split("static func _poner_cara", 1)[1])

    def test_conserva_el_shader_comun(self):
        self.assertIn("material.shader = load(Espacio3D.SHADER_PSX)", self.texto)


if __name__ == "__main__":
    unittest.main()
