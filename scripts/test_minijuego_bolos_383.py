import re
import unittest

from scripts.godot_pruebas import ejecutar_script


PRUEBA_GODOT = "pruebas/pruebas_minijuego_bolos_383.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class MinijuegoBolos383RuntimeTest(unittest.TestCase):
    """Comprueba que #383 reutiliza la física determinista real de #159."""

    def test_bolos_coop_en_godot_headless(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=60)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 35, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
