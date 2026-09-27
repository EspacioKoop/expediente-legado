import re
import unittest

from scripts.godot_pruebas import ejecutar_script


PRUEBA_GODOT = "pruebas/pruebas_minijuego_servicio_383.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class MinijuegoServicio383RuntimeTest(unittest.TestCase):
    """Ejecuta la fachada de sesión sobre el transporte fixture."""

    def test_servicio_minijuego_en_godot_headless(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=60)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 25, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
