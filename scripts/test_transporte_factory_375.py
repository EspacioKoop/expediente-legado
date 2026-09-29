import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
FACTORY = ROOT / "godot" / "guion" / "red" / "transporte_online_factory.gd"
CONSUMIDORES = (
    ROOT / "godot" / "guion" / "dia_ghosts_app.gd",
    ROOT / "godot" / "guion" / "ventanilla_coop_acceso.gd",
    ROOT / "godot" / "guion" / "dia_presencia_coop_app.gd",
)
PRUEBA = "pruebas/pruebas_transporte_factory_375.gd"
RESUMEN = re.compile(r"transporte_factory_375: (\d+) pasadas, 0 fallos")


class TransporteFactory375Test(unittest.TestCase):
    def test_solo_factory_conoce_websocket_concreto(self):
        factory = FACTORY.read_text(encoding="utf-8")
        self.assertIn('preload("res://guion/red/transporte_websocket.gd")', factory)
        self.assertIn('preload("res://guion/red/transporte_nulo.gd")', factory)
        self.assertIn("TransporteWebSocket.new(normalizado)", factory)
        for ruta in CONSUMIDORES:
            fuente = ruta.read_text(encoding="utf-8")
            self.assertIn("TransporteOnlineFactory", fuente, ruta.name)
            self.assertNotIn("TransporteWebSocket", fuente, ruta.name)

    def test_consumidores_conservan_inyeccion_para_pruebas(self):
        ventanilla = CONSUMIDORES[1].read_text(encoding="utf-8")
        presencia = CONSUMIDORES[2].read_text(encoding="utf-8")
        self.assertIn("transporte_override", ventanilla)
        self.assertIn("transporte: RefCounted = null", presencia)

    def test_factory_ejecutable_en_godot(self):
        importar_proyecto()
        motor = os.environ.get("GODOT_BIN", "godot4")
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA,
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
        self.assertGreaterEqual(int(resumen.group(1)), 6, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
