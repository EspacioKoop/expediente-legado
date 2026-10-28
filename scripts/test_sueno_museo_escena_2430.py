"""Comprueba la galería onírica real y su retorno sin escribir campaña."""

import re
import shutil
import unittest

from scripts.godot_pruebas import comprobar_contrato, motor


class MuseoEscena2430Test(unittest.TestCase):
    def test_recorrido_de_vida_no_canonica(self):
        if shutil.which(motor()) is None:
            self.skipTest(f"{motor()} no disponible en este entorno")
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_sueno_museo_escena_2430.gd",
            "museo_escena_2430:",
            timeout=45,
        )
        resumen = re.search(r"museo_escena_2430: (\d+) pasadas, 0 fallos", salida)
        self.assertIsNotNone(resumen, salida)
        self.assertGreaterEqual(int(resumen.group(1)), 24, salida)


if __name__ == "__main__":
    unittest.main()
