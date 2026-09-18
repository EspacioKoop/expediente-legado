from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs" / "assets" / "industrial-pack.manifest.json"
INDUSTRIAL = ROOT / "godot" / "arte" / "industrial_cc0.gd"
GITATTRIBUTES = ROOT / ".gitattributes"

EXPECTED_ARCHIVE_SHA256 = (
    "48821008e7c2e62cd8b7050d57fd372e2aeae038987fe1dd249ae2e0ef33af78"
)
EXPECTED_RUNTIME = {
    "CableDrum",
    "ElectricalBox",
    "Platform_Trolley",
    "WorkLight",
}


class IndustrialPackManifestTest(unittest.TestCase):
    def setUp(self) -> None:
        self.data = json.loads(MANIFEST.read_text(encoding="utf-8"))

    def test_fija_fuente_licencia_y_hash_del_rar_aportado(self) -> None:
        source = self.data["source"]
        self.assertEqual(source["license"], "CC0-1.0 / public domain")
        self.assertEqual(source["provided_archive"], "IndustrialPack.rar")
        self.assertEqual(source["archive_sha256"], EXPECTED_ARCHIVE_SHA256)
        self.assertEqual(source["archive_size_bytes"], 67_986_593)

    def test_inventario_corresponde_al_pack_aportado(self) -> None:
        inventory = self.data["inventory"]
        self.assertEqual(inventory["asset_count"], 12)
        self.assertEqual(inventory["file_count"], 68)
        self.assertEqual(inventory["fbx_count"], 12)
        self.assertEqual(inventory["png_count"], 56)

        assets = self.data["assets"]
        ids = {asset["id"] for asset in assets}
        self.assertEqual(len(assets), 12)
        self.assertEqual(len(ids), 12)
        for asset in assets:
            self.assertTrue(asset["fbx"].endswith(".fbx"))
            self.assertGreater(asset["fbx_size_bytes"], 0)
            self.assertRegex(asset["fbx_crc32"], r"^[0-9a-f]{8}$")
            self.assertIn("base_color", asset["maps"])
            self.assertIn("metallic", asset["maps"])
            self.assertIn("roughness", asset["maps"])

    def test_seleccion_runtime_es_subconjunto_pequeno_del_catalogo(self) -> None:
        assets = {asset["id"] for asset in self.data["assets"]}
        runtime = set(self.data["runtime_selection"])
        self.assertEqual(runtime, EXPECTED_RUNTIME)
        self.assertLess(len(runtime), len(assets))
        self.assertTrue(runtime <= assets)

        texto = INDUSTRIAL.read_text(encoding="utf-8")
        for referencia in ("Cable Drum", "Electrical Box", "Platform Trolley"):
            self.assertIn(referencia, texto)
        self.assertIn("Work Light Small", texto)

    def test_no_versiona_el_rar_y_binarios_futuros_quedan_en_lfs(self) -> None:
        policy = self.data["policy"]
        self.assertFalse(policy["archive_vendored"])
        self.assertFalse(policy["source_binaries_imported_by_this_change"])
        self.assertFalse((ROOT / "IndustrialPack.rar").exists())

        attributes = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("*.fbx   filter=lfs", attributes)
        self.assertIn("*.png   filter=lfs", attributes)


if __name__ == "__main__":
    unittest.main()
