"""Fachadas vivas: contrato estático y prueba real en Godot (#861)."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

from verificar_godot import validar


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot/guion"


class FachadasVivasTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fachadas = (GUION / "calle_fachadas_vivas.gd").read_text(encoding="utf-8")
        cls.calle = (GUION / "dia_calle_app.gd").read_text(encoding="utf-8")

    def test_contrato_de_vertical_slice(self):
        self.assertIn("CalleFachadasVivas.montar(calle)", self.calle)
        self.assertIn("const MAX_VENTANAS := 9", self.fachadas)
        self.assertIn('const PREFIJO_TRAMO := "Ventana0_"', self.fachadas)
        for variante in ("escritorio", "estanteria", "salon_tv"):
            self.assertIn(f'"{variante}"', self.fachadas)
        for estado in ("calida", "apagada", "fria_tv", "tenue", "persiana"):
            self.assertIn(f'"{estado}"', self.fachadas)
        for contrato_lod in (
            "LOD_CERCA_FIN := 18.0",
            "LOD_MEDIA_FIN := 36.0",
            "LOD_LEJOS_FIN := 72.0",
        ):
            self.assertIn(contrato_lod, self.fachadas)
        self.assertIn("visibility_range_end = rango_fin", self.fachadas)
        self.assertIn("PROFUNDIDAD_INTERIOR := 0.055", self.fachadas)
        self.assertIn("SALIENTE_EXTRA_CRISTAL := 0.05", self.fachadas)
        self.assertNotIn("no_depth_test", self.fachadas)
        self.assertNotIn("render_priority", self.fachadas)
        self.assertNotIn("load(", self.fachadas)

    def test_fachadas_vivas_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="fachadas-vivas-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            base = [motor, "--headless", "--language", "es", "--path", str(ROOT / "godot")]
            for argumentos, importando in [
                (["--editor", "--import", "--quit"], True),
                (["--script", "res://pruebas/pruebas_fachadas_vivas.gd"], False),
            ]:
                resultado = subprocess.run(
                    base + argumentos,
                    env=entorno,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    timeout=240,
                    check=False,
                )
                try:
                    validar(resultado.stdout, resultado.returncode, None, importando)
                except ValueError as error:
                    self.fail(f"{error}\n{resultado.stdout}")


if __name__ == "__main__":
    unittest.main()
