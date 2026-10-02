from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CAPTURA = ROOT / "godot/pruebas/capturar_inicio_830.gd"
WORKFLOW = ROOT / ".github/workflows/evidencia-inicio-830.yml"
README = ROOT / "docs/evidencias/inicio-830/README.md"


class EvidenciaInicio830Test(unittest.TestCase):
    def test_captura_escena_real_a_1080p(self):
        fuente = CAPTURA.read_text(encoding="utf-8")
        self.assertIn('const Inicio := preload("res://guion/inicio_app.gd")', fuente)
        self.assertIn("var inicio := Inicio.new()", fuente)
        self.assertIn("const ANCHO := 1920", fuente)
        self.assertIn("const ALTO := 1080", fuente)
        self.assertIn("InicioDiorama3D", fuente)
        self.assertIn('"FondoInicio"', fuente)

    def test_compara_movimiento_normal_y_reducido(self):
        fuente = CAPTURA.read_text(encoding="utf-8")
        self.assertIn('"inicio-normal.png"', fuente)
        self.assertIn('"inicio-reduccion-movimiento.png"', fuente)
        self.assertIn("configurar_reduccion_movimiento(true)", fuente)
        self.assertIn('"_exterior"', fuente)
        self.assertIn('"VaporTaza"', fuente)
        self.assertIn('"veredicto_automatico": false', fuente)

    def test_workflow_publica_artifact_sin_autoaprobar(self):
        flujo = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("Evidencia inicio 830", flujo)
        self.assertIn("capturar_inicio_830.gd", flujo)
        self.assertIn("uses: ./.github/actions/upload-artifact", flujo)
        self.assertNotIn("actions/upload-artifact@", flujo)
        self.assertIn("inicio-normal.png", flujo)
        self.assertIn("inicio-reduccion-movimiento.png", flujo)
        self.assertIn("manifest.json", flujo)

    def test_documentacion_exige_revision_humana(self):
        texto = README.read_text(encoding="utf-8")
        self.assertIn("#830", texto)
        self.assertIn("1920×1080", texto)
        self.assertIn("inicio-normal.png", texto)
        self.assertIn("inicio-reduccion-movimiento.png", texto)
        self.assertIn("revisión humana", texto.lower())


if __name__ == "__main__":
    unittest.main()
