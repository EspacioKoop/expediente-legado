from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPTURA = ROOT / "godot" / "pruebas" / "capturar_kubasta_298.gd"
WORKFLOW = ROOT / ".github" / "workflows" / "kubasta-visual-gate-298.yml"


class KubastaVisualGate298Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = CAPTURA.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_matriz_cubre_tamanos_contrastes_y_escalas(self):
        self.assertIn("const TAMANOS := [10, 12, 14, 16]", self.captura)
        self.assertIn("const ESCALAS := [1.0, 1.25]", self.captura)
        self.assertIn('"id": "oscuro"', self.captura)
        self.assertIn('"id": "claro"', self.captura)
        self.assertIn('{"id": "terminal", "fuente": terminal}', self.captura)
        self.assertIn('{"id": "ibm-plex-mono", "fuente": fallback}', self.captura)

    def test_muestra_espanol_simbolos_y_superficies_reales_del_rol(self):
        self.assertIn("áéíóúüñ¿¡ ÁÉÍÓÚÜÑ", self.captura)
        self.assertIn("RichTextLabel.new()", self.captura)
        self.assertIn("LineEdit.new()", self.captura)
        self.assertIn('"normal_font", fuente', self.captura)
        self.assertIn('"font", fuente', self.captura)

    def test_detecta_clipping_y_puede_exigir_kubasta_real(self):
        self.assertIn("--exigir-kubasta", self.captura)
        self.assertIn("EstiloSiga.RUTA_FUENTE_TERMINAL", self.captura)
        self.assertIn("get_minimum_size().x", self.captura)
        self.assertIn("get_content_height()", self.captura)
        self.assertIn("get_string_size(", self.captura)

    def test_captura_render_real_y_manifiesto(self):
        self.assertIn("RenderingServer.frame_post_draw", self.captura)
        self.assertIn("_viewport.get_texture().get_image()", self.captura)
        self.assertIn("imagen.save_png(ruta)", self.captura)
        self.assertIn('"manifest.json"', self.captura)
        self.assertIn('"kubasta_materializada"', self.captura)
        self.assertIn('"layout_ok"', self.captura)

    def test_workflow_publica_las_ocho_capturas(self):
        self.assertIn("Gate visual Kubasta 298", self.workflow)
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("res://pruebas/capturar_kubasta_298.gd", self.workflow)
        self.assertIn('len(data["casos"]) == 8', self.workflow)
        self.assertIn("SIGA-98-kubasta-visual-gate-298-${{ github.sha }}", self.workflow)
        self.assertIn("retention-days: 14", self.workflow)


if __name__ == "__main__":
    unittest.main()
