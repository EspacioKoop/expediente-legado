"""Contrato ejecutable del ciclo guardia/embestida de Gárgola (#2194)."""
from pathlib import Path
import re
import shutil
import unittest

from scripts.godot_pruebas import ejecutar_script, motor


ROOT = Path(__file__).resolve().parents[1]


class GargolaRuntime2092Test(unittest.TestCase):
    def test_runtime_no_resuelve_dano_ni_consecuencias(self):
        fuente = (ROOT / "godot/guion/juicio_combate_gargola_runtime_2092.gd").read_text()
        for simbolo in ("Partida.", "Jornada.", "SuenoCombate.", "_aplicar_impacto", "move_and_collide", "Time."):
            self.assertNotIn(simbolo, fuente)

    def test_contrato_guardia_embestida(self):
        if shutil.which(motor()) is None:
            self.skipTest(f"{motor()} no disponible en este entorno")
        resultado = ejecutar_script("res://pruebas/pruebas_gargola_runtime_2092.gd")
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = re.search(r"(\d+) pasadas, 0 fallos", resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 64, resultado.stdout)
        self.assertNotIn("ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
