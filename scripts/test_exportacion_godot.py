import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


RAIZ = Path(__file__).resolve().parents[1]
PRESETS = RAIZ / "godot/export_presets.cfg"
SCRIPT = RAIZ / "dist/exportar-godot-alpha.sh"
WORKFLOW = RAIZ / ".github/workflows/alpha-playtest.yml"
AUDITOR = RAIZ / "scripts/auditar_frontera_qa.py"
MARCADOR_QA = RAIZ / "godot/debug/qa_export_marker_116.tres"


class ExportacionGodotTest(unittest.TestCase):
    def test_hay_dos_presets_publicos_y_dos_qa(self):
        texto = PRESETS.read_text(encoding="utf-8")
        self.assertEqual(
            4,
            len(re.findall(r"^\[preset\.\d+\]$", texto, re.MULTILINE)),
        )
        for nombre in (
            "Linux x86_64",
            "Windows x86_64",
            "Linux x86_64 QA",
            "Windows x86_64 QA",
        ):
            self.assertIn(f'name="{nombre}"', texto)
        self.assertEqual(4, texto.count("binary_format/embed_pck=true"))
        self.assertEqual(4, texto.count("script_export_mode=2"))
        self.assertNotIn("dist/salida/../", texto)

    def test_las_salidas_quedan_bajo_dist_salida(self):
        texto = PRESETS.read_text(encoding="utf-8")
        rutas = re.findall(r'^export_path="([^"]+)"$', texto, re.MULTILINE)
        self.assertEqual(4, len(rutas))
        for ruta in rutas:
            self.assertTrue(ruta.startswith("../dist/salida/"), ruta)

    def test_presets_publicos_excluyen_debug_y_qa_lo_incluye(self):
        texto = PRESETS.read_text(encoding="utf-8")
        self.assertEqual(2, texto.count('exclude_filter="debug/**"'))
        self.assertEqual(2, texto.count('custom_features=""'))
        self.assertEqual(2, texto.count('custom_features="qa_tools"'))

        bloques = re.split(
            r"(?=^\[preset\.\d+\]$)",
            texto,
            flags=re.MULTILINE,
        )
        por_nombre = {}
        for bloque in bloques:
            nombre = re.search(r'^name="([^"]+)"$', bloque, re.MULTILINE)
            if nombre:
                por_nombre[nombre.group(1)] = bloque

        for nombre in ("Linux x86_64", "Windows x86_64"):
            self.assertIn('exclude_filter="debug/**"', por_nombre[nombre])
            self.assertIn('custom_features=""', por_nombre[nombre])
        for nombre in ("Linux x86_64 QA", "Windows x86_64 QA"):
            self.assertIn('exclude_filter=""', por_nombre[nombre])
            self.assertIn('custom_features="qa_tools"', por_nombre[nombre])

    def test_el_script_exporta_release_y_no_publica(self):
        texto = SCRIPT.read_text(encoding="utf-8")
        self.assertEqual(1, texto.count("--export-release"))
        self.assertIn('LINUX_PRESET="Linux x86_64"', texto)
        self.assertIn('WINDOWS_PRESET="Windows x86_64"', texto)
        self.assertIn('LINUX_PRESET="Linux x86_64 QA"', texto)
        self.assertIn('WINDOWS_PRESET="Windows x86_64 QA"', texto)
        self.assertNotIn("--export-debug", texto)
        self.assertNotIn("butler", texto.lower())
        self.assertNotIn("ITCH", texto)
        self.assertIn(".godot-version", texto)
        self.assertIn("GODOT_BIN", texto)
        self.assertIn("SHA256SUMS", texto)

    def test_alpha_qa_y_release_por_tag_tienen_fronteras_distintas(self):
        script = SCRIPT.read_text(encoding="utf-8")
        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn('QA_TOOLS="${SIGA98_QA_TOOLS:-0}"'.replace("\\", ""), script)
        self.assertIn("qa_tools=$QA_TOOLS", script)
        expresion = (
            "SIGA98_QA_TOOLS: "
            "${{ startsWith(github.ref, 'refs/tags/v') && '0' || '1' }}"
        ).replace("\\", "")
        self.assertIn(expresion, workflow)

    def test_el_workflow_demuestra_la_frontera_sobre_paquetes_y_ejecutables(self):
        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertTrue(AUDITOR.is_file())
        self.assertTrue(MARCADOR_QA.is_file())
        self.assertIn('--export-pack "Linux x86_64 QA"', workflow)
        self.assertIn('--export-pack "Linux x86_64"', workflow)
        self.assertIn("auditar_frontera_qa.py qa", workflow)
        self.assertIn("auditar_frontera_qa.py publico", workflow)
        self.assertIn("SIGA98_ARTEFACTO_PUBLICO:", workflow)
        self.assertIn("dist/salida/godot-linux/SIGA-98.x86_64", workflow)
        self.assertIn("dist/salida/godot-windows/SIGA-98.exe", workflow)

    def test_el_auditor_distingue_un_artefacto_qa_de_uno_publico(self):
        with tempfile.TemporaryDirectory(prefix="frontera-qa-") as temporal:
            qa = Path(temporal) / "qa.bin"
            publico = Path(temporal) / "publico.bin"
            qa.write_bytes(b"cabecera qa_export_marker_116 cola")
            publico.write_bytes(b"cabecera sin herramientas internas")

            for modo, artefacto in (("qa", qa), ("publico", publico)):
                resultado = subprocess.run(
                    [sys.executable, str(AUDITOR), modo, str(artefacto)],
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    check=False,
                )
                self.assertEqual(0, resultado.returncode, resultado.stdout)

            fallo = subprocess.run(
                [sys.executable, str(AUDITOR), "publico", str(qa)],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            self.assertNotEqual(0, fallo.returncode)


if __name__ == "__main__":
    unittest.main()
