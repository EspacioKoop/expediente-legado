from pathlib import Path
import re
import unittest


RAIZ = Path(__file__).resolve().parents[1]
VIGILIA = RAIZ / "godot" / "guion" / "hidra_vigilia.gd"
SUENO = RAIZ / "godot" / "guion" / "sueno_hidra.gd"
SEMILLAS = RAIZ / "godot" / "guion" / "SemillasOniricas.gd"


class HidraVerticalTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.semillas = SEMILLAS.read_text(encoding="utf-8")

    def test_vigilia_hydra_loop_requiere_dos_interacciones_deliberadas(self):
        self.assertIn("extends Interactuable3D", self.vigilia)
        self.assertIn('const ID_MITO := "hidra"', self.vigilia)
        self.assertIn('const FUENTE := "rom:hydra_loop_98"', self.vigilia)
        self.assertIn("HYDRA_LOOP", self.vigilia)
        self.assertIn("const INTERACCIONES_REQUERIDAS := 2", self.vigilia)
        self.assertIn("_interacciones < INTERACCIONES_REQUERIDAS", self.vigilia)
        self.assertRegex(
            self.vigilia,
            r"SemillasOniricas\s*\.\s*activar_semilla_onirica",
        )

    def test_presencia_del_cartucho_no_activa_semilla(self):
        codigo = re.sub(r"#.*", "", self.vigilia)
        self.assertEqual(codigo.count("activar_semilla_onirica"), 1)
        self.assertIn("func _al_examinar", codigo)
        self.assertIn("func _intentar_activar", codigo)
        self.assertIn("if _interacciones < INTERACCIONES_REQUERIDAS", codigo)

    def test_semilla_canonica_esta_en_pool_y_gatea_el_sueno(self):
        self.assertIn('"hidra"', self.semillas)
        self.assertIn('const SEMILLA := "semilla_onirica_hidra"', self.sueno)
        self.assertIn("static func habilitada(semillas: Dictionary)", self.sueno)
        self.assertIn("visible = _habilitada", self.sueno)

    def test_proliferacion_esta_acotada_y_es_determinista(self):
        self.assertIn("const MAX_CABEZAS := 9", self.sueno)
        self.assertIn("const MAX_REGENERACIONES := 2", self.sueno)
        self.assertIn("static func cortar_sintoma", self.sueno)
        self.assertIn("posmod(cortes + raiz_seed, 2)", self.sueno)
        self.assertIn('siguiente["cabezas"] = mini(MAX_CABEZAS', self.sueno)
        self.assertIn("mini(\n\t\t\tMAX_REGENERACIONES", self.sueno)

    def test_hay_pista_progresiva_y_nodo_comun_resoluble(self):
        self.assertIn("func observar_conexiones", self.sueno)
        self.assertIn("const PISTA_NODO_LEGIBLE := 2", self.sueno)
        self.assertIn("static func resolver_nodo_comun", self.sueno)
        self.assertIn('siguiente["resuelta"] = true', self.sueno)
        self.assertIn('siguiente["cabezas"] = 0', self.sueno)
        self.assertIn("if int(siguiente.get(\"pista_nivel\", 0)) < PISTA_NODO_LEGIBLE", self.sueno)

    def test_reaccion_3d_y_regeneracion_arquitectonica_son_visibles(self):
        self.assertIn("extends Node3D", self.sueno)
        self.assertIn("MeshInstance3D.new()", self.sueno)
        self.assertIn("SphereMesh.new()", self.sueno)
        self.assertIn("BoxMesh.new()", self.sueno)
        self.assertIn("func _crear_regeneracion", self.sueno)
        self.assertIn('sala.name = "SalaRegenerada_%02d" % indice', self.sueno)

    def test_regeneracion_no_puede_softlockear_corredor(self):
        self.assertIn("const ANCHO_CORREDOR_SEGURO := 3.0", self.sueno)
        self.assertIn("static func regeneracion_respeta_corredor", self.sueno)
        self.assertIn("absf(posicion.x) >= ANCHO_CORREDOR_SEGURO", self.sueno)
        # El sueño no crea cuerpos físicos: las mutaciones arquitectónicas son
        # visuales y por construcción no pueden cerrar la única ruta válida.
        self.assertNotIn("CollisionShape3D.new()", self.sueno)
        self.assertNotIn("StaticBody3D.new()", self.sueno)

    def test_reduccion_movimiento_tiene_presentacion_discreta(self):
        self.assertIn("reduccion_movimiento", self.sueno)
        self.assertIn('"fundido_discreto"', self.sueno)
        self.assertIn('"crecimiento_escalonado"', self.sueno)

    def test_no_hay_mecanicas_de_combate_o_timing(self):
        codigo = re.sub(r"#.*", "", self.sueno).lower()
        for termino in ("health", "damage", "timer.new", "timeout.connect"):
            self.assertNotIn(termino, codigo)


if __name__ == "__main__":
    unittest.main()
