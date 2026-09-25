"""Contrato estático del gate reproducible de calle para #277."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaCalle277Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (ROOT / "godot/pruebas/capturar_calle_277.gd").read_text(
            encoding="utf-8"
        )
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-calle-277.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/calle-277/README.md"
        ).read_text(encoding="utf-8")

    def test_cubre_los_criterios_visuales_del_issue_y_el_tramo_central(self):
        for caso in (
            "spawn_exterior",
            "mitad_recorrido",
            "escaparate_crt",
            "portal_casa",
        ):
            self.assertIn(f'"id": "{caso}"', self.captura)
        self.assertIn('"fase": "trayecto"', self.captura)
        self.assertIn('"issue": 277', self.captura)
        self.assertIn("Vector3(0.0, 0.0, 3.5)", self.captura)

    def test_usa_camara_jugable_sin_hud_y_locale_controlado(self):
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn("camara.look_at", self.captura)
        self.assertIn("camara.fov = FOV", self.captura)
        self.assertIn("dia._hud_prioridades.visible = false", self.captura)
        self.assertIn('dia.find_children("*", "CanvasLayer"', self.captura)
        self.assertIn('TranslationServer.set_locale("es")', self.captura)
        self.assertIn('rotulo.text.begins_with("CALLE_")', self.captura)

    def test_no_convierte_capturas_en_veredicto_artistico(self):
        self.assertIn('"criterio": "evidencia_para_revision_humana"', self.captura)
        self.assertIn('"veredicto_automatico": false', self.captura)
        self.assertIn("no decide el resultado artístico", self.captura.lower())

    def test_workflow_publica_cuatro_png_y_manifiesto(self):
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn(
            "for captura in spawn_exterior mitad_recorrido escaparate_crt portal_casa; do",
            self.workflow,
        )
        self.assertIn("manifest.json", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("evidencia-calle-277-${{ github.sha }}", self.workflow)
        self.assertIn("len(set(hashes)) != 4", self.workflow)

    def test_documentacion_exige_revision_humana_criterio_a_criterio(self):
        texto = self.docs.lower()
        self.assertIn("revisión humana", texto)
        self.assertIn("spawn_exterior", texto)
        self.assertIn("mitad_recorrido", texto)
        self.assertIn("escaparate_crt", texto)
        self.assertIn("portal_casa", texto)
        self.assertIn("pass/fail", texto)
        self.assertIn("no cierra", texto)


if __name__ == "__main__":
    unittest.main()
