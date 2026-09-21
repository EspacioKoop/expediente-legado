"""Contrato estático del gate visual reproducible de comercios para #676."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaComercios676Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (
            ROOT / "godot/pruebas/capturar_comercios_676.gd"
        ).read_text(encoding="utf-8")
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-comercios-676.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/comercios-676/README.md"
        ).read_text(encoding="utf-8")

    def test_cubre_las_cuatro_vistas_comerciales(self):
        for caso in (
            "bit98_exterior",
            "bit98_interior",
            "quiosco_avenida",
            "el_trastero",
        ):
            self.assertIn(f'"id": "{caso}"', self.captura)
        self.assertIn('"issue": 676', self.captura)
        self.assertIn('"fase": "trayecto"', self.captura)

    def test_bit98_interior_usa_la_entrada_real(self):
        self.assertIn('"EntrarTiendaVideojuegos"', self.captura)
        self.assertIn("entrar_bit98.interactuar(dia._caminante)", self.captura)
        self.assertIn("interior_bit98.visible", self.captura)
        self.assertIn("dia._caminante.global_position.x < 40.0", self.captura)

    def test_usa_camara_jugable_sin_hud_y_locale_controlado(self):
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn("camara.look_at", self.captura)
        self.assertIn("camara.fov = FOV", self.captura)
        self.assertIn("dia._hud_prioridades.visible = false", self.captura)
        self.assertIn('dia.find_children("*", "CanvasLayer"', self.captura)
        self.assertIn('TranslationServer.set_locale("es")', self.captura)

    def test_no_convierte_capturas_en_veredicto_artistico(self):
        self.assertIn('"criterio": "evidencia_para_revision_humana"', self.captura)
        self.assertIn('"veredicto_automatico": false', self.captura)
        self.assertIn("no decide si el arte es suficiente", self.captura.lower())

    def test_workflow_publica_cuatro_png_y_manifiesto(self):
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn(
            "for captura in bit98_exterior bit98_interior quiosco_avenida el_trastero; do",
            self.workflow,
        )
        self.assertIn("manifest.json", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("evidencia-comercios-676-${{ github.sha }}", self.workflow)
        self.assertIn("len(set(hashes)) != 4", self.workflow)

    def test_documentacion_exige_revision_humana_por_comercio(self):
        texto = self.docs.lower()
        self.assertIn("revisión humana", texto)
        self.assertIn("bit98_exterior", texto)
        self.assertIn("bit98_interior", texto)
        self.assertIn("quiosco_avenida", texto)
        self.assertIn("el_trastero", texto)
        self.assertIn("pass/fail", texto)
        self.assertIn("no cierra", texto)


if __name__ == "__main__":
    unittest.main()
