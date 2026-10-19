"""Prueba de Godot del rodaje de créditos #795/#2527."""

import re
import unittest
from scripts.godot_pruebas import comprobar_contrato

PRUEBA_GODOT = "res://pruebas/pruebas_creditos_montaje_795.gd"


class CreditosMontaje795Test(unittest.TestCase):
    def test_montaje_real_en_godot(self) -> None:
        salida = comprobar_contrato(self, PRUEBA_GODOT, " 0 fallos", timeout=180)
        coincidencia = re.search(r"(\d+) pasadas, 0 fallos", salida)
        self.assertIsNotNone(coincidencia, salida)
        self.assertGreaterEqual(int(coincidencia.group(1)), 250, salida)


if __name__ == "__main__":
    unittest.main()
