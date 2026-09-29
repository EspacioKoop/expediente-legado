import re
import unittest

from scripts.godot_pruebas import ejecutar_script


PRUEBA_GODOT = "res://pruebas/pruebas_evaluacion_cierres_150.gd"
RESUMEN = re.compile(r"evaluacion_cierres_150: (\d+) pasadas, 0 fallos")


class EvaluacionCierres150Test(unittest.TestCase):
    def test_reasignacion_y_final_narrativo_sellan_el_mismo_historial(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 14, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
