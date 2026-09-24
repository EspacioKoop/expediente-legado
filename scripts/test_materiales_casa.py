from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
TEXTURAS = ROOT / "godot" / "guion" / "textura_procedural.gd"
UTILERIA = ROOT / "godot" / "guion" / "casa_utileria.gd"
MODELOS = ROOT / "godot" / "guion" / "modelos.gd"
CATALOGO = ROOT / "godot" / "guion" / "espacios_catalogo.gd"


class MaterialesCasaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texturas = TEXTURAS.read_text(encoding="utf-8")
        cls.utileria = UTILERIA.read_text(encoding="utf-8")
        cls.modelos = MODELOS.read_text(encoding="utf-8")
        cls.catalogo = CATALOGO.read_text(encoding="utf-8")

    def test_biblioteca_anade_tres_perfiles_domesticos(self):
        for perfil in ("madera_domestica", "tejido_domestico", "acero_cocina"):
            self.assertIn(f"static func {perfil}(", self.texturas)
            self.assertIn(f'"{perfil}":', self.texturas)

    def test_perfiles_domesticos_son_procedurales(self):
        inicio = self.texturas.index("static func madera_domestica(")
        final = self.texturas.index("## La textura de una superficie", inicio)
        bloque = self.texturas[inicio:final]
        self.assertIn("Image.create(", bloque)
        self.assertIn("RandomNumberGenerator.new()", bloque)
        self.assertNotIn("ResourceLoader", bloque)
        self.assertNotIn(".png", bloque)
        self.assertNotIn(".jpg", bloque)

    def test_sofa_cocina_y_muebles_de_casa_declaran_materia(self):
        self.assertIn('const MADERA := "madera_domestica"', self.utileria)
        self.assertIn('const TEJIDO := "tejido_domestico"', self.utileria)
        self.assertIn('const ACERO := "acero_cocina"', self.utileria)
        # Los props originales sustituyen parte de las primitivas; las zonas que
        # siguen siendo procedurales conservan sus perfiles de materia.
        self.assertGreaterEqual(self.utileria.count("TEJIDO"), 6)
        self.assertGreaterEqual(self.utileria.count("MADERA"), 13)
        self.assertGreaterEqual(self.utileria.count("ACERO"), 7)

    def test_utileria_reutiliza_el_shader_psx_central(self):
        self.assertIn("Modelos._pintar(malla, color, textura)", self.utileria)
        self.assertIn("material.shader = load(Espacio3D.shader_del_sitio())", self.modelos)
        self.assertIn('set_shader_parameter("textura", imagen)', self.modelos)
        self.assertIn('set_shader_parameter("con_textura", true)', self.modelos)
        self.assertNotIn("StandardMaterial3D.new()", self.utileria)

    def test_casa_conserva_suelo_domestico_y_luz_calida(self):
        casa = self.catalogo.split("const CASA :=", 1)[1].split("const POR_FASE :=", 1)[0]
        self.assertIn('"textura_suelo": "moqueta"', casa)
        self.assertIn('"ambiente": Color(0.30, 0.26, 0.22)', casa)
        self.assertIn('"color": Color(1.0, 0.84, 0.62)', casa)

    def test_corte_no_anade_assets_externos(self):
        self.assertNotIn(".glb", self.utileria)
        self.assertNotIn(".png", self.utileria)
        self.assertNotIn("preload(", self.utileria)
        for linea in self.utileria.splitlines():
            if "load(" in linea:
                self.assertIn("res://arte/props_originales_98/", linea)
                self.assertIn(".obj", linea)


if __name__ == "__main__":
    unittest.main()
