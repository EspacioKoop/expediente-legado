"""Contrato estatico del gate visual reproducible de Traffic Road Assets #225."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaTraficoVial225Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (
            ROOT / "godot/pruebas/capturar_trafico_vial_225.gd"
        ).read_text(encoding="utf-8")
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-trafico-vial-225.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/trafico-vial-225/README.md"
        ).read_text(encoding="utf-8")

    def test_cubre_las_cuatro_vistas_del_gate(self):
        for caso in ("barrera_conos", "tapa_sur", "tapa_norte", "paso_central"):
            self.assertIn(f'"id": "{caso}"', self.captura)
        self.assertIn('"fase": "trayecto"', self.captura)
        self.assertIn('"issue": 225', self.captura)

    def test_inventaria_las_cinco_instancias_cc0(self):
        for nodo in ("TapaSur", "TapaNorte", "Barrera", "ConoSur", "ConoNorte"):
            self.assertIn(f'"{nodo}"', self.captura)
        self.assertIn('"instancias_cc0": objetos.size()', self.captura)
        self.assertIn("_aabb_visual", self.captura)

    def test_usa_escena_camara_y_frustum_reales(self):
        self.assertIn('load("res://escenas/dia.tscn").instantiate()', self.captura)
        self.assertIn('dia._entrar_en("trayecto")', self.captura)
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn("camara.make_current()", self.captura)
        self.assertIn("camara.look_at", self.captura)
        self.assertIn("camara.is_position_in_frustum", self.captura)
        self.assertIn("camara.unproject_position", self.captura)
        self.assertIn("RenderingServer.frame_post_draw", self.captura)
        self.assertIn("dia._hud_prioridades.visible = false", self.captura)

    def test_no_autoaprueba_el_criterio_artistico(self):
        self.assertIn('"criterio": "evidencia_para_revision_humana"', self.captura)
        self.assertIn('"veredicto_automatico": false', self.captura)
        self.assertIn("no sustituyen", self.captura.lower())

    def test_workflow_publica_cuatro_png_y_manifiesto(self):
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn(
            "for captura in barrera_conos tapa_sur tapa_norte paso_central; do",
            self.workflow,
        )
        self.assertIn("manifest.json", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("evidencia-trafico-vial-225-${{ github.sha }}", self.workflow)
        self.assertIn('manifest["instancias_cc0"] != 5', self.workflow)

    def test_documentacion_deja_claro_el_gate_humano(self):
        texto = self.docs.lower()
        for termino in (
            "revision humana",
            "epoca",
            "escala",
            "clipping",
            "legibilidad",
            "barrera_conos.png",
            "tapa_sur.png",
            "tapa_norte.png",
            "paso_central.png",
            "no cierra",
        ):
            self.assertIn(termino, texto)


if __name__ == "__main__":
    unittest.main()
