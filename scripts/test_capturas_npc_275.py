from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CAPTURAS = RAIZ / "godot/pruebas/capturas_npc_275.gd"
WORKFLOW = RAIZ / ".github/workflows/npc-visual-gate-275.yml"


class CapturasNpc275Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.capturas = CAPTURAS.read_text(encoding="utf-8")
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_recorre_roster_completo_y_pipeline_real(self):
        self.assertIn("[Companeros.CUNADO] + Array(Companeros.ROSTER)", self.capturas)
        self.assertIn("Modelos.persona(", self.capturas)
        self.assertIn('has_meta("vestuario_humano_275")', self.capturas)
        self.assertIn('has_meta("correccion_visual_275")', self.capturas)

    def test_cubre_frente_tres_cuartos_y_detalle_historico(self):
        for vista in ("frente", "tres_cuartos", "perfil", "primer_plano"):
            self.assertIn(f'"nombre": "{vista}"', self.capturas)
        self.assertIn("if not retrato.is_empty():", self.capturas)
        self.assertIn("vistas.append_array(VISTAS_HISTORICAS)", self.capturas)

    def test_captura_render_real_y_persistente(self):
        self.assertIn("RenderingServer.frame_post_draw", self.capturas)
        self.assertIn("_viewport.get_texture().get_image()", self.capturas)
        self.assertIn("imagen.save_png(ruta)", self.capturas)
        self.assertIn('"README.md"', self.capturas)

    def test_workflow_publica_artefacto_para_revision_humana(self):
        self.assertIn("Generar capturas comparativas NPC #275", self.workflow)
        self.assertIn("xvfb-run -a godot4", self.workflow)
        self.assertIn("res://pruebas/capturas_npc_275.gd", self.workflow)
        self.assertIn("SIGA-98-npc-visual-gate-275-${{ github.sha }}", self.workflow)
        self.assertIn("dist/capturas-npc-275", self.workflow)
        self.assertIn("retention-days: 14", self.workflow)


if __name__ == "__main__":
    unittest.main()
