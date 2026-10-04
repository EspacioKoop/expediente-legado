from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
CAMINANTE = ROOT / "godot/guion/caminante.gd"


class CaminanteTactil98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.caminante = CAMINANTE.read_text(encoding="utf-8")

    def test_regresion_pura_en_godot(self):
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_caminante_tactil_98.gd",
            "0 fallos",
        )
        self.assertIn("pasadas", salida)

    def test_multitouch_separa_movimiento_y_mirada(self):
        self.assertIn("InputEventScreenTouch", self.caminante)
        self.assertIn("InputEventScreenDrag", self.caminante)
        self.assertIn("arrastre.index == _dedo_movimiento_tactil", self.caminante)
        self.assertIn("_limpiar_movimiento_tactil()", self.caminante)
        self.assertIn("_aplicar_arrastre_tactil(arrastre)", self.caminante)

    def test_no_simula_acciones_ni_rompe_teclado_mando(self):
        self.assertIn("Input.get_vector(MOVER_IZQUIERDA", self.caminante)
        self.assertIn("_movimiento_tactil", self.caminante)
        for prohibido in (
            "Input.action_press(",
            "Input.action_release(",
            "TouchScreenButton",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, self.caminante)


if __name__ == "__main__":
    unittest.main()
