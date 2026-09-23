"""Contrato estático de evidencia visual reproducible para #787."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class EvidenciaGato787Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.captura = (ROOT / "godot/pruebas/capturar_gato_787.gd").read_text(
            encoding="utf-8"
        )
        cls.workflow = (
            ROOT / ".github/workflows/evidencia-gato-787.yml"
        ).read_text(encoding="utf-8")
        cls.docs = (
            ROOT / "docs/evidencias/gato-787/README.md"
        ).read_text(encoding="utf-8")

    def test_captura_casa_y_sueno_con_el_gato_real(self):
        self.assertIn('"id": "casa"', self.captura)
        self.assertIn('"fase": "casa"', self.captura)
        self.assertIn('"id": "sueno"', self.captura)
        self.assertIn('"fase": "sueño"', self.captura)
        self.assertIn("dia._gato if fase == \"casa\" else dia._gato_guia", self.captura)
        self.assertIn('dia.jornada["gato"]["presente"] = true', self.captura)

    def test_usa_camara_jugable_y_encuadra_la_silueta(self):
        self.assertIn('dia._caminante.get_node("Camara")', self.captura)
        self.assertIn('"camara": Vector3(2.8, 0.0, 3.35)', self.captura)
        self.assertIn('var posicion: Vector3 = caso.get("camara", entrada)', self.captura)
        self.assertIn("dia._caminante.situar(posicion, 0.0)", self.captura)
        self.assertIn("camara.look_at(gato.global_position", self.captura)
        self.assertIn("camara.fov = FOV", self.captura)
        self.assertIn("dia._hud_prioridades.visible = false", self.captura)

    def test_manifiesto_expone_estabilidad_sin_autoaprobar(self):
        self.assertIn('"gato_top_level": gato.top_level', self.captura)
        self.assertIn('"escala_global": _vector_a_array(escala)', self.captura)
        self.assertIn('"criterio": "evidencia_para_revision_humana"', self.captura)
        self.assertIn('"veredicto_automatico": false', self.captura)

    def test_workflow_publica_dos_png_y_manifiesto(self):
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("for captura in casa sueno; do", self.workflow)
        self.assertIn("manifest.json", self.workflow)
        self.assertIn("actions/upload-artifact@v4", self.workflow)
        self.assertIn("evidencia-gato-787-${{ github.sha }}", self.workflow)
        self.assertIn('casos["sueno"]["gato_top_level"] is not True', self.workflow)

    def test_documentacion_exige_revision_humana(self):
        texto = self.docs.lower()
        self.assertIn("revisión humana", texto)
        self.assertIn("casa.png", texto)
        self.assertIn("sueno.png", texto)
        self.assertIn("misma silueta", texto)
        self.assertIn("no autoaprueba", texto)
        self.assertIn("pass/fail", texto)


if __name__ == "__main__":
    unittest.main()
