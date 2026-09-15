import os
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ANCHO = 1024
ALTO = 680


class EscritorioVisualSmokeTest(unittest.TestCase):
    def test_shell_real_genera_capturas_reproducibles(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        with tempfile.TemporaryDirectory(prefix="siga98-shell-smoke-") as temporal:
            salida = Path(temporal).resolve()
            resultado = subprocess.run(
                [
                    motor,
                    "--headless",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    "pruebas/pruebas_escritorio_visual_smoke.gd",
                    "--",
                    f"--output={salida}",
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=30,
                check=False,
            )

            self.assertEqual(resultado.returncode, 0, resultado.stdout)
            self.assertIn("SMOKE_VISUAL_ESCRITORIO_OK", resultado.stdout)
            self.assertNotIn("Parse Error:", resultado.stdout)
            self.assertNotIn("FALLO smoke visual escritorio", resultado.stdout)

            base = salida / "escritorio-ventanas.png"
            modal = salida / "escritorio-modal.png"
            for captura in (base, modal):
                self.assertTrue(captura.is_file(), f"captura ausente: {captura.name}")
                self.assertGreater(captura.stat().st_size, 2048, captura.name)
                self.assertEqual(self._dimensiones_png(captura), (ANCHO, ALTO))

            self.assertNotEqual(
                base.read_bytes(),
                modal.read_bytes(),
                "la captura modal debe reflejar un estado visual distinto",
            )

    @staticmethod
    def _dimensiones_png(ruta: Path) -> tuple[int, int]:
        with ruta.open("rb") as archivo:
            cabecera = archivo.read(24)
        if len(cabecera) < 24 or cabecera[:8] != b"\x89PNG\r\n\x1a\n":
            raise AssertionError(f"PNG inválido: {ruta}")
        return struct.unpack(">II", cabecera[16:24])


if __name__ == "__main__":
    unittest.main()
