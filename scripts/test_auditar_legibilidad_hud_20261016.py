#!/usr/bin/env python3
"""Pruebas sintéticas para el auditor estático de legibilidad HUD 1920x1080 (#20261016)."""

from __future__ import annotations

import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from scripts.auditar_legibilidad_hud_20261016 import (
    auditar_archivo,
    auditar_ruta,
    main,
)


class TestAuditarLegibilidadHUD(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self.tmp_dir.name)

    def tearDown(self) -> None:
        self.tmp_dir.cleanup()

    def test_deteccion_tamanio_fuente_pequenio(self) -> None:
        contenido = """[gd_scene format=3]

[node name="HUD" type="Control"]
layout_mode = 3

[node name="EtiquetaPequenia" type="Label" parent="."]
theme_override_font_sizes/font_size = 10
text = "Texto muy pequeño"

[node name="EtiquetaNormal" type="Label" parent="."]
theme_override_font_sizes/font_size = 18
text = "Texto normal"
"""
        file_path = self.tmp_path / "hud_test.tscn"
        file_path.write_text(contenido, encoding="utf-8")

        hallazgos = auditar_archivo(file_path, min_font_size=14)
        hallazgos_font = [
            h for h in hallazgos if h["tipo_hallazgo"] == "tamanio_fuente_pequenio"
        ]

        self.assertEqual(len(hallazgos_font), 1)
        h = hallazgos_font[0]
        self.assertEqual(h["nodo"], "EtiquetaPequenia")
        self.assertEqual(h["tipo_nodo"], "Label")
        self.assertEqual(h["linea"], 7)
        self.assertEqual(h["valor"], 10)
        self.assertIn("10px", h["detalles"])

    def test_deteccion_opacidad_reducida(self) -> None:
        contenido = """[gd_scene format=3]

[node name="HUD" type="Control"]
modulate = Color(1, 1, 1, 0.4)

[node name="BotonSemiTransparente" type="Button" parent="."]
self_modulate = Color(0.8, 0.8, 0.8, 0.5)

[node name="BotonOpaco" type="Button" parent="."]
self_modulate = Color(1, 1, 1, 1.0)
"""
        file_path = self.tmp_path / "opacidad_test.tscn"
        file_path.write_text(contenido, encoding="utf-8")

        hallazgos = auditar_archivo(file_path, min_alpha=1.0)
        hallazgos_opacidad = [
            h for h in hallazgos if h["tipo_hallazgo"] == "opacidad_reducida"
        ]

        self.assertEqual(len(hallazgos_opacidad), 2)
        node_names = [h["nodo"] for h in hallazgos_opacidad]
        self.assertIn("HUD", node_names)
        self.assertIn("BotonSemiTransparente", node_names)
        self.assertNotIn("BotonOpaco", node_names)

        # Verificar trazabilidad de linea
        h_hud = next(h for h in hallazgos_opacidad if h["nodo"] == "HUD")
        self.assertEqual(h_hud["linea"], 4)
        self.assertEqual(h_hud["valor"], 0.4)

    def test_deteccion_theme_override(self) -> None:
        contenido = """[gd_scene format=3]

[node name="HUD" type="Control"]

[node name="TextoPersonalizado" type="Label" parent="."]
theme_override_colors/font_color = Color(1, 0, 0, 1)
theme_override_styles/panel = SubResource("1")
"""
        file_path = self.tmp_path / "theme_test.tscn"
        file_path.write_text(contenido, encoding="utf-8")

        hallazgos = auditar_archivo(file_path)
        hallazgos_theme = [
            h for h in hallazgos if h["tipo_hallazgo"] == "theme_override"
        ]

        self.assertEqual(len(hallazgos_theme), 2)
        props = [h["propiedad"] for h in hallazgos_theme]
        self.assertIn("theme_override_colors/font_color", props)
        self.assertIn("theme_override_styles/panel", props)

    def test_auditar_recurso_tres(self) -> None:
        contenido = """[gd_resource type="LabelSettings" format=3]

[resource]
font_size = 11
font_color = Color(1, 1, 1, 0.6)
"""
        file_path = self.tmp_path / "estilo.tres"
        file_path.write_text(contenido, encoding="utf-8")

        hallazgos = auditar_archivo(file_path, min_font_size=14, min_alpha=1.0)
        tipos = [h["tipo_hallazgo"] for h in hallazgos]

        self.assertIn("tamanio_fuente_pequenio", tipos)
        self.assertIn("opacidad_reducida", tipos)

        h_font = next(h for h in hallazgos if h["tipo_hallazgo"] == "tamanio_fuente_pequenio")
        self.assertEqual(h_font["nodo"], "resource")
        self.assertEqual(h_font["tipo_nodo"], "Resource")
        self.assertEqual(h_font["linea"], 4)

    def test_auditar_directorio_y_json(self) -> None:
        (self.tmp_path / "escena1.tscn").write_text(
            '[node name="A" type="Label"]\nfont_size = 8\n', encoding="utf-8"
        )
        (self.tmp_path / "escena2.tres").write_text(
            '[resource]\nfont_size = 20\n', encoding="utf-8"
        )

        reporte = auditar_ruta(self.tmp_path, min_font_size=14)
        self.assertEqual(reporte["resolucion_objetivo"], "1920x1080")
        self.assertEqual(reporte["total_archivos"], 2)
        self.assertEqual(reporte["total_hallazgos"], 1)

        hallazgo = reporte["hallazgos"][0]
        self.assertEqual(hallazgo["valor"], 8)
        self.assertEqual(hallazgo["nodo"], "A")
        self.assertEqual(hallazgo["linea"], 2)

    def test_cli_main_y_fail_on_findings(self) -> None:
        file_path = self.tmp_path / "test.tscn"
        file_path.write_text('[node name="X" type="Label"]\nfont_size = 9\n', encoding="utf-8")
        out_json = self.tmp_path / "reporte.json"

        with patch("sys.stdout", new_callable=io.StringIO):
            ret = main(
                [
                    "--path",
                    str(file_path),
                    "--json-out",
                    str(out_json),
                    "--min-font-size",
                    "14",
                    "--fail-on-findings",
                ]
            )

        self.assertEqual(ret, 2)
        self.assertTrue(out_json.exists())

        datos = json.loads(out_json.read_text(encoding="utf-8"))
        self.assertEqual(datos["total_hallazgos"], 1)
        self.assertEqual(datos["hallazgos"][0]["nodo"], "X")


if __name__ == "__main__":
    unittest.main()
