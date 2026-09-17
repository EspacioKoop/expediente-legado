import unittest

from scripts.godot_pruebas import comprobar_contrato


class PlaytestJuicioTelemetria912Test(unittest.TestCase):
    def test_metricas_de_sesion_sin_persistencia(self):
        comprobar_contrato(
            self,
            "pruebas/playtest_juicio_telemetria_912.gd",
            "playtest_juicio_telemetria_912:",
        )


if __name__ == "__main__":
    unittest.main()
