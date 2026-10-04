"""Ejecuta la regresión integrada del Eco del Kenoma desde el CI canónico."""

import re
import shutil
import unittest

from scripts.godot_pruebas import comprobar_contrato, motor


class Kenoma2089Test(unittest.TestCase):
    def test_limite_repeticion_y_destruccion_en_godot(self):
        if shutil.which(motor()) is None:
            self.skipTest(f"{motor()} no disponible en este entorno")
        salida = comprobar_contrato(
            self,
            "pruebas/pruebas_kenoma_runtime_2089.gd",
            "pruebas_kenoma_runtime_2089:",
        )
        resumen = re.search(r"pruebas_kenoma_runtime_2089: (\d+) pasadas, 0 fallos", salida)
        self.assertIsNotNone(resumen, salida)
        self.assertGreaterEqual(int(resumen.group(1)), 841, salida)


if __name__ == "__main__":
    unittest.main()
