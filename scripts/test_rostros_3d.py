from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
MODELOS = RAIZ / "godot" / "guion" / "modelos.gd"


class Rostros3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = MODELOS.read_text(encoding="utf-8")
        cls.cara = cls.texto.split("static func _poner_cara", 1)[1].split(
            "static func _alto_cabeza", 1
        )[0]

    def test_no_superpone_fotografia_plana(self):
        self.assertNotIn("QuadMesh", self.cara)
        self.assertNotIn("albedo_texture", self.cara)
        self.assertNotIn("load(ruta)", self.cara)

    def test_la_cara_nace_de_un_volumen_completo_de_cabeza(self):
        self.assertIn("_volumen_cabeza(", self.cara)
        self.assertIn("static func _volumen_cabeza", self.texto)
        self.assertIn("Vector3(radio_x, radio_y, radio_z)", self.cara)

    def test_los_rasgos_siguen_la_curvatura_y_quedan_hundidos(self):
        self.assertIn("_frente_cabeza(", self.cara)
        self.assertIn("var hundido :=", self.cara)
        self.assertGreaterEqual(self.cara.count("- hundido"), 2)
        self.assertIn("- alto * 0.015", self.cara)
        self.assertIn("- alto * 0.010", self.cara)
        self.assertNotIn("frente := alto * 0.50", self.cara)

    def test_no_reintroduce_bloques_frontales_como_mascara(self):
        self.assertNotIn("_rasgo_caja(", self.cara)
        self.assertNotIn("BoxMesh.new()", self.texto)
        self.assertIn("SphereMesh.new()", self.texto)
        self.assertIn("BoneAttachment3D.new()", self.cara)

    def test_la_identidad_es_determinista(self):
        self.assertIn("absi(hash(retrato))", self.cara)
        self.assertNotIn("randf()", self.cara)

    def test_perfiles_historicos_explicitos_y_cabello_integrado(self):
        for retrato in ("emperador", "aduanero_ny", "correspondencia", "riegos", "fielato"):
            self.assertIn('"%s"' % retrato, self.texto)
        self.assertIn("PERFILES_FACIALES.get(retrato", self.cara)
        self.assertIn("_cabello_cabeza(", self.cara)
        self.assertIn("perfil.get(", self.cara)
        self.assertIn("\"piel\"", self.cara)
        self.assertIn("perfil.get(\"x\"", self.cara)

    def test_conserva_el_shader_comun(self):
        self.assertIn("material.shader = load(Espacio3D.shader_del_sitio())", self.texto)


if __name__ == "__main__":
    unittest.main()
