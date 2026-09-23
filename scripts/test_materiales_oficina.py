from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
TEXTURAS = ROOT / "godot" / "guion" / "textura_procedural.gd"
MODELOS = ROOT / "godot" / "guion" / "modelos.gd"
CATALOGO = ROOT / "godot" / "guion" / "espacios_catalogo.gd"
SHADER = ROOT / "godot" / "arte" / "psx.gdshader"


class MaterialesOficinaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texturas = TEXTURAS.read_text(encoding="utf-8")
        cls.modelos = MODELOS.read_text(encoding="utf-8")
        cls.catalogo = CATALOGO.read_text(encoding="utf-8")
        cls.shader = SHADER.read_text(encoding="utf-8")

    def test_la_envolvente_de_oficina_ya_declara_materia(self):
        oficina = self.catalogo.split("const OFICINA :=", 1)[1].split("const CALLE :=", 1)[0]
        self.assertIn('"textura_suelo": "linoleo"', oficina)
        self.assertIn('"textura_muro": "gotele"', oficina)
        self.assertIn('"textura_techo": "techo"', oficina)

    def test_biblioteca_procedural_anade_materiales_de_mobiliario(self):
        for funcion in ("melamina", "metal_pintado", "plastico_abs"):
            self.assertIn(f"static func {funcion}(", self.texturas)
            self.assertIn(f'"{funcion}":', self.texturas)

    def test_modelos_de_oficina_tienen_perfiles_semanticos(self):
        esperados = {
            "desk": "melamina",
            "bookcaseClosed": "metal_pintado",
            "computerScreen": "plastico_abs",
            "chairDesk": "plastico_abs",
            "trashcan": "metal_pintado",
        }
        for modelo, material in esperados.items():
            self.assertIn(f'"{modelo}": "{material}"', self.modelos)

    def test_mueble_activa_textura_sobre_el_shader_comun(self):
        self.assertIn("TexturaProcedural.por_nombre(", self.modelos)
        self.assertIn('set_shader_parameter("textura", imagen)', self.modelos)
        self.assertIn('set_shader_parameter("con_textura", true)', self.modelos)
        self.assertRegex(self.modelos, r'set_shader_parameter\(\s*"escala_textura"')
        self.assertIn("material.shader = load(Espacio3D.shader_del_sitio())", self.modelos)
        self.assertIn("muestra_triplanar", self.shader)

    def test_personas_siguen_sin_material_de_mueble(self):
        persona = self.modelos.split("static func persona", 1)[1].split("static func _instanciar", 1)[0]
        self.assertIn("_pintar(pieza, color)", persona)
        self.assertNotIn("MATERIALES_MUEBLE", persona)

    def test_no_anade_assets_externos_para_los_perfiles_nuevos(self):
        for extension in ("melamina.jpg", "metal_pintado.jpg", "plastico_abs.jpg"):
            self.assertNotIn(extension, self.texturas)
        self.assertIn("Image.create(LADO, LADO", self.texturas)


if __name__ == "__main__":
    unittest.main()
