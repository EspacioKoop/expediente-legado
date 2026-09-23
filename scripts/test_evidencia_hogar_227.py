"""Contrato estatico del gate visual reproducible de mobiliario domestico #227."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaHogar227Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (
            ROOT / "godot/pruebas/capturar_hogar_227.gd"
        ).read_text(encoding="utf-8")
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-hogar-227.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/hogar-227/README.md"
        ).read_text(encoding="utf-8")

    def test_cubre_las_cuatro_zonas_domesticas(self):
        for caso in ("entrada", "estar", "dormitorio", "cocina_comedor"):
            self.assertIn(f'"id": "{caso}"', self.captura)
        self.assertIn('"fase": "casa"', self.captura)
        self.assertIn('"issue": 227', self.captura)

    def test_inventaria_las_quince_instancias_cc0(self):
        for nodo in (
            "MuebleTVHogar",
            "MesaBajaHogar",
            "SofaCasa/VisualHogar",
            "ArmarioHogar",
            "MesaComedorHogar",
            "SillaComedorOeste",
            "SillaComedorOesteB",
            "SillaComedorEste",
            "HornoHogar",
            "LavadoraHogar",
            "MicroondasHogar",
            "TostadoraHogar",
            "HervidorHogar",
            "AparadorHogar",
            "LamparaMesaHogar",
        ):
            self.assertIn(nodo, self.captura)
        self.assertIn('nodo.get_node_or_null("AssetCc0")', self.captura)

    def test_usa_escena_camara_y_frustum_reales(self):
        self.assertIn('load("res://escenas/dia.tscn").instantiate()', self.captura)
        self.assertIn('dia._entrar_en("casa")', self.captura)
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn("camara.look_at", self.captura)
        self.assertIn("camara.is_position_in_frustum", self.captura)
        self.assertIn("camara.unproject_position", self.captura)
        self.assertIn("dia._hud_prioridades.visible = false", self.captura)

    def test_no_autoaprueba_el_criterio_artistico(self):
        self.assertIn('"criterio": "evidencia_para_revision_humana"', self.captura)
        self.assertIn('"veredicto_automatico": false', self.captura)
        self.assertIn("no un veredicto", self.captura.lower())

    def test_workflow_publica_cuatro_png_y_manifiesto(self):
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn(
            "for captura in entrada estar dormitorio cocina_comedor; do",
            self.workflow,
        )
        self.assertIn("manifest.json", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("evidencia-hogar-227-${{ github.sha }}", self.workflow)
        self.assertIn('manifest["instancias_cc0"] != 15', self.workflow)
        self.assertIn('objeto["zona"] == zona', self.workflow)

    def test_documentacion_deja_claro_el_gate_humano(self):
        texto = self.docs.lower()
        for termino in (
            "revision humana",
            "escala",
            "clipping",
            "legibilidad",
            "entrada.png",
            "estar.png",
            "dormitorio.png",
            "cocina_comedor.png",
            "no cierra",
        ):
            self.assertIn(termino, texto)


if __name__ == "__main__":
    unittest.main()
