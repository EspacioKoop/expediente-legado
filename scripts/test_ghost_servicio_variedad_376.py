import re
import unittest

from scripts.godot_pruebas import ejecutar_script


PRUEBA_GODOT = "pruebas/pruebas_ghost_servicio_variedad_376.gd"
RESUMEN = re.compile(r"Ghost selección #376: (\d+) pasadas, 0 fallos")


class GhostServicioVariedad376Test(unittest.TestCase):
    def test_seleccion_varia_sin_perder_frescura(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=60)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 10, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
