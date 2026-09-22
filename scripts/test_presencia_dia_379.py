import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


RAIZ = Path(__file__).resolve().parents[1]
ESCENA_DIA = RAIZ / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "pruebas/pruebas_presencia_dia_379.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class PresenciaDia379RuntimeTest(unittest.TestCase):
    """Verifica el wiring opt-in de presencia sobre el trayecto real."""

    def test_dia_monta_controller_de_presencia(self):
        escena = ESCENA_DIA.read_text(encoding="utf-8")
        self.assertIn('path="res://guion/dia_presencia_coop_app.gd"', escena)
        self.assertIn('[node name="PresenciaCoopController" type="Node" parent="."]', escena)

    def test_presencia_trayecto_en_godot_headless(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=60)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 25, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
