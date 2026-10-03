"""Conecta la regresión CONTROLADOR de #2145 con la suite CI (#2146)."""
from pathlib import Path
import re
import shutil
import unittest

from scripts.godot_pruebas import ejecutar_script, motor


ROOT = Path(__file__).resolve().parents[1]


class ControladorRuntime2086Test(unittest.TestCase):
    def test_runtime_no_resuelve_host_ni_consecuencias(self):
        fuente = (ROOT / "godot/guion/juicio_combate_controlador_3d.gd").read_text()
        for simbolo in (
            "Partida.",
            "Jornada.",
            "SuenoCombate.",
            "juicio_combate_3d.gd",
            "_aplicar_impacto",
            "_terminar(",
        ):
            self.assertNotIn(simbolo, fuente)

    def test_contrato_headless(self):
        if shutil.which(motor()) is None:
            self.skipTest(f"{motor()} no disponible en este entorno")
        resultado = ejecutar_script("res://pruebas/pruebas_controlador_runtime_2086.gd")
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = re.search(r"controlador_runtime_2086: (\d+) pasadas, 0 fallos", resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 18, resultado.stdout)
        self.assertNotIn("ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
