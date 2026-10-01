#!/usr/bin/env python3
"""Regresión del pack GBC textual de MYRMIDON 98 (#1804)."""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
MODULO = ROOT / "gbc/minijuegos/aquiles_98/generar_arte_v1.py"
ASSETS = ROOT / "gbc/minijuegos/aquiles_98/assets"


def cargar_generador():
    spec = importlib.util.spec_from_file_location("myrmidon_arte_v1", MODULO)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class MyrmidonAssets1804Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gen = cargar_generador()
        cls.manifest = json.loads((ASSETS / "myrmidon_v1_manifest.json").read_text(encoding="utf-8"))

    def test_generados_estan_sincronizados(self):
        proc = subprocess.run(
            [sys.executable, str(MODULO), "--check"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)

    def test_seis_estados_dos_frames_y_grid(self):
        sprite = self.manifest["sprite"]
        self.assertEqual(sprite["grid"], [8, 8])
        self.assertEqual(sprite["frame_px"], [24, 32])
        self.assertEqual(
            sprite["states"],
            ["idle", "advance", "attack", "block", "vulnerable", "defeat"],
        )
        self.assertEqual(sprite["frames_per_state"], 2)
        self.assertEqual(sprite["tiles_per_frame"], 12)
        for estado, frames in sprite["frame_maps"].items():
            self.assertEqual(len(frames), 2, estado)
            for frame in frames:
                self.assertEqual(len(frame), 12, estado)
                self.assertTrue(all(0 <= i < sprite["unique_obj_tiles"] for i in frame))

    def test_presupuesto_de_tiles_deja_margen(self):
        p = self.manifest["presupuesto"]
        self.assertLessEqual(p["obj_tiles_actual"], p["obj_tiles_max"])
        self.assertLessEqual(p["bg_tiles_actual"], p["bg_tiles_max"])
        self.assertLessEqual(p["hud_tiles_actual"], p["hud_tiles_max"])
        self.assertLessEqual(p["obj_tiles_actual"], 64)
        self.assertLessEqual(p["bg_tiles_actual"], 16)

    def test_ocho_paletas_de_cuatro_colores(self):
        p = self.manifest["paletas"]
        self.assertEqual(p, {"bg": 4, "colores_por_paleta": 4, "obj": 4, "total": 8})
        texto = (ASSETS / "myrmidon_v1_palettes.inc").read_text(encoding="utf-8")
        self.assertEqual(texto.count("MyrmidonPal_"), 8)
        self.assertEqual(texto.count("    dw "), 8)

    def test_vulnerabilidad_cambia_silueta_y_hud_permanece_separado(self):
        idle = self.gen.frame_pixels("idle", 0)
        vul = self.gen.frame_pixels("vulnerable", 0)
        ocup_idle = {(x, y) for y, row in enumerate(idle) for x, px in enumerate(row) if px}
        ocup_vul = {(x, y) for y, row in enumerate(vul) for x, px in enumerate(row) if px}
        self.assertGreater(len(ocup_idle.symmetric_difference(ocup_vul)), 24)
        talon_idle = sum(1 for x, y in ocup_idle if x >= 15 and y >= 24)
        talon_vul = sum(1 for x, y in ocup_vul if x >= 15 and y >= 24)
        self.assertGreater(talon_vul, talon_idle)
        self.assertNotIn("talon", self.manifest["hud"]["base"])
        self.assertEqual(self.manifest["hud"]["revealed_only"], ["talon"])
        tiles = (ASSETS / "myrmidon_v1_tiles.inc").read_text(encoding="utf-8")
        self.assertLess(tiles.index("MyrmidonHudBase::"), tiles.index("MyrmidonHudRevealed::"))
        self.assertLess(tiles.index("MyrmidonHudRevealed::"), tiles.index("MyrmidonHud_talon::"))

    def test_previews_son_160x144_y_no_revelan_talon_antes_de_tiempo(self):
        with tempfile.TemporaryDirectory() as tmp:
            proc = subprocess.run(
                [sys.executable, str(MODULO), "--check", "--preview-dir", tmp],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
            normal = Path(tmp) / "myrmidon_v1_preview_normal.svg"
            vulnerable = Path(tmp) / "myrmidon_v1_preview_vulnerable.svg"
            for ruta in (normal, vulnerable):
                root = ET.parse(ruta).getroot()
                self.assertEqual(root.attrib["width"], "160")
                self.assertEqual(root.attrib["height"], "144")
                self.assertEqual(root.attrib["viewBox"], "0 0 160 144")
            texto_normal = normal.read_text(encoding="utf-8").lower()
            texto_vulnerable = vulnerable.read_text(encoding="utf-8").lower()
            self.assertNotIn("#f5df79", texto_normal)
            self.assertIn("#f5df79", texto_vulnerable)

    def test_fuentes_canónicas_quedan_trazadas(self):
        fuentes = {x["ruta"]: x["git_blob_sha"] for x in self.manifest["fuentes_visuales"]}
        self.assertIn("godot/arte/aquiles/aquiles_atlas_referencia.jpg", fuentes)
        self.assertIn("godot/arte/aquiles/aquiles_entorno_referencia.jpg", fuentes)
        self.assertTrue(all(len(sha) == 40 for sha in fuentes.values()))


if __name__ == "__main__":
    unittest.main()
