"""Contrato estático del gate reproducible de casa para #133."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaCasa133Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (ROOT / "godot/pruebas/capturar_casa_133.gd").read_text(
            encoding="utf-8"
        )
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-casa-133.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/casa-133/README.md"
        ).read_text(encoding="utf-8")

    def test_cubre_los_tres_criterios_visuales_del_issue(self):
        for caso in ("entrada_vivienda", "salon_dormitorio", "consola_television"):
            self.assertIn(f'"id": "{caso}"', self.captura)
        self.assertIn('"fase": "casa"', self.captura)
        self.assertIn('"issue": 133', self.captura)

    def test_usa_escena_y_camara_jugables_sin_hud(self):
        self.assertIn('load("res://escenas/dia.tscn").instantiate()', self.captura)
        self.assertIn('dia._entrar_en("casa")', self.captura)
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn("camara.look_at", self.captura)
        self.assertIn("camara.fov = FOV", self.captura)
        self.assertIn("dia._hud_prioridades.visible = false", self.captura)
        self.assertIn('dia.find_children("*", "CanvasLayer"', self.captura)

    def test_exige_la_composicion_domestica_real(self):
        for nodo in (
            "CasaHogarCC0",
            "HabitacionesCasa",
            "TransicionesCasa",
            "ConsolaSobremesa98",
            "TelevisorCasaInteractuable",
        ):
            self.assertIn(f'"{nodo}"', self.captura)

    def test_no_convierte_capturas_en_veredicto_artistico(self):
        self.assertIn('"criterio": "evidencia_para_revision_humana"', self.captura)
        self.assertIn('"veredicto_automatico": false', self.captura)
        self.assertIn("no decide", self.captura.lower())

    def test_workflow_publica_tres_png_y_manifiesto(self):
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn(
            "for captura in entrada_vivienda salon_dormitorio consola_television; do",
            self.workflow,
        )
        self.assertIn("manifest.json", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("evidencia-casa-133-${{ github.sha }}", self.workflow)
        self.assertIn("len(set(hashes)) != 3", self.workflow)

    def test_documentacion_exige_revision_humana_criterio_a_criterio(self):
        texto = self.docs.lower()
        self.assertIn("revisión humana", texto)
        self.assertIn("entrada_vivienda", texto)
        self.assertIn("salon_dormitorio", texto)
        self.assertIn("consola_television", texto)
        self.assertIn("pass/fail", texto)
        self.assertIn("no cierra", texto)


if __name__ == "__main__":
    unittest.main()
