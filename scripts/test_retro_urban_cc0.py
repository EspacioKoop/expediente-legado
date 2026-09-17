from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MALLA = ROOT / "godot" / "arte" / "retro_urban_awning.gd"
MALLA_BANCO = ROOT / "godot" / "arte" / "retro_urban_bench.gd"
MALLA_FAROLA = ROOT / "godot" / "arte" / "retro_urban_lamp.gd"
MALLA_BARRERA = ROOT / "godot" / "arte" / "retro_urban_barrier.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_retro_urban_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
DOCUMENTACION = ROOT / "docs" / "assets" / "retro-urban-kit.md"
FUENTE_SHA256 = "b012c04b39d39a66c7cb45392621d7374f1ff34c6054b4a05bee019abc55b155"

PIEZAS = {
    MALLA: ("detail-awning-small.glb", "b012c04b39d39a66c7cb45392621d7374f1ff34c6054b4a05bee019abc55b155"),
    MALLA_BANCO: ("detail-bench.glb", "ccf6f0a95b04db1720c9a7040404ca0d676a0f850815aee90de5edc33b96c47c"),
    MALLA_FAROLA: ("detail-light-single.glb", "aac24987fa7651f8e892f4e661b3bb67c6866edb726e0ab092e9c747f0a69151"),
    MALLA_BARRERA: ("detail-barrier-type-a.glb", "8ad30f159654cccd2cb176b84852275c375a2d4cb868b6969b184474d3d765ef"),
}


class RetroUrbanCC0Test(unittest.TestCase):
    def test_fija_fuente_licencia_y_hash_en_cada_pieza(self) -> None:
        for ruta, (glb, sha) in PIEZAS.items():
            codigo = ruta.read_text(encoding="utf-8")
            self.assertIn("https://kenney.nl/assets/retro-urban-kit", codigo)
            self.assertIn("CC0-1.0", codigo)
            self.assertIn(glb, codigo)
            self.assertIn(sha, codigo)

    def test_la_conversion_conserva_una_malla_no_trivial_y_compartida(self) -> None:
        for ruta in PIEZAS:
            codigo = ruta.read_text(encoding="utf-8")
            self.assertGreaterEqual(len(re.findall(r"Vector3\(", codigo)), 8)
            self.assertGreaterEqual(len(re.findall(r"Vector3i\(", codigo)), 4)
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

    def test_el_controller_monta_ocho_instancias_en_el_trayecto(self) -> None:
        codigo = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn('!= "trayecto"', codigo)
        self.assertIn("RetroUrbanAwning.crear", codigo)
        self.assertIn("RetroUrbanBench.crear", codigo)
        self.assertIn("RetroUrbanLamp.crear", codigo)
        self.assertIn("RetroUrbanBarrier.crear", codigo)
        toldos = re.findall(r'^\s*_toldo\(mundo, "ToldoRetroUrban', codigo, re.MULTILINE)
        farolas = re.findall(r'^\s*_farola\(mundo, "FarolaRetroUrban', codigo, re.MULTILINE)
        barreras = re.findall(r'^\s*_barrera\(mundo, "BarreraRetroUrban', codigo, re.MULTILINE)
        self.assertEqual(len(toldos), 2)
        self.assertEqual(len(farolas), 2)
        self.assertEqual(len(barreras), 3)
        self.assertIn("BancoRetroUrban", codigo)
        self.assertIn("const INSTANCIAS_RETRO_URBAN := 8", codigo)
        self.assertIn("const DRAW_CALLS_BASE_MAX := 8", codigo)
        self.assertNotIn("KEY_E", codigo)
        self.assertNotIn("InputEventKey", codigo)
        self.assertNotIn("CalleMateriales.montar", codigo)

    def test_el_dressing_no_crea_fisica_ni_colision(self) -> None:
        for ruta in PIEZAS:
            codigo = ruta.read_text(encoding="utf-8")
            for token in ("StaticBody3D", "CharacterBody3D", "CollisionShape3D", "create_trimesh_collision"):
                self.assertNotIn(token, codigo)

    def test_documenta_procedencia_presupuesto_y_deuda_restante(self) -> None:
        doc = DOCUMENTACION.read_text(encoding="utf-8")
        self.assertIn("CC0 1.0", doc)
        self.assertIn(FUENTE_SHA256, doc)
        self.assertIn("KoshkiKode/cordite", doc)
        self.assertIn("máximo 8 draw calls", doc)
        self.assertIn("4 piezas fuente", doc)
        self.assertIn("6–10 piezas", doc)
        self.assertIn("retro_urban-summary.json", doc)
        for _, (glb, sha) in PIEZAS.items():
            if glb == "detail-awning-small.glb":
                continue
            self.assertIn(glb, doc)
            self.assertIn(sha, doc)


if __name__ == "__main__":
    unittest.main()
