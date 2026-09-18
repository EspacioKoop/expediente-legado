from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPTURADOR = ROOT / "godot" / "pruebas" / "capturar_castillo_947.gd"
WORKFLOW = ROOT / ".github" / "workflows" / "evidencia-castillo-947.yml"
DOC = ROOT / "docs" / "evidencias" / "castillo-947" / "README.md"


class EvidenciaCastillo947Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.capturador = CAPTURADOR.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_compara_las_cuatro_composiciones_con_camara_fija(self) -> None:
        for variante in ("patio", "scriptorium", "torre_capilla", "claustro_reflejado"):
            self.assertIn(f'"variante": "{variante}"', self.capturador)
        self.assertIn('{"nombre": "claustro_giro"', self.capturador)
        self.assertIn('"nombre": "torre_capilla_pulso"', self.capturador)
        self.assertIn('"pulso": 2', self.capturador)
        self.assertIn('"nombre": "scriptorium_lectura"', self.capturador)
        self.assertIn('"lectura": true', self.capturador)
        self.assertIn("SuenoCastillo3D.reaccionar_a_lectura(mundo)", self.capturador)
        self.assertIn("controlador.aplicar_pulso(int(caso[\"pulso\"]))", self.capturador)
        self.assertIn("Vector3(13.5, 8.2, 15.5)", self.capturador)
        self.assertIn("camara.fov = 58.0", self.capturador)
        self.assertIn("root.size = TAMANO", self.capturador)

    def test_capturador_monta_solo_presentacion_sin_fisica_nueva(self) -> None:
        self.assertIn("SuenoCastillo3D.montar(mundo, espacio)", self.capturador)
        self.assertNotIn("StaticBody3D", self.capturador)
        self.assertNotIn("CollisionShape3D", self.capturador)
        self.assertNotIn("Espacio3D.construir", self.capturador)

    def test_workflow_renderiza_con_xvfb_y_publica_png(self) -> None:
        self.assertIn("Evidencia castillo 947", self.workflow)
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("capturar_castillo_947.gd", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("evidencia-castillo-947/*.png", self.workflow)

    def test_documentacion_no_confunde_evidencia_con_playtest_humano(self) -> None:
        self.assertIn("#398", self.doc)
        self.assertIn("no sustituye", self.doc.lower())
        self.assertIn("mismo encuadre", self.doc.lower())


if __name__ == "__main__":
    unittest.main()
