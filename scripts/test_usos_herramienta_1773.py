import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
USOS = ROOT / "godot" / "guion" / "usos_herramienta.gd"
PRUEBA = "res://pruebas/pruebas_usos_herramienta_1773.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class UsosHerramienta1773Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = USOS.read_text(encoding="utf-8")

    def test_resuelve_por_semantica_y_solo_carried(self):
        for uso in ("forzar", "iluminar", "estabilizar", "calzar"):
            self.assertIn(f'"{uso}"', self.fuente)
        self.assertIn("Inventario.CARRIED", self.fuente)
        self.assertNotIn("Inventario.HOME_STORAGE", self.fuente)
        self.assertNotIn("Inventario.visibles", self.fuente)

    def test_no_hardcodea_herramientas_concretas(self):
        for objeto_id in ("palanca_kkryy", "linterna_kkryy", "cuña_madera"):
            self.assertNotIn(objeto_id, self.fuente)
        self.assertIn('objeto.get("usos"', self.fuente)

    def test_no_muta_inventario_ni_consume_implicitamente(self):
        self.assertNotIn("Inventario.retirar", self.fuente)
        self.assertNotIn("Inventario.recoger", self.fuente)
        self.assertNotIn("Inventario.guardar_en_casa", self.fuente)
        self.assertIn('objeto.get("consumir_usos"', self.fuente)
        for campo in ("dinero", "acciones", "precio"):
            self.assertNotIn(campo, self.fuente)

    def test_contrato_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        if shutil.which(motor) is None:
            self.skipTest(f"{motor} no disponible en este entorno")
        importar_proyecto()
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
        self.assertGreaterEqual(int(resumen.group(1)), 25, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
