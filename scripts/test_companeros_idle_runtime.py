import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
PRUEBA_GODOT = "pruebas/pruebas_companeros_idle.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class CompanerosIdleRuntimeTest(unittest.TestCase):
    """Ejecuta la prueba Godot de CompaneroIdle3D, que ningún runner invocaba."""

    def test_idle_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertEqual(resumen.group(1), "9", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
