from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CAPTURA = ROOT / "godot/pruebas/capturar_minotauro_437.gd"
WORKFLOW = ROOT / ".github/workflows/evidencia-minotauro-437.yml"
README = ROOT / "docs/evidencias/minotauro-437/README.md"


class EvidenciaMinotauro437Test(unittest.TestCase):
    def test_captura_tres_estados_de_la_misma_regla(self):
        fuente = CAPTURA.read_text(encoding="utf-8")
        self.assertIn('"inicial"', fuente)
        self.assertIn('"marca-estable"', fuente)
        self.assertIn('"marca-desplazada"', fuente)
        self.assertIn("SuenoMinotauro3D.new()", fuente)
        self.assertIn("SuenoMinotauro.CRUCE_NORTE", fuente)
        self.assertIn("SuenoMinotauro.BISAGRA", fuente)
        self.assertIn("SuenoMinotauro.CENTRO", fuente)

    def test_manifiesto_no_autoaprueba_legibilidad(self):
        fuente = CAPTURA.read_text(encoding="utf-8")
        self.assertIn('"veredicto_automatico": false', fuente)
        self.assertIn("SuenoMinotauro.leer_marca(estado, 0)", fuente)
        flujo = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("actions/upload-artifact@v4", flujo)
        self.assertIn("evidencia-minotauro-437", flujo)
        self.assertIn("capturar_minotauro_437.gd", flujo)

    def test_documentacion_define_pregunta_humana(self):
        texto = README.read_text(encoding="utf-8").lower()
        self.assertIn("revisión humana", texto)
        self.assertIn("ensayo ciego", texto)
        self.assertIn("#437", texto)
        self.assertIn("marca-desplazada.png", texto)


if __name__ == "__main__":
    unittest.main()
