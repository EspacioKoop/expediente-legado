from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDUSTRIAL = ROOT / "godot" / "arte" / "industrial_cc0.gd"
DRESSING = ROOT / "godot" / "guion" / "dia_dressing_cc0_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class IndustrialCC0Test(unittest.TestCase):
    def setUp(self) -> None:
        self.industrial = INDUSTRIAL.read_text(encoding="utf-8")
        self.dressing = DRESSING.read_text(encoding="utf-8")

    def test_fija_fuente_licencia_y_seleccion_pequena(self) -> None:
        self.assertIn(
            "https://3dmodelscc0.itch.io/free-cc0-industrial-3d-models",
            self.industrial,
        )
        self.assertIn("CC0-1.0", self.industrial)
        for referencia in (
            "Cable Drum",
            "Electrical Box",
            "Platform Trolley",
            "Work Light Small",
        ):
            self.assertIn(referencia, self.industrial)

    def test_adaptacion_es_textual_psx_y_low_poly(self) -> None:
        self.assertIn("Espacio3D.SHADER_PSX", self.industrial)
        self.assertIn("BoxMesh.new()", self.industrial)
        self.assertIn("CylinderMesh.new()", self.industrial)
        self.assertIn("radial_segments = 10", self.industrial)
        self.assertNotIn('load("res://assets/', self.industrial)
        self.assertNotIn("preload(", self.industrial)

    def test_dressing_industrial_no_es_gameplay(self) -> None:
        for termino in (
            "StaticBody3D",
            "CollisionShape3D",
            "Area3D",
            "Interactuable3D",
            "OmniLight3D",
            "DirectionalLight3D",
        ):
            self.assertNotIn(termino, self.industrial)
        for termino in ("Jornada.", "partida.estado", "dinero", "pistas_descubiertas"):
            self.assertNotIn(termino, self.industrial)

    def test_se_monta_solo_como_zona_secundaria_del_trayecto(self) -> None:
        self.assertIn("_zona_servicio_industrial_cc0(mundo)", self.dressing)
        self.assertIn("IndustrialCC0.crear_zona_servicio()", self.dressing)
        self.assertIn('zona.name = "ZonaServicioIndustrialCC0"', self.dressing)
        self.assertIn("Vector3(6.05, 0.14, -0.40)", self.dressing)
        self.assertIn("zona.rotation_degrees.y = -90.0", self.dressing)
        self.assertIn("zona.scale = Vector3.ONE * 0.90", self.dressing)

    def test_no_necesita_tocar_la_escena_ni_el_pack_completo(self) -> None:
        escena = ESCENA.read_text(encoding="utf-8")
        self.assertIn('path="res://guion/dia_dressing_cc0_app.gd"', escena)
        self.assertNotIn("industrial_cc0.gd", escena)
        self.assertNotIn("IndustrialPack.rar", escena)
        self.assertNotIn("IndustrialPack.rar", self.dressing)


if __name__ == "__main__":
    unittest.main()
