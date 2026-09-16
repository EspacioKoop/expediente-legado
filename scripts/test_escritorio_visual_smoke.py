import os
from pathlib import Path
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]


class EscritorioVisualSmokeTest(unittest.TestCase):
    def test_shell_real_genera_capturas_reproducibles(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        comando = [
            motor,
            "--path",
            str(ROOT / "godot"),
            "--rendering-method",
            "gl_compatibility",
            "--audio-driver",
            "Dummy",
            "--script",
            "pruebas/pruebas_escritorio_visual_smoke.gd",
        ]
        if not os.environ.get("DISPLAY"):
            xvfb = shutil.which("xvfb-run")
            if xvfb is None:
                self.skipTest("el smoke visual requiere DISPLAY o xvfb-run")
            comando = [xvfb, "-a", "-s", "-screen 0 1280x800x24", *comando]

        resultado = subprocess.run(
            comando,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )

        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(
            resultado.stdout,
            r"SMOKE_VISUAL_ESCRITORIO_OK captures=2 resolution=1024x680 "
            r"bytes_base=\d+ bytes_modal=\d+ distinct=1",
        )
        self.assertNotIn("Parse Error:", resultado.stdout)
        self.assertNotIn("FALLO smoke visual escritorio", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
