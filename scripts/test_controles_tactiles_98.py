from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
CONTROLADOR = ROOT / "godot/guion/dia_controles_tactiles_app.gd"
DIA = ROOT / "godot/escenas/dia.tscn"
CAMINANTE = ROOT / "godot/guion/caminante.gd"


class ControlesTactiles98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.caminante = CAMINANTE.read_text(encoding="utf-8")

    def test_regresion_pura_en_godot(self):
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_controles_tactiles_98.gd",
            "0 fallos",
        )
        self.assertIn("pasadas", salida)

    def test_reutiliza_acciones_semanticas_sin_duplicar_interaccion(self):
        self.assertIn('const ACCION_INTERACTUAR: StringName = &"interactuar"', self.controlador)
        self.assertIn('const ACCION_CANCELAR: StringName = &"cancelar"', self.controlador)
        self.assertIn("InputEventAction.new()", self.controlador)
        self.assertIn("Input.parse_input_event(", self.controlador)
        self.assertNotIn("DetectorInteraccion3D.new()", self.controlador)
        self.assertNotIn(".interactuar(", self.controlador)
        self.assertNotIn("Input.action_press(", self.controlador)
        self.assertNotIn("Input.action_release(", self.controlador)

    def test_overlay_cede_a_pantallas_pausa_y_cinematica(self):
        for token in (
            "DisplayServer.is_touchscreen_available()",
            "caminante.is_physics_processing()",
            'dia.get("_pantalla") != null',
            'dia.get("_entrada") != null',
            "get_tree().paused",
        ):
            self.assertIn(token, self.controlador)

    def test_boton_interactuar_usa_prompt_contextual_existente(self):
        self.assertIn('caminante.get("_texto_interaccion_actual")', self.controlador)
        self.assertIn("_boton_interactuar.visible = not texto_interaccion.is_empty()", self.controlador)

    def test_dia_monta_controller_y_movimiento_tactil_sigue_independiente(self):
        self.assertIn("dia_controles_tactiles_app.gd", self.dia)
        self.assertIn('node name="ControlesTactiles98Controller"', self.dia)
        self.assertIn("_dedo_movimiento_tactil", self.caminante)
        self.assertNotIn("TouchScreenButton", self.caminante)


if __name__ == "__main__":
    unittest.main()
