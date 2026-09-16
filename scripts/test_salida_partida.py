from pathlib import Path
import unittest

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
SALIDA = ROOT / "godot" / "guion" / "salida_partida.gd"


class SalidaPartidaTest(unittest.TestCase):
    def test_contrato_ejecutable_en_godot(self):
        resultado = ejecutar_script("res://pruebas/pruebas_salida_partida.gd")
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("11 pasadas, 0 fallos", resultado.stdout)
        self.assertIn("No se pudo escribir", resultado.stdout)

    def test_el_nucleo_no_decide_navegacion(self):
        fuente = SALIDA.read_text(encoding="utf-8")
        self.assertIn("partida.guardar(ruta)", fuente)
        self.assertNotIn("change_scene", fuente)
        self.assertNotIn("get_tree().quit", fuente)


if __name__ == "__main__":
    unittest.main()
