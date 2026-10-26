"""Regresión headless del recorrido interactivo de Catedral Invertida #2431."""

import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class CatedralRecorrido3DTest(unittest.TestCase):
    def test_dos_giros_y_salida_real(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        ejecutable = shutil.which(motor)
        if ejecutable is None:
            if os.environ.get("SIGA98_EXIGIR_EXTENSION") == "1":
                self.fail(f"No está disponible el ejecutable de Godot: {motor}")
            self.skipTest(f"Godot no instalado: {motor}")

        resultado = subprocess.run(
            [
                ejecutable,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_catedral_invertida_recorrido_3d.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=45,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
