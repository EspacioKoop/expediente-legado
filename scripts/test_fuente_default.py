import hashlib
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / "godot" / "assets" / "fonts" / "MFBOldstyle-Regular.otf"
PROJECT = ROOT / "godot" / "project.godot"
PROVENANCE = ROOT / "godot" / "assets" / "procedencia.json"


class FuenteDefaultTest(unittest.TestCase):
    def test_la_fuente_empaquetada_tiene_formato_opentype_y_hash_registrado(self):
        self.assertTrue(FONT.read_bytes()[:4] in (b"OTTO", b"\x00\x01\x00\x00"))
        esperado = next(
            item for item in json.loads(PROVENANCE.read_text(encoding="utf-8"))["assets"]
            if item["ruta"] == "fonts/MFBOldstyle-Regular.otf"
        )
        actual = hashlib.sha256(FONT.read_bytes()).hexdigest()
        self.assertEqual(esperado["sha256"], actual)
        self.assertEqual(esperado["licencia"], "CC0-1.0")

    def test_project_fija_la_fuente_de_forma_central(self):
        project = PROJECT.read_text(encoding="utf-8")
        self.assertIn(
            'theme/custom_font="res://assets/fonts/MFBOldstyle-Regular.otf"', project
        )
        self.assertNotIn("ExtResource(\"1_font\")", project)


if __name__ == "__main__":
    unittest.main()
