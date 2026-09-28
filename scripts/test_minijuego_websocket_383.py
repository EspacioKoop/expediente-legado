import re
import unittest

from scripts.godot_pruebas import ejecutar_script


PRUEBA_GODOT = "pruebas/pruebas_minijuego_websocket_383.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class MinijuegoWebSocket383RuntimeTest(unittest.TestCase):
    def test_dos_clientes_minijuego_sobre_relay_real(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=90)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
