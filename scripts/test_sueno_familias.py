from pathlib import Path
import re
import unittest


RAIZ = Path(__file__).resolve().parents[1]
FAMILIAS = RAIZ / "godot" / "guion" / "sueno_familias.gd"


class SuenoFamiliasTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.texto = FAMILIAS.read_text(encoding="utf-8")

    def test_declara_las_tres_familias_del_issue(self):
        self.assertIn('CONVERGENTE := "convergente"', self.texto)
        self.assertIn('ANULAR := "anular"', self.texto)
        self.assertIn('FRAGMENTADA := "fragmentada"', self.texto)

    def test_no_vuelve_a_rect2i_ni_boxmesh(self):
        self.assertNotIn("Rect2i", self.texto)
        self.assertNotIn("BoxMesh", self.texto)

    def test_reutiliza_la_geometria_poligonal_integrada(self):
        self.assertIn("SuenoGeometria.malla_sala", self.texto)
        self.assertIn("SuenoGeometria.contorno_valido", self.texto)
        self.assertIn("SuenoGeometria.tiene_arista_diagonal", self.texto)

    def test_expone_cuerpo_con_colision_compartida(self):
        self.assertIn("static func cuerpo", self.texto)
        self.assertIn("SuenoGeometria.cuerpo_sala", self.texto)
        self.assertIn("StaticBody3D.new()", self.texto)

    def test_cada_familia_tiene_entrada_y_anclas_de_contenido(self):
        self.assertGreaterEqual(self.texto.count('"entrada": Vector3('), 3)
        self.assertGreaterEqual(len(re.findall(r'"anclas"\s*:\s*\[', self.texto)), 3)

    def test_anular_es_concavo_y_fragmentada_declara_tabiques_reales(self):
        anular = self.texto.split("\tANULAR:", 1)[1].split("\tFRAGMENTADA:", 1)[0]
        fragmentada = self.texto.split("\tFRAGMENTADA:", 1)[1]
        self.assertNotIn('"hueco":', anular)
        self.assertGreaterEqual(anular.count("Vector2("), 16)
        self.assertRegex(fragmentada, re.compile(r'"tabiques"\s*:\s*\n?\s*\['))
        self.assertGreaterEqual(fragmentada.count('"desde": Vector2('), 3)
        self.assertGreaterEqual(fragmentada.count('"hasta": Vector2('), 3)
        self.assertIn('familia.get("tabiques", [])', self.texto)

    def test_no_toca_progreso_jornada_ni_recompensas(self):
        bloque = self.texto.lower()
        for termino in ["jornada.", "partida", "dinero", "acciones", "pistas_descubiertas", "veredicto"]:
            self.assertNotIn(termino, bloque)


if __name__ == "__main__":
    unittest.main()
