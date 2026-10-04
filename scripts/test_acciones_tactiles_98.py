from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
OVERLAY = ROOT / "godot/guion/acciones_tactiles_98.gd"
CAMINANTE = ROOT / "godot/guion/caminante.gd"


class AccionesTactiles98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.overlay = OVERLAY.read_text(encoding="utf-8")
        cls.caminante = CAMINANTE.read_text(encoding="utf-8")

    def test_regresion_godot(self):
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_acciones_tactiles_98.gd",
            "0 fallos",
        )
        self.assertIn("pasadas", salida)

    def test_overlay_delega_en_inputmap_sin_simular_acciones(self):
        self.assertIn("TouchScreenButton.new()", self.overlay)
        self.assertIn('ACCION_INTERACTUAR := "interactuar"', self.overlay)
        self.assertIn('ACCION_CANCELAR := "cancelar"', self.overlay)
        self.assertIn("boton.action = accion", self.overlay)
        self.assertIn("VISIBILITY_TOUCHSCREEN_ONLY", self.overlay)
        self.assertNotIn("Input.action_press(", self.overlay)
        self.assertNotIn("Input.action_release(", self.overlay)

    def test_caminante_solo_monta_y_declara_disponibilidad(self):
        self.assertIn('preload("res://guion/acciones_tactiles_98.gd")', self.caminante)
        self.assertIn("_montar_acciones_tactiles()", self.caminante)
        self.assertIn("func acciones_tactiles_disponibles() -> bool:", self.caminante)
        self.assertIn("is_physics_processing()", self.caminante)
        self.assertIn("Input.mouse_mode == Input.MOUSE_MODE_CAPTURED", self.caminante)
        self.assertNotIn("TouchScreenButton", self.caminante)
        self.assertNotIn("Input.action_press(", self.caminante)
        self.assertNotIn("Input.action_release(", self.caminante)


if __name__ == "__main__":
    unittest.main()
