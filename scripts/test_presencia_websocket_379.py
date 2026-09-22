import re
import unittest

from scripts.godot_pruebas import ejecutar_script


PRUEBA_GODOT = "pruebas/pruebas_presencia_websocket_379.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class PresenciaWebSocket379RuntimeTest(unittest.TestCase):
    """Valida dos clientes reales contra el relay WebSocket local."""

    def test_presencia_websocket_en_godot_headless(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=60)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 18, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
