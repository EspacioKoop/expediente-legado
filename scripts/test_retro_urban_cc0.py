from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MALLA = ROOT / "godot" / "arte" / "retro_urban_awning.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_retro_urban_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class RetroUrbanCC0Test(unittest.TestCase):
    def test_fija_fuente_y_licencia_cc0_en_la_geometria(self) -> None:
        codigo = MALLA.read_text(encoding="utf-8")
        self.assertIn("https://kenney.nl/assets/retro-urban-kit", codigo)
        self.assertIn("CC0-1.0", codigo)
        self.assertIn("detail-awning-small.glb", codigo)

    def test_la_conversion_conserva_una_malla_no_trivial(self) -> None:
        codigo = MALLA.read_text(encoding="utf-8")
        self.assertGreaterEqual(len(re.findall(r"Vector3\(", codigo)), 44)
        self.assertGreaterEqual(len(re.findall(r"Vector3i\(", codigo)), 24)
        self.assertIn("SurfaceTool.new()", codigo)
        self.assertIn("generate_normals()", codigo)
        self.assertIn("Espacio3D.SHADER_PSX", codigo)

    def test_el_dia_conserva_la_raiz_y_activa_retro_urban(self) -> None:
        escena = ESCENA.read_text(encoding="utf-8")
        self.assertIn('path="res://guion/dia_clima_app.gd"', escena)
        self.assertIn('path="res://guion/dia_retro_urban_app.gd"', escena)
        self.assertIn('[node name="RetroUrbanController" type="Node" parent="."]', escena)

    def test_el_controller_solo_monta_en_el_trayecto(self) -> None:
        codigo = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn('!= "trayecto"', codigo)
        self.assertIn("RetroUrbanAwning.crear", codigo)
        self.assertGreaterEqual(codigo.count("_toldo(mundo"), 3)
        self.assertNotIn("KEY_E", codigo)
        self.assertNotIn("InputEventKey", codigo)


if __name__ == "__main__":
    unittest.main()
