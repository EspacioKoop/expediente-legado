import os
from pathlib import Path
import subprocess
import tempfile
import unittest

from scripts.godot_pruebas import importar_proyecto, motor
from scripts.verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]


class CinematicaFasesRealesTest(unittest.TestCase):
    def test_casa_sueno_usa_enganches_reales_y_equivale_skip_fin(self):
        importar_proyecto()
        with tempfile.TemporaryDirectory(prefix="legado-cinematica-280-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable, carpeta in (
                ("XDG_DATA_HOME", "datos"),
                ("XDG_CONFIG_HOME", "config"),
                ("XDG_CACHE_HOME", "cache"),
            ):
                entorno[variable] = str(Path(temporal) / carpeta)

            resultado = subprocess.run(
                [
                    motor(),
                    "--headless",
                    "--language",
                    "es",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    "pruebas/pruebas_cinematica_fases_reales.gd",
                ],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=45,
                check=False,
            )

        validar(resultado.stdout, resultado.returncode, minimo=40)
        self.assertIn("0 fallos", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
