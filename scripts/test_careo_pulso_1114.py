import unittest

from scripts.godot_pruebas import comprobar_contrato


class CareoPulso1114Test(unittest.TestCase):
    def test_pulso_interactivo(self):
        comprobar_contrato(
            self,
            "pruebas/careo_pulso_1114.gd",
            "careo_pulso_1114: 29 pasadas, 0 fallos",
        )


if __name__ == "__main__":
    unittest.main()
