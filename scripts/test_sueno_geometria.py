from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GEOMETRIA = ROOT / "godot" / "guion" / "sueno_geometria.gd"


class SuenoGeometriaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = GEOMETRIA.read_text(encoding="utf-8")

    def test_no_depende_de_cajas_o_rect2i(self):
        self.assertNotIn("BoxMesh", self.codigo)
        self.assertNotIn("Rect2i", self.codigo)

    def test_triangula_un_contorno_arbitrario(self):
        self.assertIn("Geometry2D.triangulate_polygon(contorno)", self.codigo)
        self.assertIn("_agregar_suelo_y_techo", self.codigo)
        self.assertIn("_agregar_paredes", self.codigo)

    def test_expone_guardia_para_aristas_diagonales(self):
        self.assertIn("func tiene_arista_diagonal", self.codigo)
        self.assertIn("not is_zero_approx(delta.x)", self.codigo)
        self.assertIn("not is_zero_approx(delta.y)", self.codigo)

    def test_no_toca_navegacion_ni_progreso(self):
        for termino in (
            "Caminante",
            "Partida",
            "Jornada",
            "pistas_descubiertas",
            "cambiar_escena",
        ):
            self.assertNotIn(termino, self.codigo)


if __name__ == "__main__":
    unittest.main()
