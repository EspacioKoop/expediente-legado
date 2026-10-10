"""Contrato puro del museo de vidas no ocurridas (#2467).

La comprobación real se hace en Godot: tres vidas no canónicas, una sola
explorable, deterministas y sin mutar el contexto recibido.
"""

import re
import unittest

from scripts.godot_pruebas import comprobar_contrato

PRUEBA_GODOT = "res://pruebas/pruebas_sueno_museo_2467.gd"


class SuenoMuseo2467Test(unittest.TestCase):
    def test_contrato_en_godot(self):
        salida = comprobar_contrato(self, PRUEBA_GODOT, " 0 fallos")
        pasadas = int(re.search(r"(\d+) pasadas, 0 fallos", salida).group(1))
        self.assertGreaterEqual(pasadas, 15, salida)


if __name__ == "__main__":
    unittest.main()
