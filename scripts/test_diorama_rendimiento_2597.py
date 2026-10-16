"""Regresión de render del menú 3D y parpadeo visual (#2597).

El test de Godot ejercita cambios de estado reales de SubViewport y luz.
Las comprobaciones declarativas solo protegen que el límite no se extienda
accidentalmente a las ventanas del mundo jugable.
"""

from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
DIORAMA = ROOT / "godot" / "guion" / "inicio_diorama_3d.gd"
EXTERIOR = ROOT / "godot" / "guion" / "ventana_exterior_3d.gd"
PRUEBA = "res://pruebas/pruebas_diorama_render_2597.gd"


class DioramaRendimiento2597Test(unittest.TestCase):
    def test_menu_conserva_resolucion_y_fondo_cinematico(self):
        texto = DIORAMA.read_text(encoding="utf-8")
        self.assertIn("TAM_VIEWPORT := Vector2i(384, 216)", texto)
        self.assertIn("limitar_refresco_para_menu(true)", texto)
        self.assertIn("SubViewport.UPDATE_ONCE", texto)
        self.assertIn("SubViewport.UPDATE_DISABLED", texto)
        self.assertNotIn("SubViewport.UPDATE_ALWAYS", texto)
        self.assertIn("DURACION_PARPADEO := 0.12", texto)
        self.assertIn("ENERGIA_AMBIENTAL_BASE := 0.42", texto)

    def test_ventanas_ajenas_al_menu_siguen_a_fps_nativos(self):
        texto = EXTERIOR.read_text(encoding="utf-8")
        self.assertIn("TAM_VIEWPORT := Vector2i(320, 180)", texto)
        self.assertIn("var _render_limitado_menu := false", texto)
        self.assertIn("SubViewport.UPDATE_ALWAYS", texto)
        self.assertIn("SubViewport.UPDATE_ONCE", texto)
        self.assertIn("SubViewport.UPDATE_DISABLED", texto)

    def test_logica_de_render_y_parpadeo_en_motor_godot(self):
        comprobar_contrato(self, PRUEBA, "20 pasadas, 0 fallos", timeout=45)


if __name__ == "__main__":
    unittest.main()
