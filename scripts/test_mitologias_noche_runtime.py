from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
ASIGNACION = ROOT / "godot" / "guion" / "mitologias_noche.gd"
AQUILES = ROOT / "godot" / "guion" / "dia_aquiles_sueno_app.gd"
GILGAMESH = ROOT / "godot" / "guion" / "dia_gilgamesh_sueno_app.gd"
MINOTAURO = ROOT / "godot" / "guion" / "dia_minotauro_sueno_app.gd"
HIDRA = ROOT / "godot" / "guion" / "dia_hidra_sueno_app.gd"
RYU = ROOT / "godot" / "guion" / "dia_ryu_sueno_app.gd"
RYU_VIGILIA = ROOT / "godot" / "guion" / "ryu_flow_vigilia.gd"
DUAT = ROOT / "godot" / "guion" / "sueno_duat.gd"
DUAT_CONTROLLER = ROOT / "godot" / "guion" / "dia_duat_sueno_app.gd"
SUENO_GILGAMESH = ROOT / "godot" / "guion" / "sueno_gilgamesh.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"


class MitologiasNocheRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.asignacion = ASIGNACION.read_text(encoding="utf-8")
        cls.aquiles = AQUILES.read_text(encoding="utf-8")
        cls.gilgamesh = GILGAMESH.read_text(encoding="utf-8")
        cls.minotauro = MINOTAURO.read_text(encoding="utf-8")
        cls.hidra = HIDRA.read_text(encoding="utf-8")
        cls.ryu = RYU.read_text(encoding="utf-8")
        cls.ryu_vigilia = RYU_VIGILIA.read_text(encoding="utf-8")
        cls.duat = DUAT.read_text(encoding="utf-8")
        cls.duat_controller = DUAT_CONTROLLER.read_text(encoding="utf-8")
        cls.sueno_gilgamesh = SUENO_GILGAMESH.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_asignacion_no_selecciona_ni_activa_familias(self):
        self.assertIn("class_name MitologiasNoche", self.asignacion)
        self.assertIn("const MAX_FAMILIAS_NOCHE := 2", self.asignacion)
        self.assertIn("static func asignar(", self.asignacion)
        self.assertIn("asignacion[familia] = indice", self.asignacion)
        self.assertNotRegex(self.asignacion, r"SemillasOniricas\s*\.")
        self.assertNotIn("activar_semilla_onirica(", self.asignacion)

    def test_indice_de_escena_sale_de_total_menos_pendientes(self):
        self.assertIn("static func indice_escena_actual(", self.asignacion)
        self.assertIn("cantidad_escenas - pendientes", self.asignacion)
        self.assertIn("static func corresponde_a_escena(", self.asignacion)

    def test_verticales_originales_consumen_la_misma_seleccion(self):
        controllers = (
            self.aquiles,
            self.gilgamesh,
            self.minotauro,
            self.hidra,
            self.ryu,
            self.duat_controller,
        )
        for controller in controllers:
            self.assertRegex(
                controller,
                r"SemillasOniricas\s*\.\s*seleccionar_para_noche\s*\(",
            )
            self.assertIn("MitologiasNoche.MAX_FAMILIAS_NOCHE", controller)
            self.assertRegex(
                controller,
                r"MitologiasNoche\s*\.\s*corresponde_a_escena\s*\(",
            )
            self.assertNotIn("activar_semilla_onirica", controller)

    def test_epica_435_monta_las_seis_familias_originales_en_dia_real(self):
        nodos = (
            "AquilesSuenoController",
            "GilgameshSuenoController",
            "MinotauroSuenoController",
            "HidraSuenoController",
            "RyuSuenoController",
            "DuatSuenoController",
        )
        for nombre in nodos:
            self.assertIn(f'[node name="{nombre}" type="Node" parent="."]', self.dia)

    def test_epica_435_cubre_semilla_rom_y_semilla_tv_fuera_de_oficina(self):
        self.assertIn('const ID_ROM := "ryu_flow_98"', self.ryu_vigilia)
        self.assertIn('const ID_MITO := "dragon_japones"', self.ryu_vigilia)
        self.assertIn('extends "res://guion/semilla_rom_vigilia.gd"', self.ryu_vigilia)
        self.assertIn('const FUENTE_TV := "tv:microdocumental_excavaciones_98"', self.duat)
        self.assertIn(
            "SemillasOniricas.activar_semilla_onirica(jornada, ID, FUENTE_TV, 1)",
            self.duat,
        )

    def test_reduccion_movimiento_se_propaga_a_verticales_jugables(self):
        for controller in (
            self.aquiles,
            self.minotauro,
            self.hidra,
            self.ryu,
            self.duat_controller,
        ):
            self.assertIn("reduccion_movimiento", controller)
            self.assertIn("PreferenciasSiga.cargar()", controller)

    def test_gilgamesh_usa_vertical_real_con_interaccion_integrada(self):
        self.assertIn(
            'preload("res://escenas/sueno_gilgamesh.tscn")', self.gilgamesh
        )
        self.assertIn("ESCENA_GILGAMESH.instantiate()", self.gilgamesh)
        self.assertIn("gilgamesh.preparar()", self.gilgamesh)
        self.assertIn("func preparar() -> void:", self.sueno_gilgamesh)
        self.assertIn("_montar_prototipo()", self.sueno_gilgamesh)

    def test_gilgamesh_no_secuestra_camara_ni_sustituye_la_sala(self):
        self.assertIn('get_node_or_null("CamaraStandalone")', self.gilgamesh)
        self.assertIn("gilgamesh.remove_child(camara)", self.gilgamesh)
        self.assertIn("camara.free()", self.gilgamesh)
        self.assertNotIn("mundo.queue_free", self.gilgamesh)
        self.assertIn('espacio.get("entrada", Vector3.ZERO)', self.gilgamesh)
        self.assertIn('espacio.get("salidas", [])', self.gilgamesh)
        self.assertIn("entrada.lerp(salida, 0.5)", self.gilgamesh)

    def test_dia_monta_controladores_nocturnos_originales(self):
        rutas = (
            "dia_aquiles_sueno_app.gd",
            "dia_gilgamesh_sueno_app.gd",
            "dia_minotauro_sueno_app.gd",
            "dia_hidra_sueno_app.gd",
            "dia_ryu_sueno_app.gd",
            "dia_duat_sueno_app.gd",
        )
        for ruta in rutas:
            self.assertIn(f'path="res://guion/{ruta}"', self.dia)


if __name__ == "__main__":
    unittest.main()
