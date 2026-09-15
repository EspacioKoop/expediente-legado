from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
TEXTURAS = RAIZ / "godot" / "guion" / "textura_procedural.gd"
CALLE = RAIZ / "godot" / "guion" / "calle_materiales.gd"
CONTROLADOR = RAIZ / "godot" / "guion" / "dia_retro_urban_app.gd"
CATALOGO = RAIZ / "godot" / "guion" / "espacios_catalogo.gd"


class MaterialesCalleTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texturas = TEXTURAS.read_text(encoding="utf-8")
        cls.calle = CALLE.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        catalogo = CATALOGO.read_text(encoding="utf-8")
        cls.catalogo_calle = catalogo.split("const CALLE :=", 1)[1].split("const CASA :=", 1)[0]

    def test_asfalto_sigue_siendo_material_del_suelo(self):
        self.assertIn('"textura_suelo": "asfalto"', self.catalogo_calle)
        self.assertIn("static func asfalto", self.texturas)

    def test_hay_revoco_urbano_reutilizable(self):
        self.assertIn("static func revoco_urbano", self.texturas)
        self.assertIn('"revoco_urbano":', self.texturas)

    def test_hay_tres_pieles_de_fachada(self):
        self.assertIn("const FACHADAS :=", self.calle)
        self.assertEqual(self.calle.count('"nombre": "FachadaRevoco'), 3)
        self.assertIn('TexturaProcedural.por_nombre("revoco_urbano"', self.calle)

    def test_las_pieles_guardan_margen_con_la_fachada(self):
        self.assertIn("const SEPARACION_FACHADA := 0.02", self.calle)
        self.assertIn("const GROSOR_PIEL_FACHADA := 0.025", self.calle)
        self.assertIn('"cara_x": CalleIdentidad.CARA_OESTE_SUR', self.calle)
        self.assertIn('"cara_x": CalleIdentidad.CARA_ESTE_SUR', self.calle)
        self.assertIn('"cara_x": CalleIdentidad.CARA_OESTE_NORTE', self.calle)
        self.assertEqual(self.calle.count('"hacia_calle":'), 3)
        self.assertIn("SEPARACION_FACHADA + tam.x * 0.5", self.calle)

    def test_las_pieles_no_cambian_colisiones(self):
        self.assertNotIn("CollisionShape3D", self.calle)
        self.assertNotIn("StaticBody3D", self.calle)
        self.assertIn("MeshInstance3D", self.calle)

    def test_el_controller_solo_monta_el_material_en_trayecto(self):
        self.assertIn('!= "trayecto"', self.controlador)
        self.assertIn("CalleMateriales.montar(mundo)", self.controlador)


if __name__ == "__main__":
    unittest.main()
