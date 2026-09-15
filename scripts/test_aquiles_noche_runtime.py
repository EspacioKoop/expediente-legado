from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CONTROLLER = ROOT / "godot" / "guion" / "dia_aquiles_sueno_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"


class AquilesNocheRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_controller_esta_montado_en_dia_real(self):
        self.assertIn('path="res://guion/dia_aquiles_sueno_app.gd"', self.dia)
        self.assertIn('[node name="AquilesSuenoController" type="Node" parent="."]', self.dia)

    def test_solo_monta_durante_sueno_y_por_seleccion_comun(self):
        self.assertIn('if fase != "sueño":', self.controller)
        self.assertRegex(
            self.controller,
            r"SemillasOniricas\s*\.\s*seleccionar_para_noche\s*\(",
        )
        self.assertIn("MitologiasNoche.MAX_FAMILIAS_NOCHE", self.controller)
        self.assertIn("_corresponde_a_esta_escena(dia, familias)", self.controller)
        self.assertRegex(
            self.controller,
            r"MitologiasNoche\s*\.\s*corresponde_a_escena\s*\(",
        )
        self.assertIn("SuenoAquiles.ID_MITO", self.controller)
        self.assertNotIn("activar_semilla_onirica", self.controller)
        self.assertNotIn("semilla_onirica_aquiles", self.controller)

    def test_no_repite_aquiles_y_ya_no_fuerza_la_primera_escena(self):
        self.assertIn("_aquiles_montado_esta_noche = true", self.controller)
        self.assertNotIn("_es_primera_escena", self.controller)
        self.assertNotIn("pendientes.size() == cantidad", self.controller)

    def test_reutiliza_vertical_interactivo_y_no_secuestra_camara(self):
        self.assertIn("SuenoAquilesAlineacion.new()", self.controller)
        self.assertIn("aquiles.preparar()", self.controller)
        self.assertIn('get_node_or_null("CamaraStandalone")', self.controller)
        self.assertIn("aquiles.remove_child(camara)", self.controller)
        self.assertIn("camara.free()", self.controller)

    def test_reduccion_movimiento_viene_de_preferencias(self):
        self.assertIn("PreferenciasSiga.cargar()", self.controller)
        self.assertIn('get("reduccion_movimiento", false)', self.controller)
        self.assertIn("aquiles.reduccion_movimiento", self.controller)

    def test_preserva_sala_base_y_salidas(self):
        self.assertNotIn("queue_free()", self.controller)
        self.assertIn('espacio.get("entrada", Vector3.ZERO)', self.controller)
        self.assertIn('espacio.get("salidas", [])', self.controller)
        self.assertIn("entrada.lerp(salida, 0.5)", self.controller)


if __name__ == "__main__":
    unittest.main()
