import re
import unittest

from scripts.godot_pruebas import ejecutar_script


PRUEBA_GODOT = "pruebas/pruebas_senales_interaccion_377.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SenalesInteraccion377RuntimeTest(unittest.TestCase):
    """Ejecuta el compositor cerrado de señales sobre la calle real."""

    def test_compositor_senales_en_godot_headless(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=60)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 13, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
