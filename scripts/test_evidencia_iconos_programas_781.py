from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CAPTURA = ROOT / "godot/pruebas/capturar_iconos_programas_781.gd"
WORKFLOW = ROOT / ".github/workflows/evidencia-iconos-programas-781.yml"
README = ROOT / "docs/evidencias/iconos-programas-781/README.md"

PROGRAMAS = (
    "explorador",
    "web98",
    "software",
    "correo",
    "bloc-notas",
    "calculadora",
    "catalogo-anomalias",
)


class EvidenciaIconosProgramas781Test(unittest.TestCase):
    def test_captura_shell_real_y_siete_identidades(self):
        fuente = CAPTURA.read_text(encoding="utf-8")
        self.assertIn("EscritorioSigaVisual.new()", fuente)
        self.assertIn("const ANCHO := 1920", fuente)
        self.assertIn("const ALTO := 1080", fuente)
        for programa in PROGRAMAS:
            self.assertIn(f'"id": "{programa}"', fuente)
        self.assertIn("registrar_identidad_visual(id, id)", fuente)
        self.assertIn("registrar_aplicacion(", fuente)

    def test_cubre_atlas_32_y_16_y_no_autoaprueba(self):
        fuente = CAPTURA.read_text(encoding="utf-8")
        self.assertIn('"iconos-programas-32.png"', fuente)
        self.assertIn('"iconos-programas-16.png"', fuente)
        self.assertIn('"veredicto_automatico": false', fuente)
        self.assertIn('Rect2(float(indice * tamano)', fuente)
        self.assertIn('"IconoAplicacion"', fuente)

    def test_workflow_publica_artifact_con_wrapper_local(self):
        flujo = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("Evidencia iconos programas 781", flujo)
        self.assertIn("capturar_iconos_programas_781.gd", flujo)
        self.assertIn("uses: ./.github/actions/upload-artifact", flujo)
        self.assertNotIn("actions/upload-artifact@", flujo)
        self.assertIn("iconos-programas-32.png", flujo)
        self.assertIn("iconos-programas-16.png", flujo)
        self.assertIn("manifest.json", flujo)

    def test_documentacion_mantiene_gate_humano(self):
        texto = README.read_text(encoding="utf-8")
        self.assertIn("#781", texto)
        self.assertIn("1920×1080", texto)
        self.assertIn("iconos-programas-32.png", texto)
        self.assertIn("iconos-programas-16.png", texto)
        self.assertIn("revisión humana", texto.lower())


if __name__ == "__main__":
    unittest.main()
