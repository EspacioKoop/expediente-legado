"""Regresión del acabado de suelo administrativo frente al PSX heredado (#398)."""

import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class SueloRealista398Test(unittest.TestCase):
    def test_godot_suelo_y_fallback(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "res://pruebas/pruebas_suelo_realista_398.gd",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=90,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertNotRegex(resultado.stdout, r"SCRIPT ERROR:|Parse Error:")
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 10, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
