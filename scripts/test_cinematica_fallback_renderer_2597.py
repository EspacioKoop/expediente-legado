"""Prueba de contrato del fallback de cámara para Compatibility (#2597)."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CINE = (ROOT / "godot/guion/cinematica_app.gd").read_text(encoding="utf-8")
PROJECT = (ROOT / "godot/project.godot").read_text(encoding="utf-8")


class RenderizadorCinematicaTest(unittest.TestCase):
    def test_renderer_principal_no_se_degrada(self):
        self.assertIn('renderer/rendering_method="forward_plus"', PROJECT)

    def test_compatibilidad_no_aplica_dof_incompatible(self):
        metodo = 'RenderingServer.get_current_rendering_method() == "gl_compatibility"'
        self.assertIn(metodo, CINE)
        guardia = CINE.split(metodo, 1)[1].split("return", 1)[0]
        self.assertIn("_camara.attributes = null", guardia)

    def test_forward_plus_preserva_fov_y_profundidad_de_campo(self):
        self.assertIn("_camara.fov = LenguajeCine.fov_de(plano)", CINE)
        self.assertIn(
            "_camara.attributes = LenguajeCine.atributos(LenguajeCine.foco_de(plano, camara, mira))",
            CINE,
        )


if __name__ == "__main__":
    unittest.main()
