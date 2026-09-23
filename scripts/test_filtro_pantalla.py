"""Filtro de pantalla de época opcional (#1270).

La prueba de verdad es la de Godot (preferencia, preajustes, compositor montado
en el día y en el plató, shaders que compilan). Aquí se fija lo que un cambio
posterior podría romper sin que Godot lo note: la frontera de #115 y la
atribución MIT del código adaptado.
"""

import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script

ROOT = Path(__file__).resolve().parents[1]
SHADER = ROOT / "godot" / "arte" / "pantalla_98.glsl"
EFECTO = ROOT / "godot" / "guion" / "efecto_pantalla_98.gd"
FILTRO = ROOT / "godot" / "guion" / "filtro_pantalla.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_filtro_pantalla.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class FiltroPantallaTest(unittest.TestCase):
    def test_es_un_efecto_de_compositor_y_no_una_capa_2d(self):
        # Un ColorRect o un canvas_item a pantalla completa filtraría también el
        # visor y el HUD, que es justo lo que #115 prohíbe.
        for ruta in (EFECTO, FILTRO):
            codigo = ruta.read_text(encoding="utf-8")
            self.assertNotIn("canvas_item", codigo)
            self.assertNotIn("ColorRect", codigo)
            self.assertNotIn("CanvasLayer", codigo)
        self.assertIn("extends CompositorEffect", EFECTO.read_text(encoding="utf-8"))

    def test_conserva_la_atribucion_mit_de_kinotube(self):
        shader = SHADER.read_text(encoding="utf-8")
        self.assertIn("Copyright (c) 2017 Keijiro Takahashi", shader)
        self.assertIn("MIT License", shader)
        self.assertIn("https://github.com/keijiro/KinoTube", shader)

    def test_flujo_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 60, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
