"""Contrato estático de evidencia visual reproducible para #673."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaVecinos673Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (ROOT / "godot/pruebas/capturar_vecinos_673.gd").read_text(
            encoding="utf-8"
        )
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-vecinos-673.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/vecinos-673/README.md"
        ).read_text(encoding="utf-8")

    def test_captura_dos_jornadas_reproducibles(self):
        self.assertIn('"id": "manuela"', self.captura)
        self.assertIn('"dia": 7', self.captura)
        self.assertIn('"id": "repartidor"', self.captura)
        self.assertIn('"dia": 8', self.captura)
        self.assertIn('"Manuela3B"', self.captura)
        self.assertIn('"RepartidorConfundido"', self.captura)
        self.assertIn('"PaqueteEquivocado"', self.captura)

    def test_usa_runtime_y_camara_jugable(self):
        self.assertIn('load("res://escenas/dia.tscn").instantiate()', self.captura)
        self.assertIn('dia._entrar_en("trayecto")', self.captura)
        self.assertIn('dia.get_node_or_null("VecinosEdificioController")', self.captura)
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn("camara.look_at", self.captura)
        self.assertIn("camara.is_position_in_frustum", self.captura)
        self.assertIn("camara.unproject_position", self.captura)

    def test_manifiesto_no_autoaprueba_gate_humano(self):
        self.assertIn('"criterio": "evidencia_para_revision_humana"', self.captura)
        self.assertIn('"veredicto_automatico": false', self.captura)
        self.assertIn('"camara": "jugable"', self.captura)
        self.assertIn('"hud": false', self.captura)

    def test_workflow_publica_png_y_manifiesto(self):
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("for captura in manuela repartidor; do", self.workflow)
        self.assertIn("manifest.json", self.workflow)
        self.assertIn("uses: ./.github/actions/upload-artifact", self.workflow)
        self.assertNotIn("actions/upload-artifact@", self.workflow)
        self.assertIn("evidencia-vecinos-673-" + "$" + "{{ github.sha }}", self.workflow)
        self.assertIn('objetivo["en_frustum"] is not True', self.workflow)

    def test_documentacion_mantiene_revision_humana(self):
        texto = self.docs.lower()
        self.assertIn("revisión humana", texto)
        self.assertIn("manuela.png", texto)
        self.assertIn("repartidor.png", texto)
        self.assertIn("cámara jugable", texto)
        self.assertIn("no autoaprueba", texto)
        self.assertIn("mando", texto)


if __name__ == "__main__":
    unittest.main()
