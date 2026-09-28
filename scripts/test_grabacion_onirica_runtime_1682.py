import unittest

from scripts.godot_pruebas import comprobar_contrato


class GrabacionOniricaRuntime1682Test(unittest.TestCase):
    def test_captura_runtime_en_godot(self):
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_grabacion_onirica_runtime_1682.gd",
            "0 fallos",
        )
        self.assertIn("pasadas", salida)


if __name__ == "__main__":
    unittest.main()
