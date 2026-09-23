from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPTURADOR = ROOT / "godot" / "pruebas" / "capturar_sueno_284.gd"
WORKFLOW = ROOT / ".github" / "workflows" / "evidencia-sueno-284.yml"
DOC = ROOT / "docs" / "evidencias" / "sueno-284" / "README.md"


class EvidenciaSueno284Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.capturador = CAPTURADOR.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_captura_las_cuatro_identidades(self) -> None:
        for identidad, forma in (
            ("castillo", "patio"),
            ("montana", "embudo"),
            ("desierto", "peine"),
        ):
            self.assertIn(f'"id": "{identidad}"', self.capturador)
            self.assertIn(f'"forma": "{forma}"', self.capturador)
            self.assertIn(f"{identidad}.png", self.workflow)

        self.assertIn('"id": "escuela"', self.capturador)
        self.assertIn('"forma": "crucero"', self.capturador)
        self.assertIn('"captura": "escuela_general.png"', self.capturador)
        self.assertIn('"captura": "escuela_contenido.png"', self.capturador)
        self.assertIn("escuela_general.png", self.workflow)
        self.assertIn("escuela_contenido.png", self.workflow)

        for clase in ("Castillo", "Montana", "Desierto", "Escuela"):
            self.assertIn(f"Sueno{clase}3D.montar", self.capturador)

    def test_captura_la_arquitectura_base_que_usa_el_runtime(self) -> None:
        self.assertIn("Espacio3D.construir(mundo, espacio)", self.capturador)
        self.assertIn('"gate_humano_crucero": 798', self.capturador)

    def test_comparacion_usa_camara_de_jugador_y_sin_hud(self) -> None:
        self.assertIn("const ALTURA_JUGADOR := 1.65", self.capturador)
        self.assertIn("const FOV := 70.0", self.capturador)
        self.assertIn('camara.name = "CamaraJugadorSinHUD"', self.capturador)
        self.assertIn('"hud": false', self.capturador)
        for termino in ("CanvasLayer", "Control.new", "Label.new", "HUDLayer"):
            self.assertNotIn(termino, self.capturador)

    def test_usa_el_mismo_contenido_conocido_y_no_inventa_pistas(self) -> None:
        self.assertIn('const FRASE_CONOCIDA := "EXPEDIENTE CONOCIDO"', self.capturador)
        self.assertIn('{"frases": [FRASE_CONOCIDA]}', self.capturador)
        self.assertIn("Sueno.espacio(forma, 0, contenido)", self.capturador)

    def test_manifiesto_hace_reproducible_el_encuadre(self) -> None:
        for clave in (
            '"tamano"',
            '"fov"',
            '"altura_jugador"',
            '"camara"',
            '"objetivo"',
            '"identidad_onirica"',
        ):
            self.assertIn(clave, self.capturador)
        self.assertIn('salida.path_join("manifest.json")', self.capturador)

    def test_workflow_renderiza_y_publica_artifact(self) -> None:
        self.assertIn("Evidencia sueño 284", self.workflow)
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("capturar_sueno_284.gd", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("evidencia-sueno-284/", self.workflow)

    def test_documentacion_separa_evidencia_de_juicio_humano(self) -> None:
        self.assertIn("#398", self.doc)
        self.assertIn("no sustituye", self.doc.lower())
        self.assertIn("sin hud", self.doc.lower())
        self.assertIn("silueta", self.doc.lower())
        self.assertIn("sonido", self.doc.lower())


if __name__ == "__main__":
    unittest.main()
