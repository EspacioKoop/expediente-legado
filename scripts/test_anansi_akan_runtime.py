import unittest

from scripts.godot_pruebas import comprobar_contrato


PRUEBA_GODOT = "pruebas/pruebas_anansi_akan.gd"


class AnansiAkanRuntimeTest(unittest.TestCase):
    def test_vertical_anansi_en_godot_headless(self):
        comprobar_contrato(
            self,
            PRUEBA_GODOT,
            "48 pasadas, 0 fallos",
            timeout=60,
        )


if __name__ == "__main__":
    unittest.main()
