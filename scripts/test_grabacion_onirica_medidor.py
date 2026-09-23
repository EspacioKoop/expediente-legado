import unittest

from scripts.godot_pruebas import comprobar_contrato


class GrabacionOniricaMedidorTest(unittest.TestCase):
    def test_medidor_en_godot(self):
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_grabacion_onirica_medidor.gd",
            "0 fallos",
        )
        self.assertIn("pasadas", salida)


if __name__ == "__main__":
    unittest.main()
