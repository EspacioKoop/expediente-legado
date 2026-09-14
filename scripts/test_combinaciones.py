import os
from pathlib import Path
import subprocess
import unittest

from scripts.verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]


class CombinacionesTest(unittest.TestCase):
    def test_relaciones_y_persistencia_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importacion = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--editor",
                "--import",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=120,
            check=False,
        )
        validar(importacion.stdout, importacion.returncode, importando=True)
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_combinaciones.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("9 pasadas, 0 fallos", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
