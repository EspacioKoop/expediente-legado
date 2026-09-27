import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
ESCENA_DIA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "pruebas/pruebas_ghosts_runtime_376.gd"
RESUMEN_GODOT = re.compile(r"Ghosts runtime #376: (\d+) pasadas, 0 fallos")


class GhostsRuntime376Test(unittest.TestCase):
    """Ejecuta el runtime asíncrono y comprueba su montaje en Dia."""

    def test_dia_monta_controller_de_ghosts(self):
        escena = ESCENA_DIA.read_text(encoding="utf-8")
        self.assertIn('path="res://guion/dia_ghosts_app.gd"', escena)
        self.assertIn(
            '[node name="GhostsAsincronosController" type="Node" parent="."]',
            escena,
        )

    def test_ghosts_runtime_en_godot_headless(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=90)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 18, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
