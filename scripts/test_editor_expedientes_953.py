"""#953: editor de expedientes QA aislado de los catálogos canónicos."""

from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
EDITOR = ROOT / "godot" / "debug" / "editor_expedientes.gd"
CARGADOR = ROOT / "godot" / "guion" / "cargador_consola_depuracion.gd"
PRESETS = ROOT / "godot" / "export_presets.cfg"


class EditorExpedientes953Test(unittest.TestCase):
    def test_contrato_ejecutable_en_godot(self):
        comprobar_contrato(
            self,
            "pruebas/pruebas_editor_expedientes_953.gd",
            "17 pasadas, 0 fallos",
        )

    def test_el_acceso_es_explicito_y_solo_qa(self):
        cargador = CARGADOR.read_text(encoding="utf-8")
        self.assertIn('OS.get_environment("SIGA98_EDITOR_EXPEDIENTES") == "1"', cargador)
        self.assertIn("OS.is_debug_build()", cargador)
        self.assertIn('OS.has_feature("qa_tools")', cargador)
        self.assertIn('res://debug/editor_expedientes.gd', cargador)
        presets = PRESETS.read_text(encoding="utf-8")
        self.assertGreaterEqual(presets.count('exclude_filter="debug/**"'), 2)

    def test_el_editor_no_escribe_catalogos_canonicos(self):
        editor = EDITOR.read_text(encoding="utf-8")
        self.assertIn('DIRECTORIO := "user://editor_expedientes"', editor)
        self.assertNotIn("res://datos/casos.json", editor)
        self.assertNotIn("res://datos/textos.csv", editor)
        self.assertIn('"formato": FORMATO', editor)
        self.assertIn('"editor_meta":', editor)
        self.assertIn('"contenido_bbcode":', editor)


if __name__ == "__main__":
    unittest.main()
