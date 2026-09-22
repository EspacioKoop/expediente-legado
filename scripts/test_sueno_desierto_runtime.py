from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DESIERTO = ROOT / "godot" / "guion" / "sueno_desierto.gd"
DESIERTO_3D = ROOT / "godot" / "guion" / "sueno_desierto_3d.gd"
DIA_SUENO = ROOT / "godot" / "guion" / "dia_sueno_app.gd"
ESPACIO_3D = ROOT / "godot" / "guion" / "espacio_3d.gd"


class SuenoDesiertoRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.desierto = DESIERTO.read_text(encoding="utf-8")
        cls.desierto_3d = DESIERTO_3D.read_text(encoding="utf-8")
        cls.dia = DIA_SUENO.read_text(encoding="utf-8")
        cls.espacio_3d = ESPACIO_3D.read_text(encoding="utf-8")

    def test_reutiliza_peine_y_familia_fragmentada(self):
        self.assertIn('const FORMA := "peine"', self.desierto)
        self.assertIn("const FAMILIA := SuenoFamilias.FRAGMENTADA", self.desierto)
        self.assertIn('resultado["contorno"] = familia["contorno"]', self.desierto)
        self.assertIn('resultado["altura_contorno"]', self.desierto)
        self.assertIn('resultado["tabiques_poligonales"]', self.desierto)
        self.assertIn('familia.get("tabiques", [])', self.desierto)
        self.assertIn('resultado["entrada"]', self.desierto)

    def test_runtime_materializa_los_tabiques_sin_conocer_el_desierto(self):
        self.assertIn('espacio.get("tabiques_poligonales", [])', self.espacio_3d)
        self.assertIn("SuenoGeometria.cuerpo_sala(contorno, altura, tabiques)", self.espacio_3d)
        self.assertNotIn("SuenoDesierto", self.espacio_3d)

    def test_presentacion_reexpone_tabiques_que_la_sala_base_oculta(self):
        self.assertIn("_ocultar_sala_cerrada()", self.desierto_3d)
        self.assertIn('espacio.get("tabiques_poligonales", [])', self.desierto_3d)
        self.assertIn("SuenoGeometria.malla_tabiques(tabiques)", self.desierto_3d)
        self.assertIn('"TabiquesMineralesFragmentados"', self.desierto_3d)
        self.assertNotIn("StaticBody3D.new", self.desierto_3d)
        self.assertNotIn("CollisionShape3D.new", self.desierto_3d)

    def test_remapea_contenido_a_coordenadas_del_desierto(self):
        self.assertIn('resultado.get("salidas", [])', self.desierto)
        self.assertIn('salida_principal["pos"] = salida_pos', self.desierto)
        self.assertIn('resultado.get("figuras", [])', self.desierto)
        self.assertIn('figura["pos"] = sitios', self.desierto)
        self.assertIn('resultado.get("carteles", [])', self.desierto)
        self.assertIn('cartel["pos"] = sitios', self.desierto)

    def test_telefono_reutiliza_frase_conocida(self):
        self.assertIn("carteles.pop_front()", self.desierto)
        self.assertIn('frase_conocida = String(primero.get("texto", ""))', self.desierto)
        self.assertIn('"frase": frase_conocida', self.desierto)
        self.assertIn('"destino": ""', self.desierto)

    def test_cubre_regla_de_extraneza(self):
        for clave in (
            '"horizonte_recede"',
            '"silencio_local"',
            '"huellas_geometricas"',
            '"papel_enterrado"',
            '"telefono_con_tono"',
        ):
            self.assertIn(clave, self.desierto)

    def test_no_muta_estado_jugable_ni_azar_global(self):
        codigo = self.desierto.split("class_name SuenoDesierto", 1)[1]
        for termino in ("Jornada.", "Partida.", "dinero", "veredicto", "randf(", "randi("):
            self.assertNotIn(termino, codigo)

    def test_capa_nocturna_adapta_sin_reseleccionar_la_noche(self):
        self.assertIn("var espacio: Dictionary = super._espacio_de(fase)", self.dia)
        self.assertIn("SuenoDesierto.es_forma(id)", self.dia)
        self.assertIn("SuenoDesierto.adaptar_espacio(espacio", self.dia)
        self.assertNotIn("Sueno.noche(", self.desierto)


if __name__ == "__main__":
    unittest.main()
