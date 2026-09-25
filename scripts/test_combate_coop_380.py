import re
import unittest

from scripts.godot_pruebas import ejecutar_script


PRUEBA_GODOT = "pruebas/pruebas_combate_coop_380.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class CombateCoop380RuntimeTest(unittest.TestCase):
    """Ejecuta el vertical aislado de combate cooperativo con dos clientes fixture."""

    def test_combate_coop_en_godot_headless(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=60)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
