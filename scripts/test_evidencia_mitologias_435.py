from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CAPTURADOR = ROOT / "godot/pruebas/capturar_mitologias_435.gd"
WORKFLOW = ROOT / ".github/workflows/evidencia-mitologias-435.yml"
DOC = ROOT / "docs/evidencias/mitologias-435/README.md"
CONTROLLER_GILGAMESH = ROOT / "godot/guion/dia_gilgamesh_sueno_app.gd"


class EvidenciaMitologias435Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.capturador = CAPTURADOR.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")
        cls.controller_gilgamesh = CONTROLLER_GILGAMESH.read_text(encoding="utf-8")

    def test_cubre_las_tres_familias_sin_gate_dedicado(self):
        self.assertIn("ESCENA_GILGAMESH.instantiate()", self.capturador)
        for captura in (
            "436_gilgamesh_inicial.png",
            "436_gilgamesh_puzzle.png",
            "436_gilgamesh_resuelto.png",
        ):
            self.assertIn(captura, self.capturador)
            self.assertIn(captura, self.workflow)

        contratos = (
            ("SuenoAquiles.new()", "438_aquiles_revelado.png", "438_aquiles_resuelto.png"),
            ("SuenoDuat.crear_prototipo_3d", "441_duat_inicial.png", "441_duat_equilibrado.png"),
        )
        for constructor, inicial, final in contratos:
            self.assertIn(constructor, self.capturador)
            self.assertIn(inicial, self.capturador)
            self.assertIn(final, self.capturador)
            self.assertIn(inicial, self.workflow)
            self.assertIn(final, self.workflow)

    def test_gilgamesh_reproduce_escala_y_camara_de_runtime(self):
        self.assertIn("Espacio3D.construir(mundo, espacio)", self.capturador)
        self.assertIn("SuenoGilgamesh.ESCALA_ENCUENTRO", self.capturador)
        self.assertIn("ALTURA_JUGADOR", self.capturador)
        self.assertIn('get_node_or_null("CamaraStandalone")', self.capturador)
        self.assertIn("sueno.remove_child(standalone)", self.capturador)
        self.assertIn("SuenoGilgamesh.ESCALA_ENCUENTRO", self.controller_gilgamesh)
        self.assertNotIn("const ESCALA_ENCUENTRO := 0.44", self.controller_gilgamesh)

    def test_usa_transiciones_reales(self):
        for token in (
            "colocar_fragmento(",
            "aplicar_lectura_espacial(true, false)",
            'aplicar_resolucion("sellar", true)',
            "aplicar_pesaje_3d(",
        ):
            self.assertIn(token, self.capturador)

    def test_no_autoaprueba_la_revision_humana(self):
        self.assertIn('"veredicto_automatico": false', self.capturador)
        self.assertIn('"requiere_revision_humana": true', self.capturador)
        self.assertIn("veredicto_automatico", self.workflow)
        self.assertIn("requiere_revision_humana", self.workflow)
        self.assertIn("no", self.doc.lower())
        self.assertIn("revisión humana", self.doc.lower())

    def test_workflow_publica_artifact(self):
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("evidencia-mitologias-435/", self.workflow)
        self.assertIn("capturar_mitologias_435.gd", self.workflow)


if __name__ == "__main__":
    unittest.main()
