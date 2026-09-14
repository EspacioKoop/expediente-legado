from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
CONTROLADOR = RAIZ / "godot" / "guion" / "dia_hud_fases_app.gd"
ESCENA = RAIZ / "godot" / "escenas" / "dia.tscn"


class HudFasesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_estado_permanente_se_limita_al_archivo(self):
        cuerpo = self.controlador.split("func _sincronizar_estado_hud", 1)[1]
        self.assertIn('if fase == "archivo":', cuerpo)
        self.assertIn("hud.activar(HUDLayer.ESTADO)", cuerpo)
        self.assertIn("hud.desactivar(HUDLayer.ESTADO)", cuerpo)

    def test_cambiar_fase_no_apaga_el_arbitro_completo(self):
        cuerpo = self.controlador.split("func _sincronizar_estado_hud", 1)[1]
        self.assertNotIn("visible = false", cuerpo)
        self.assertNotIn("INTERACCION", cuerpo)
        self.assertNotIn("DIALOGO", cuerpo)
        self.assertNotIn("MODAL", cuerpo)

    def test_la_escena_conserva_raiz_historica_y_anade_controller(self):
        self.assertIn('path="res://guion/dia_clima_app.gd" id="1"', self.escena)
        self.assertIn('path="res://guion/dia_hud_fases_app.gd" id="11"', self.escena)
        self.assertIn('[node name="HUDFasesController" type="Node" parent="."]', self.escena)
        self.assertIn('script = ExtResource("11")', self.escena)


if __name__ == "__main__":
    unittest.main()
