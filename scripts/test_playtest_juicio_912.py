import unittest

from scripts.godot_pruebas import comprobar_contrato


class PlaytestJuicio912Test(unittest.TestCase):
    def test_baseline_cuantitativo_base_y_seis_rituales(self):
        comprobar_contrato(
            self,
            "pruebas/playtest_juicio_912.gd",
            "playtest_juicio_912: 7 escenarios, 0 fallos",
        )


if __name__ == "__main__":
    unittest.main()
