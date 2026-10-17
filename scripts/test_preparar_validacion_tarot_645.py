from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from scripts.preparar_validacion_tarot_645 import preparar


class TestPrepararValidacionTarot645(unittest.TestCase):
    def test_preparar_dry_run_genera_manifiesto_y_hoja_revision(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            destino = Path(tmpdir) / "salida"
            godot = "/usr/bin/godot_ficticio"

            manifiesto = preparar(destino, godot, ejecutar=False)

            self.assertEqual(manifiesto["issue"], 645)
            self.assertEqual(manifiesto["total"], 26)
            self.assertEqual(manifiesto["esperadas"], 26)
            self.assertEqual(len(manifiesto["entradas"]), 26)

            manifest_file = destino / "manifest.json"
            self.assertTrue(manifest_file.is_file())
            manifest_data = json.loads(manifest_file.read_text(encoding="utf-8"))
            self.assertEqual(manifest_data["issue"], 645)
            self.assertEqual(manifest_data["total"], 26)
            self.assertEqual(manifest_data["esperadas"], 26)

            revision_file = destino / "revision-humana.md"
            self.assertTrue(revision_file.is_file())
            content_md = revision_file.read_text(encoding="utf-8")
            self.assertIn("# Revisión humana Tarot #645", content_md)
            self.assertIn("el-mago — progresión real", content_md)

    def test_preparar_entradas_estructuras_y_comandos(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            destino = Path(tmpdir) / "salida"
            godot = "/usr/bin/godot_ficticio"

            manifiesto = preparar(destino, godot, ejecutar=False)
            entradas = manifiesto["entradas"]

            ocultas = [e for e in entradas if e["tipo"] == "oculta"]
            progreso = [e for e in entradas if e["tipo"] == "progreso"]

            self.assertEqual(len(ocultas), 24)
            self.assertEqual(len(progreso), 2)

            for e in entradas:
                self.assertIsNone(e["ok"])
                self.assertTrue(e["captura"].endswith(".png"))
                self.assertIn(godot, e["comando"])

            primera_oculta = ocultas[0]
            self.assertEqual(primera_oculta["folio"], "ACTA-1999-014")
            self.assertEqual(primera_oculta["carta"], "la-justicia")
            self.assertEqual(primera_oculta["recorrido"], "normal")
            self.assertEqual(primera_oculta["plano"], 2)
            self.assertEqual(primera_oculta["modo"], "normal")

            primer_progreso = progreso[0]
            self.assertIsNone(primer_progreso["folio"])
            self.assertEqual(primer_progreso["carta"], "el-mago")
            self.assertEqual(primer_progreso["recorrido"], "normal")

    def test_preparar_crea_directorio_destino_si_no_existe(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            destino = Path(tmpdir) / "profundo" / "subdirectorio" / "salida"
            self.assertFalse(destino.exists())

            preparar(destino, "godot_ficticio", ejecutar=False)

            self.assertTrue(destino.is_dir())
            self.assertTrue((destino / "manifest.json").is_file())
            self.assertTrue((destino / "revision-humana.md").is_file())


if __name__ == "__main__":
    unittest.main()
