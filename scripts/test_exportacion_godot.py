import re
import unittest
from pathlib import Path


RAIZ = Path(__file__).resolve().parents[1]
PRESETS = RAIZ / "godot/export_presets.cfg"
SCRIPT = RAIZ / "dist/exportar-godot-alpha.sh"
WORKFLOW = RAIZ / ".github/workflows/alpha-playtest.yml"


class ExportacionGodotTest(unittest.TestCase):
    def test_hay_dos_presets_release_reproducibles(self):
        texto = PRESETS.read_text(encoding="utf-8")
        self.assertEqual(2, len(re.findall(r"^\[preset\.\d+\]$", texto, re.MULTILINE)))
        self.assertIn('name="Linux x86_64"', texto)
        self.assertIn('platform="Linux/X11"', texto)
        self.assertIn('name="Windows x86_64"', texto)
        self.assertIn('platform="Windows Desktop"', texto)
        self.assertEqual(2, texto.count("binary_format/embed_pck=true"))
        self.assertEqual(2, texto.count("script_export_mode=2"))
        self.assertNotIn("dist/salida/../", texto)

    def test_las_salidas_quedan_bajo_dist_salida(self):
        texto = PRESETS.read_text(encoding="utf-8")
        rutas = re.findall(r'^export_path="([^"]+)"$', texto, re.MULTILINE)
        self.assertEqual(2, len(rutas))
        for ruta in rutas:
            self.assertTrue(ruta.startswith("../dist/salida/"), ruta)

    def test_el_script_exporta_release_y_no_publica(self):
        texto = SCRIPT.read_text(encoding="utf-8")
        self.assertEqual(1, texto.count("--export-release"))
        self.assertIn('exportar "Linux x86_64"', texto)
        self.assertIn('exportar "Windows x86_64"', texto)
        self.assertNotIn("--export-debug", texto)
        self.assertNotIn("butler", texto.lower())
        self.assertNotIn("ITCH", texto)
        self.assertIn(".godot-version", texto)
        self.assertIn("GODOT_BIN", texto)
        self.assertIn("SHA256SUMS", texto)


    def test_alpha_qa_y_release_publicada_tienen_fronteras_distintas(self):
        script = SCRIPT.read_text(encoding="utf-8")
        workflow = WORKFLOW.read_text(encoding="utf-8")
        presets = PRESETS.read_text(encoding="utf-8")

        self.assertIn('QA_TOOLS="${SIGA98_QA_TOOLS:-0}"', script)
        self.assertIn('"qa_tools"', script)
        self.assertIn('"debug/**"', script)
        self.assertIn('qa_tools=$QA_TOOLS', script)
        self.assertIn(
            "SIGA98_QA_TOOLS: ${{ startsWith(github.ref, 'refs/tags/v') && '0' || '1' }}",
            workflow,
        )
        self.assertEqual(2, presets.count('exclude_filter="debug/**"'))
        self.assertEqual(2, presets.count('custom_features=""'))


if __name__ == "__main__":
    unittest.main()
