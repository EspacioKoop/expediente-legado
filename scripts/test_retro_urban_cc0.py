from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MALLA = ROOT / "godot" / "arte" / "retro_urban_awning.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_retro_urban_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
DOCUMENTACION = ROOT / "docs" / "assets" / "retro-urban-kit.md"
FUENTE_SHA256 = "b012c04b39d39a66c7cb45392621d7374f1ff34c6054b4a05bee019abc55b155"


class RetroUrbanCC0Test(unittest.TestCase):
    def test_fija_fuente_licencia_y_hash_en_la_geometria(self) -> None:
        codigo = MALLA.read_text(encoding="utf-8")
        self.assertIn("https://kenney.nl/assets/retro-urban-kit", codigo)
        self.assertIn("CC0-1.0", codigo)
        self.assertIn("detail-awning-small.glb", codigo)
        self.assertIn(FUENTE_SHA256, codigo)

    def test_la_conversion_conserva_una_malla_no_trivial_y_compartida(self) -> None:
        codigo = MALLA.read_text(encoding="utf-8")
        self.assertGreaterEqual(len(re.findall(r"Vector3\(", codigo)), 44)
        self.assertGreaterEqual(len(re.findall(r"Vector3i\(", codigo)), 24)
        self.assertIn("SurfaceTool.new()", codigo)
        self.assertIn("generate_normals()", codigo)
        self.assertIn("Espacio3D.SHADER_PSX", codigo)
        self.assertIn("static var _malla_compartida: ArrayMesh", codigo)
        self.assertIn("_obtener_malla_compartida()", codigo)
        self.assertIn("SHADOW_CASTING_SETTING_OFF", codigo)

    def test_el_dia_conserva_la_raiz_y_activa_retro_urban(self) -> None:
        escena = ESCENA.read_text(encoding="utf-8")
        self.assertIn('path="res://guion/dia_clima_app.gd"', escena)
        self.assertIn('path="res://guion/dia_retro_urban_app.gd"', escena)
        self.assertIn('[node name="RetroUrbanController" type="Node" parent="."]', escena)

    def test_el_controller_solo_monta_dos_instancias_en_el_trayecto(self) -> None:
        codigo = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn('!= "trayecto"', codigo)
        self.assertIn("RetroUrbanAwning.crear", codigo)
        instancias = re.findall(r'^\s*_toldo\(mundo, "ToldoRetroUrban', codigo, re.MULTILINE)
        self.assertEqual(len(instancias), 2)
        self.assertIn("const INSTANCIAS_RETRO_URBAN := 2", codigo)
        self.assertIn("const DRAW_CALLS_BASE_MAX := 2", codigo)
        self.assertNotIn("KEY_E", codigo)
        self.assertNotIn("InputEventKey", codigo)

    def test_el_dressing_no_crea_fisica_ni_colision(self) -> None:
        codigo = MALLA.read_text(encoding="utf-8")
        for token in ("StaticBody3D", "CharacterBody3D", "CollisionShape3D", "create_trimesh_collision"):
            self.assertNotIn(token, codigo)

    def test_documenta_procedencia_presupuesto_y_deuda_restante(self) -> None:
        doc = DOCUMENTACION.read_text(encoding="utf-8")
        self.assertIn("CC0 1.0", doc)
        self.assertIn(FUENTE_SHA256, doc)
        self.assertIn("KoshkiKode/cordite", doc)
        self.assertIn("máximo 2 draw calls", doc)
        self.assertIn("no cierra #295", doc)
        self.assertIn("6–10 piezas", doc)


if __name__ == "__main__":
    unittest.main()
