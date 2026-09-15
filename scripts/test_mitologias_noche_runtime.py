from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
ASIGNACION = ROOT / "godot" / "guion" / "mitologias_noche.gd"
AQUILES = ROOT / "godot" / "guion" / "dia_aquiles_sueno_app.gd"
GILGAMESH = ROOT / "godot" / "guion" / "dia_gilgamesh_sueno_app.gd"
SUENO_GILGAMESH = ROOT / "godot" / "guion" / "sueno_gilgamesh.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"


class MitologiasNocheRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.asignacion = ASIGNACION.read_text(encoding="utf-8")
        cls.aquiles = AQUILES.read_text(encoding="utf-8")
        cls.gilgamesh = GILGAMESH.read_text(encoding="utf-8")
        cls.sueno_gilgamesh = SUENO_GILGAMESH.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_asignacion_no_selecciona_ni_activa_familias(self):
        self.assertIn("class_name MitologiasNoche", self.asignacion)
        self.assertIn("const MAX_FAMILIAS_NOCHE := 2", self.asignacion)
        self.assertIn("static func asignar(", self.asignacion)
        self.assertIn("asignacion[familia] = indice", self.asignacion)
        self.assertNotIn("SemillasOniricas", self.asignacion)
        self.assertNotIn("activar_semilla_onirica", self.asignacion)

    def test_indice_de_escena_sale_de_total_menos_pendientes(self):
        self.assertIn("static func indice_escena_actual(", self.asignacion)
        self.assertIn("cantidad_escenas - pendientes", self.asignacion)
        self.assertIn("static func corresponde_a_escena(", self.asignacion)

    def test_aquiles_y_gilgamesh_consumen_la_misma_seleccion(self):
        for controller in (self.aquiles, self.gilgamesh):
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
        self.assertIn("SuenoAquiles.ID_MITO", self.aquiles)
        self.assertIn("SuenoGilgamesh.ID_MITO", self.gilgamesh)

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

    def test_dia_monta_ambos_controllers_nocturnos(self):
        self.assertIn('path="res://guion/dia_aquiles_sueno_app.gd"', self.dia)
        self.assertIn('path="res://guion/dia_gilgamesh_sueno_app.gd"', self.dia)
        self.assertIn('[node name="AquilesSuenoController" type="Node" parent="."]', self.dia)
        self.assertIn(
            '[node name="GilgameshSuenoController" type="Node" parent="."]', self.dia
        )


if __name__ == "__main__":
    unittest.main()
