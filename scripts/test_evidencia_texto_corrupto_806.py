from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CAPTURA = ROOT / "godot/pruebas/capturar_texto_corrupto_806.gd"
WORKFLOW = ROOT / ".github/workflows/evidencia-texto-corrupto-806.yml"
README = ROOT / "docs/evidencias/texto-corrupto-806/README.md"


class EvidenciaTextoCorrupto806Test(unittest.TestCase):
    def test_captura_superficies_reales(self):
        fuente = CAPTURA.read_text(encoding="utf-8")
        self.assertIn("ExploradorSiga.new()", fuente)
        self.assertIn('find_child("VisorDocumento"', fuente)
        self.assertIn("ArchivadorInteractivo3D.new()", fuente)
        self.assertIn('rotulo.name = "DestinoArchivado"', fuente)
        self.assertIn("_sincronizar_documento", fuente)
        self.assertIn("_sincronizar_rotulos_3d", fuente)

    def test_genera_dos_png_y_manifiesto_sin_autoaprobar(self):
        fuente = CAPTURA.read_text(encoding="utf-8")
        self.assertIn('"documento-os98.png"', fuente)
        self.assertIn('"rotulo-3d.png"', fuente)
        self.assertIn('"veredicto_automatico": false', fuente)
        flujo = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("actions/upload-artifact@v4", flujo)
        self.assertIn("evidencia-texto-corrupto-806", flujo)
        self.assertIn("capturar_texto_corrupto_806.gd", flujo)

    def test_documentacion_exige_revision_humana(self):
        texto = README.read_text(encoding="utf-8")
        self.assertIn("documento-os98.png", texto)
        self.assertIn("rotulo-3d.png", texto)
        self.assertIn("revisión humana", texto.lower())
        self.assertIn("#806", texto)


if __name__ == "__main__":
    unittest.main()
