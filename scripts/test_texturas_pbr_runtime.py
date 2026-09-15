import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class TexturasPBRRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.shader_pbr = (ROOT / "godot/arte/psx_pbr.gdshader").read_text(encoding="utf-8")
        cls.shader_psx = (ROOT / "godot/arte/psx.gdshader").read_text(encoding="utf-8")
        cls.loader = (ROOT / "godot/guion/texturas_pbr.gd").read_text(encoding="utf-8")
        cls.calle = (ROOT / "godot/guion/calle_materiales.gd").read_text(encoding="utf-8")

    def test_shader_pbr_conserva_senales_psx(self):
        self.assertIn("rejilla", self.shader_pbr)
        self.assertIn("tonos", self.shader_pbr)
        self.assertIn("dithering", self.shader_pbr)
        self.assertIn("bayer_4x4", self.shader_pbr)

    def test_shader_pbr_expone_mapas_de_material(self):
        for nombre in ("mapa_normal", "mapa_roughness", "mapa_ao"):
            self.assertIn(nombre, self.shader_pbr)
        self.assertIn("NORMAL_MAP", self.shader_pbr)
        self.assertIn("ROUGHNESS", self.shader_pbr)
        self.assertIn("AO =", self.shader_pbr)

    def test_shader_psx_canonico_sigue_siendo_vertex_lighting(self):
        self.assertIn("vertex_lighting", self.shader_psx)
        self.assertIn("specular_disabled", self.shader_psx)

    def test_loader_es_opcional_y_busca_set_canonico(self):
        self.assertIn("res://assets/texturas/pbr/%s/%s", self.loader)
        self.assertIn("return null", self.loader)
        self.assertIn("if albedo == null:", self.loader)
        for tipo in ("albedo", "normal", "roughness", "ao"):
            self.assertIn(f'"{tipo}"', self.loader)

    def test_fachada_activa_pbr_con_fallback_procedural(self):
        self.assertIn('"fachada_edificio"', self.calle)
        self.assertIn("TexturasPBR.crear", self.calle)
        self.assertIn("if material == null:", self.calle)
        self.assertIn('"revoco_urbano"', self.calle)
        self.assertIn("Color.WHITE", self.calle)

    def test_calzada_y_aceras_solo_existen_con_pbr(self):
        self.assertIn('"asfalto_urbano"', self.calle)
        self.assertIn('"acera_barcelona"', self.calle)
        self.assertIn('"CalzadaPBR"', self.calle)
        self.assertIn('"AceraOestePBR"', self.calle)
        self.assertIn('"AceraEstePBR"', self.calle)
        self.assertIn("var superficie := _superficie_suelo(ficha)", self.calle)
        self.assertIn("if superficie != null:", self.calle)
        self.assertIn("if material == null:\n\t\treturn null", self.calle)

    def test_pieles_de_suelo_no_crean_colision(self):
        bloque = self.calle.split("static func _superficie_suelo", 1)[1].split(
            "static func _fachada", 1
        )[0]
        self.assertNotIn("CollisionShape3D", bloque)
        self.assertNotIn("StaticBody3D", bloque)
        self.assertIn("MeshInstance3D", bloque)


if __name__ == "__main__":
    unittest.main()
