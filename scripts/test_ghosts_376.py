import re
import unittest

from scripts.godot_pruebas import ejecutar_script


PRUEBA_GODOT = "pruebas/pruebas_ghosts_376.gd"
RESUMEN_GODOT = re.compile(r"Ghosts #376: (\d+) pasadas, 0 fallos")


class Ghosts376RuntimeTest(unittest.TestCase):
    """Ejecuta el vertical local de ghosts y movimiento onírico reutilizable."""

    def test_ghosts_en_godot_headless(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=60)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 25, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
