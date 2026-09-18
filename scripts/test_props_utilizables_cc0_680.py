"""Contrato standalone de props utilizables CC0 del issue #680."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

from verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]


class PropsUtilizablesCc0Test(unittest.TestCase):
    def test_contrato_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="props-utilizables-680-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            resultado = subprocess.run(
                [
                    motor,
                    "--headless",
                    "--language",
                    "es",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    "res://pruebas/pruebas_props_utilizables_cc0.gd",
                ],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=120,
                check=False,
            )
            try:
                validar(resultado.stdout, resultado.returncode, 12, False)
            except ValueError as error:
                self.fail(f"{error}\n{resultado.stdout}")

    def test_no_activa_modelos_ausentes(self):
        codigo = (ROOT / "godot/guion/props_utilizables_cc0.gd").read_text(encoding="utf-8")
        self.assertNotIn("load(", codigo)
        self.assertNotIn("preload(", codigo)
        self.assertIn('"Crowbar"', codigo)
        self.assertIn('"Flashlight"', codigo)


if __name__ == "__main__":
    unittest.main()
