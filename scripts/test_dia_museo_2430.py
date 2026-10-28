"""Prueba de ida y vuelta entre una sala de sueño y el Museo (#2430)."""

import re
import shutil
import unittest

from scripts.godot_pruebas import comprobar_contrato, motor


class DiaMuseo2430Test(unittest.TestCase):
    def test_portales_y_jornada_inmutable(self):
        if shutil.which(motor()) is None:
            self.skipTest(f"{motor()} no disponible en este entorno")
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_dia_museo_2430.gd",
            "dia_museo_2430:",
            timeout=45,
        )
        resumen = re.search(r"dia_museo_2430: (\d+) pasadas, 0 fallos", salida)
        self.assertIsNotNone(resumen, salida)
        self.assertGreaterEqual(int(resumen.group(1)), 13, salida)


if __name__ == "__main__":
    unittest.main()
