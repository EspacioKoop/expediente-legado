"""Ejecuta el contrato real del adaptador ENJAMBRE (#2157) en CI."""
import re
import shutil
import unittest

from scripts.godot_pruebas import ejecutar_script, motor


class EnjambreRuntime2120Test(unittest.TestCase):
    def test_contrato_multi_cuerpo(self):
        if shutil.which(motor()) is None:
            self.skipTest(f"{motor()} no disponible en este entorno")
        resultado = ejecutar_script("res://pruebas/pruebas_enjambre_runtime_2120.gd")
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = re.search(r"(\d+) pasadas, 0 fallos", resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 74, resultado.stdout)
        self.assertNotIn("ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
