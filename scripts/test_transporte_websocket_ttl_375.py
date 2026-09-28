import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
TRANSPORTE = ROOT / "godot" / "guion" / "red" / "transporte_websocket.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_transporte_websocket_ttl_375.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class TransporteWebSocketTTL375Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.transporte = TRANSPORTE.read_text(encoding="utf-8")

    def test_revalida_publicaciones_antes_de_vaciar_cola(self):
        self.assertIn("func _vaciar_cola(ahora_unix: int = -1) -> void:", self.transporte)
        self.assertIn("EventoOnline.validar(evento, ahora)", self.transporte)
        self.assertIn('String(mensaje.get("op", "")) == "publish"', self.transporte)
        self.assertIn("_cola_saliente.pop_front()", self.transporte)
        self.assertIn("_descartados += 1", self.transporte)

    def test_no_acopla_el_transporte_a_estado_de_campana(self):
        for forbidden in ("Partida.", "Jornada.", "SemillasOniricas", "Economia."):
            self.assertNotIn(forbidden, self.transporte)

    def test_regresion_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 7, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
