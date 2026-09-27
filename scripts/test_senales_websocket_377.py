import re
import unittest

from scripts.godot_pruebas import ejecutar_script


PRUEBA_GODOT = "pruebas/pruebas_senales_websocket_377.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SenalesWebSocket377RuntimeTest(unittest.TestCase):
    """Valida persistencia y replay de señales contra relay WebSocket local."""

    def test_senales_websocket_en_godot_headless(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=60)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 19, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
