"""El gate visual de #795 exige imágenes reales, no aprobaciones por tests.

Este contrato conserva la separación: renderiza en Godot, adjunta el resultado
como artefacto de CI y deja el veredicto de ritmo/legibilidad a la revisión
humana. No se almacenan PNG/JPG renderizados en el repositorio público.
"""

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CAPTURA = ROOT / "godot/pruebas/capturar_creditos_795.gd"
WORKFLOW = ROOT / ".github/workflows/evidencia-creditos-795.yml"


class EvidenciaCreditos795Test(unittest.TestCase):
    def setUp(self) -> None:
        self.captura = CAPTURA.read_text(encoding="utf-8")
        self.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_reproductor_y_renderizado_reales(self) -> None:
        self.assertIn('preload("res://escenas/cinematica.tscn")', self.captura)
        self.assertIn("CreditosInicioCinematica.planos()", self.captura)
        self.assertIn("reproductor.reproducir([plano])", self.captura)
        self.assertIn("root.get_texture().get_image()", self.captura)
        self.assertIn('== "forward_plus"', self.captura)
        self.assertIn("--rendering-method forward_plus", self.workflow)
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("mesa-vulkan-drivers", self.workflow)

    def test_40_planos_y_tres_variantes_reducidas(self) -> None:
        self.assertIn("const ANCHO := 1920", self.captura)
        self.assertIn("const ALTO := 1080", self.captura)
        self.assertIn("const INDICES_REDUCIDOS := [0, 24, 39]", self.captura)
        self.assertIn("for i in planos.size():", self.captura)
        self.assertIn("await _capturar_plano(reproductor, planos[i], i, false)", self.captura)
        self.assertIn("reproductor.set(\"_reduccion_movimiento\", true)", self.captura)
        self.assertIn("contacto_creditos_795.png", self.captura)
        self.assertIn("Image.INTERPOLATE_BILINEAR", self.captura)

    def test_garantias_de_evidencia_y_integridad(self) -> None:
        self.assertIn("imagen.save_jpg(ruta, 0.88)", self.captura)
        self.assertIn("FileAccess.get_sha256(ruta)", self.captura)
        self.assertIn('archivo.stat().st_size > 12000', self.workflow)
        self.assertIn("hashlib.sha256(archivo.read_bytes()).hexdigest()", self.workflow)
        self.assertIn("datos[\"veredicto_automatico\"] is False", self.workflow)
        self.assertIn("datos[\"requiere_revision_humana\"] is True", self.workflow)
        self.assertIn("retention-days: 14", self.workflow)
        self.assertIn("if-no-files-found: error", self.workflow)

    def test_aislamiento_y_principio_de_minimos_privilegios(self) -> None:
        self.assertIn("permissions:\n  contents: read", self.workflow)
        self.assertIn("persist-credentials: false", self.workflow)
        self.assertNotIn("Partida.guardar", self.captura)
        self.assertNotIn("Jornada.dormir", self.captura)
        self.assertNotIn("secrets.", self.workflow)
        self.assertNotIn("pull_request_target:", self.workflow)


if __name__ == "__main__":
    unittest.main()
