from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
DETECTOR = ROOT / "godot" / "guion" / "detector_interaccion_3d.gd"
GATO = ROOT / "godot" / "guion" / "gato.gd"
PREFERENCIAS = ROOT / "godot" / "guion" / "preferencias_siga.gd"


class GatoControles787Test(unittest.TestCase):
    def test_gato_sigue_el_contrato_comun_de_interaccion(self):
        gato = GATO.read_text(encoding="utf-8")
        detector = DETECTOR.read_text(encoding="utf-8")
        self.assertIn("extends Interactuable3D", gato)
        self.assertIn('evento.is_action_pressed("interactuar")', detector)
        self.assertNotIn("InputEventKey", detector)
        self.assertNotIn("InputEventJoypadButton", detector)

    def test_interactuar_conserva_teclado_raton_y_mando(self):
        preferencias = PREFERENCIAS.read_text(encoding="utf-8")
        self.assertIn('"interactuar": {"teclado": 69, "mando": JOY_BUTTON_A}', preferencias)
        self.assertIn("InputEventMouseButton.new()", preferencias)
        self.assertIn("raton.button_index = MOUSE_BUTTON_LEFT", preferencias)
        self.assertIn('InputMap.action_add_event("interactuar", raton)', preferencias)

    def test_los_tres_dispositivos_recorrer_las_acciones_del_gato(self):
        comprobar_contrato(
            self,
            "pruebas/pruebas_gato_controles_787.gd",
            "19 pasadas, 0 fallos",
        )


if __name__ == "__main__":
    unittest.main()
