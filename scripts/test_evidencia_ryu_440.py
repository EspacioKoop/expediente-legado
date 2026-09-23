from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPTURADOR = ROOT / "godot" / "pruebas" / "capturar_ryu_440.gd"
WORKFLOW = ROOT / ".github" / "workflows" / "evidencia-ryu-440.yml"
DOC = ROOT / "docs" / "evidencias" / "ryu-440" / "README.md"


class EvidenciaRyu440Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.capturador = CAPTURADOR.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_captura_inicio_resolucion_y_reduccion_de_movimiento(self) -> None:
        for caso in ("normal_inicial", "normal_resuelto", "reducido_resuelto"):
            self.assertIn(f'"id": "{caso}"', self.capturador)
            self.assertIn(f"{caso}.png", self.workflow)

        self.assertIn('"resolver": false', self.capturador)
        self.assertGreaterEqual(self.capturador.count('"resolver": true'), 2)
        self.assertIn('"reduccion_movimiento": true', self.capturador)

    def test_reproduce_el_contexto_runtime_sin_hud(self) -> None:
        self.assertIn('const FORMA := "peine"', self.capturador)
        self.assertIn("Espacio3D.construir(mundo, espacio)", self.capturador)
        self.assertIn("const ESCALA_RYU := 0.48", self.capturador)
        self.assertIn("ryu.scale = Vector3.ONE * ESCALA_RYU", self.capturador)
        self.assertIn('camara.name = "CamaraJugadorSinHUD"', self.capturador)
        self.assertIn('"hud": false', self.capturador)
        for termino in ("CanvasLayer", "Label.new", "Control.new", "HUDLayer"):
            self.assertNotIn(termino, self.capturador)

    def test_resuelve_por_el_contrato_real_de_interaccion(self) -> None:
        self.assertIn("as Interactuable3D", self.capturador)
        self.assertIn("compuerta.interactuar(actor)", self.capturador)
        self.assertIn("return ryu.resuelto()", self.capturador)
        self.assertNotIn("Input.", self.capturador)

    def test_manifiesto_registra_estado_y_encuadre(self) -> None:
        for clave in (
            '"estado_compuertas"',
            '"gotas"',
            '"ancla"',
            '"camara"',
            '"objetivo"',
            '"escala_ryu"',
            '"altura_jugador"',
        ):
            self.assertIn(clave, self.capturador)
        self.assertIn('salida.path_join("manifest.json")', self.capturador)

    def test_workflow_renderiza_y_publica_artifact(self) -> None:
        self.assertIn("Evidencia Ryū 440", self.workflow)
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("capturar_ryu_440.gd", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("evidencia-ryu-440/", self.workflow)

    def test_documentacion_separa_evidencia_de_playtest(self) -> None:
        self.assertIn("#440", self.doc)
        self.assertIn("#398", self.doc)
        self.assertIn("no sustituye", self.doc.lower())
        self.assertIn("silueta", self.doc.lower())
        self.assertIn("cauce", self.doc.lower())
        self.assertIn("reducción de movimiento", self.doc.lower())


if __name__ == "__main__":
    unittest.main()
