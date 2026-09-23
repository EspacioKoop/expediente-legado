from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPTURA = ROOT / "godot" / "pruebas" / "capturas_oficina_126.gd"
WORKFLOW = ROOT / ".github" / "workflows" / "oficina-visual-gate-126.yml"


class OficinaVisualGate126Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = CAPTURA.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_genera_los_dos_encuadres_de_cierre(self):
        self.assertIn('"nombre": "puestos-archivo"', self.captura)
        self.assertIn('"nombre": "acceso-ventanas"', self.captura)
        self.assertIn("const TAM := Vector2i(1280, 720)", self.captura)
        self.assertIn("RenderingServer.frame_post_draw", self.captura)
        self.assertIn("imagen.save_png(ruta)", self.captura)

    def test_monta_el_archivo_real_sin_hud(self):
        self.assertIn("EspaciosCatalogo.OFICINA.duplicate(true)", self.captura)
        self.assertIn("Espacio3D.construir(_mundo, espacio)", self.captura)
        self.assertIn('load("res://guion/dia_dressing_cc0_app.gd")', self.captura)
        self.assertIn("OficinaUtileria.montar(_mundo)", self.captura)
        self.assertIn("OficinaAssetsCc0.montar(_mundo)", self.captura)
        self.assertIn("PostersOficina.montar(_mundo)", self.captura)
        self.assertIn("CuadrosOficina.montar(_mundo)", self.captura)
        self.assertIn('OS.get_environment("GITHUB_SHA")', self.captura)
        self.assertIn('has_meta("oficina_styloo_cc0")', self.captura)
        self.assertIn("RenderingServer.get_current_rendering_method()", self.captura)
        self.assertIn("build cuyo SHA coincida", self.captura)
        self.assertNotIn("CanvasLayer.new()", self.captura)

    def test_incluye_companeros_sin_rotulos(self):
        self.assertIn("Companeros.plantilla(126)", self.captura)
        self.assertIn('"rotulo": ""', self.captura)
        self.assertIn('"frase": ""', self.captura)

    def test_workflow_publica_artifact_para_revision_humana(self):
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("res://pruebas/capturas_oficina_126.gd", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("SIGA-98-oficina-visual-gate-126-${{ github.sha }}", self.workflow)
        self.assertIn("puestos-archivo.png", self.workflow)
        self.assertIn("acceso-ventanas.png", self.workflow)


if __name__ == "__main__":
    unittest.main()
