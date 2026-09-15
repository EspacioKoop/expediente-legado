import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]


class GrabacionOniricaTest(unittest.TestCase):
    def test_contrato_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_grabacion_onirica.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)
        self.assertIn("pasadas", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
