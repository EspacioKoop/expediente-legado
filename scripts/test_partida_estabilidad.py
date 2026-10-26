"""Estabilidad del guardado/carga completo de Partida (#2739)."""
from pathlib import Path
import re
import unittest

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
PARTIDA = ROOT / "godot" / "guion" / "partida.gd"


class PartidaEstabilidadTest(unittest.TestCase):
    def test_contrato_ejecutable_en_godot(self):
        resultado = ejecutar_script("res://pruebas/pruebas_partida_estabilidad.gd")
        resumen = re.search(r"(\d+) pasadas, (\d+) fallos", resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertEqual(int(resumen.group(2)), 0, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 6, resultado.stdout)

    def test_el_nucleo_sigue_siendo_atomico_y_no_pisa_corruptas(self):
        fuente = PARTIDA.read_text(encoding="utf-8")
        self.assertIn('".nuevo"', fuente)
        self.assertIn("DirAccess.rename_absolute", fuente)
        self.assertIn('".roto"', fuente)


if __name__ == "__main__":
    unittest.main()
