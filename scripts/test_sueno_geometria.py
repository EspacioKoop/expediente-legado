from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GEOMETRIA = ROOT / "godot" / "guion" / "sueno_geometria.gd"


class SuenoGeometriaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = GEOMETRIA.read_text(encoding="utf-8")
        cls.codigo_ejecutable = "\n".join(
            linea for linea in cls.codigo.splitlines() if not linea.lstrip().startswith("#")
        )

    def test_no_depende_de_cajas_o_rect2i(self):
        self.assertNotIn("BoxMesh", self.codigo_ejecutable)
        self.assertNotIn("Rect2i", self.codigo_ejecutable)

    def test_triangula_un_contorno_arbitrario(self):
        self.assertIn("Geometry2D.triangulate_polygon(contorno)", self.codigo)
        self.assertIn("_agregar_suelo_y_techo", self.codigo)
        self.assertIn("_agregar_paredes", self.codigo)
        self.assertIn("_agregar_tabiques", self.codigo)

    def test_expone_guardia_para_aristas_diagonales(self):
        self.assertIn("func tiene_arista_diagonal", self.codigo)
        self.assertIn("not is_zero_approx(delta.x)", self.codigo)
        self.assertIn("not is_zero_approx(delta.y)", self.codigo)

    def test_el_cuerpo_usa_la_misma_malla_para_visual_y_colision(self):
        self.assertIn("static func cuerpo_sala", self.codigo)
        self.assertIn("StaticBody3D.new()", self.codigo)
        self.assertIn("visual.mesh = malla", self.codigo)
        self.assertIn("CollisionShape3D.new()", self.codigo)
        self.assertIn("malla.create_trimesh_shape()", self.codigo)
        self.assertIn("malla_sala(contorno, altura, tabiques)", self.codigo)

    def test_tabiques_son_planos_abiertos_y_no_cajas(self):
        self.assertIn("static func malla_tabiques", self.codigo)
        self.assertIn("_agregar_tabiques(st, tabiques)", self.codigo)
        self.assertIn('tabique.get("desde"', self.codigo)
        self.assertIn('tabique.get("hasta"', self.codigo)
        self.assertIn('tabique.get("altura_desde"', self.codigo)
        self.assertIn('tabique.get("altura_hasta"', self.codigo)
        self.assertGreaterEqual(self.codigo.count("_triangulo(st, abajo_"), 4)

    def test_un_contorno_invalido_no_intenta_crear_colision(self):
        self.assertIn("if malla.get_surface_count() == 0:", self.codigo)
        self.assertIn("return cuerpo", self.codigo)

    def test_no_toca_navegacion_ni_progreso(self):
        for termino in (
            "Caminante",
            "Partida",
            "Jornada",
            "pistas_descubiertas",
            "cambiar_escena",
        ):
            self.assertNotIn(termino, self.codigo_ejecutable)


if __name__ == "__main__":
    unittest.main()
