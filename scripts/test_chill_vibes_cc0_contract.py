import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / "docs" / "assets" / "chill-vibes-art-jam-4.md"
MANIFEST = ROOT / "docs" / "assets" / "chill-vibes-art-jam-4.manifest.json"
IMPORTER = ROOT / "scripts" / "preparar_chill_vibes_cc0.py"
GITATTRIBUTES = ROOT / ".gitattributes"


class TestChillVibesCc0Contract(unittest.TestCase):
    def test_fuente_licencia_y_revision_real_quedan_fijadas(self):
        texto = DOC.read_text(encoding="utf-8")
        datos = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(datos["fuente"], "https://psychic-magpie.itch.io/chill-vibes-art-jam-4")
        self.assertEqual(datos["autor"], "psychic_magpie")
        self.assertEqual(datos["licencia"], "CC0-1.0")
        self.assertEqual(datos["archivo_ficheros"], 79)
        self.assertEqual(datos["glb_totales"], 28)
        self.assertEqual(datos["familias_3d"], 15)
        self.assertRegex(datos["archivo_sha256"], r"^[0-9a-f]{64}$")
        self.assertIn("página de itch todavía enumera solo", texto)
        self.assertIn("README interno", texto)

    def test_primer_lote_es_pequeno_pasivo_y_sin_objetos_semanticos(self):
        datos = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(
            datos["lotes"]["dressing_servicio"],
            ["pallet", "crate", "barrel", "cinder_block", "concrete_barrier", "traffic_cone"],
        )
        ids = set(datos["lotes"]["dressing_servicio"])
        self.assertFalse(ids & {"radio", "lever", "button", "flashlight", "crowbar"})
        self.assertLessEqual(len(ids), 6)

    def test_interactivos_potenciales_quedan_separados(self):
        datos = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(
            datos["lotes"]["interactivos_potenciales"],
            ["radio", "lever", "button", "flashlight", "crowbar"],
        )
        por_id = {asset["id"]: asset for asset in datos["assets"]}
        self.assertEqual(por_id["radio"]["morph_targets"], 18)
        self.assertEqual(por_id["lever"]["nodos"], 2)
        self.assertEqual(por_id["button"]["morph_targets"], 2)
        self.assertEqual(por_id["flashlight"]["morph_targets"], 6)

    def test_assets_auditados_tienen_hash_tamano_y_medidas(self):
        datos = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(len(datos["assets"]), 15)
        for asset in datos["assets"]:
            self.assertRegex(asset["sha256"], r"^[0-9a-f]{64}$")
            self.assertGreater(asset["bytes"], 0)
            self.assertGreater(asset["vertices_auditados"], 0)
            self.assertGreater(asset["triangulos_auditados"], 0)
            self.assertEqual(len(asset["extents_crudos"]), 3)
            self.assertTrue(asset["miembro_extraido"].endswith(".glb"))

    def test_importador_no_escribe_runtime_ni_fabrica_lfs(self):
        texto = IMPORTER.read_text(encoding="utf-8")
        self.assertIn("no escribe en ``godot/assets``", texto)
        self.assertIn("no crea punteros LFS", texto)
        self.assertIn("dist", texto)
        self.assertNotIn("subprocess", texto)

    def test_glb_esta_cubierto_por_lfs(self):
        atributos = GITATTRIBUTES.read_text(encoding="utf-8")
        self.assertIn("*.glb   filter=lfs", atributos)

    def test_documenta_gate_p0_y_composicion_funcional(self):
        texto = DOC.read_text(encoding="utf-8")
        self.assertIn("#181 sigue priorizando", texto)
        self.assertIn("Git LFS real", texto)
        self.assertIn("godot/assets/procedencia.json", texto)
        self.assertIn("composición funcional", texto)


if __name__ == "__main__":
    unittest.main()
