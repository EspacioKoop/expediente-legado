import json
import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "godot" / "guion" / "red" / "minijuego_sala_panel.gd"
TEXTOS = ROOT / "godot" / "datos" / "minijuego_sala_textos.json"
PRUEBA_GODOT = "pruebas/pruebas_minijuego_sala_383.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class MinijuegoSala383Test(unittest.TestCase):
    def test_copy_visible_vive_fuera_del_gdscript(self):
        source = PANEL.read_text(encoding="utf-8")
        textos = json.loads(TEXTOS.read_text(encoding="utf-8"))
        self.assertNotIn('text = "Crear sala"', source)
        self.assertNotIn('text = "Unirse"', source)
        self.assertEqual(textos["crear"], "Crear sala")
        self.assertIn("sin recompensas de campaña", textos["reglas"])

    def test_panel_en_godot_headless(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=60)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
