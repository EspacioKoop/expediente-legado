"""Contrato del gate perceptivo reproducible de la Hidra (#439)."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPTURADOR = ROOT / "godot/pruebas/capturar_hidra_439.gd"
WORKFLOW = ROOT / ".github/workflows/evidencia-hidra-439.yml"
DOC = ROOT / "docs/evidencias/hidra-439/README.md"
PROYECTO = ROOT / "godot/project.godot"


class EvidenciaHidra439Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = CAPTURADOR.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        cls.docs = DOC.read_text(encoding="utf-8")
        cls.proyecto = PROYECTO.read_text(encoding="utf-8")

    def test_captura_tres_estados_del_vertical_real(self):
        self.assertIn("SuenoHidraInteraccion3D.new()", self.captura)
        self.assertIn("sintoma.interactuar(actor)", self.captura)
        self.assertIn("nodo.interactuar(actor)", self.captura)
        for archivo in ("01_inicial.png", "02_proliferacion.png", "03_resuelta.png"):
            self.assertIn(archivo, self.captura)
            self.assertIn(archivo, self.workflow)

    def test_camara_es_fija_sin_hud_y_a_fov_jugable(self):
        self.assertIn("const FOV := 70.0", self.captura)
        self.assertIn('camara.name = "CamaraJugadorSinHUD"', self.captura)
        self.assertIn('"hud": false', self.captura)
        for termino in ("CanvasLayer", "Control.new", "Label.new"):
            self.assertNotIn(termino, self.captura)

    def test_manifiesto_registra_la_causalidad_sin_puntuar_estetica(self):
        for campo in (
            '"cabezas"',
            '"regeneraciones"',
            '"nodo_legible"',
            '"resuelta"',
            '"sha256"',
        ):
            self.assertIn(campo, self.captura)
        self.assertIn('"criterio": "evidencia_para_revision_humana"', self.captura)

    def test_workflow_usa_renderer_canonico_y_publica_artifact(self):
        self.assertIn('renderer/rendering_method="forward_plus"', self.proyecto)
        self.assertIn("xvfb-run -a godot4 --path godot", self.workflow)
        self.assertNotIn("--rendering-method gl_compatibility", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("len(set(hashes)) != 3", self.workflow)
        self.assertIn('proliferacion["cabezas"] <= inicial["cabezas"]', self.workflow)

    def test_documentacion_reserva_el_veredicto_a_revision_humana(self):
        self.assertIn("revisión humana", self.docs.lower())
        self.assertIn("no sustituye", self.docs.lower())
        self.assertIn("raíz", self.docs.lower())
        self.assertIn("cartucho", self.docs.lower())
        self.assertIn("Forward+", self.docs)


if __name__ == "__main__":
    unittest.main()
