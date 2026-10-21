"""Tests sintéticos, offline, del auditor de traducciones de Godot."""
import importlib.util
import tempfile
import unittest
from pathlib import Path

MODULE = Path(__file__).with_name("auditar_localizacion_20261016.py")
spec = importlib.util.spec_from_file_location("auditor_localizacion", MODULE)
auditor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(auditor)


class AuditorLocalizacionTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        (self.root / "godot" / "datos").mkdir(parents=True)
        (self.root / "godot" / "guion").mkdir()

    def put(self, path, content):
        file = self.root / "godot" / path
        file.write_text(content, encoding="utf-8")
        return file

    def findings(self):
        return auditor.scan(self.root)["findings"]

    def test_duplicates_and_empty_translations_have_lines(self):
        self.put("datos/textos.csv", "clave,es\nSALUDO,Hola\nSALUDO,Otro\nVACIO,\n")
        actual = {(f["code"], f["line"]) for f in self.findings()}
        self.assertIn(("duplicate_key", 3), actual)
        self.assertIn(("empty_translation", 4), actual)

    def test_missing_literal_and_dynamic_ambiguity(self):
        self.put("datos/textos.csv", "clave,es\nSALUDO,Hola\n")
        self.put("guion/ejemplo.gd",
                 'tr("SALUDO")\ntr("FALTA")\nTranslationServer.translate(variable)\n# tr("COMENTADA")\n')
        errors = [f for f in self.findings() if f["code"] == "missing_key"]
        self.assertEqual([f["detail"] for f in errors], ["FALTA"])
        dynamic = [f for f in self.findings() if f["code"] == "dynamic_key"]
        self.assertEqual([f["severity"] for f in dynamic], ["info"])

    def test_imported_translations_do_not_need_versioned_binary(self):
        self.put("datos/textos.csv", "clave,es\nSALUDO,Hola\n")
        self.put("datos/textos.csv.import",
                 '[deps]\nsource_file="res://datos/textos.csv"\n'
                 'dest_files=["res://datos/textos.es.translation"]\n')
        self.put("project.godot",
                 'locale/translations=PackedStringArray("res://datos/textos.es.translation")\n')
        self.assertNotIn("unresolvable_translation",
                         [f["code"] for f in self.findings()])

    def test_broken_import_metadata_is_reported(self):
        self.put("datos/textos.csv", "clave,es\nSALUDO,Hola\n")
        self.put("project.godot",
                 'locale/translations=PackedStringArray("res://datos/textos.es.translation")\n')
        self.assertIn("unresolvable_translation",
                      [f["code"] for f in self.findings()])

    def test_other_csv_files_are_not_catalogues(self):
        self.put("datos/textos.csv", "clave,es\nSALUDO,Hola\n")
        self.put("datos/casos.csv", "id,estado\n1,abierto\n")
        self.assertEqual(auditor.scan(self.root)["stats"]["catalogs"], 1)
        self.assertNotIn("csv_header", [f["code"] for f in self.findings()])

    def test_determinism_and_symlink_escape(self):
        self.put("datos/textos.csv", "clave,es\nSALUDO,Hola\n")
        outside = Path(self.root).parent / ("auditor_escape_" + self.root.name)
        self.addCleanup(lambda: outside.unlink(missing_ok=True))
        outside.write_text('tr("NO_FUGA")', encoding="utf-8")
        (self.root / "godot" / "guion" / "externo.gd").symlink_to(outside)
        self.assertEqual(auditor.scan(self.root), auditor.scan(self.root))
        self.assertNotIn("NO_FUGA", str(self.findings()))


if __name__ == "__main__":
    unittest.main()
