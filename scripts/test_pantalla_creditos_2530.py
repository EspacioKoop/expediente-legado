"""Pruebas de la pantalla de créditos en el menú de inicio (#2530)."""

import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script

ROOT = Path(__file__).resolve().parents[1]
PRUEBA_GODOT = "res://pruebas/pruebas_pantalla_creditos_2530.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class PantallaCreditosTest(unittest.TestCase):
    def test_contrato_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 5, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
