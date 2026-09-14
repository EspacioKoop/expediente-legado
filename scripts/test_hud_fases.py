from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
DIA = RAIZ / "godot" / "guion" / "dia_hud_fases_app.gd"
ESCENA = RAIZ / "godot" / "escenas" / "dia.tscn"


class HudFasesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_estado_permanente_se_limita_al_archivo(self):
        self.assertIn("_sincronizar_estado_hud(fase)", self.dia)
        cuerpo = self.dia.split("func _sincronizar_estado_hud", 1)[1].split("\n\n", 1)[0]
        self.assertIn('if fase == "archivo":', cuerpo)
        self.assertIn("_hud_prioridades.activar(HUDLayer.ESTADO)", cuerpo)
        self.assertIn("_hud_prioridades.desactivar(HUDLayer.ESTADO)", cuerpo)

    def test_cambiar_fase_no_apaga_el_arbitro_completo(self):
        cuerpo = self.dia.split("func _sincronizar_estado_hud", 1)[1].split("\n\n", 1)[0]
        self.assertNotIn("_hud_prioridades.visible = false", cuerpo)
        self.assertNotIn("INTERACCION", cuerpo)
        self.assertNotIn("DIALOGO", cuerpo)
        self.assertNotIn("MODAL", cuerpo)

    def test_la_escena_usa_la_capa_de_hud_por_fases(self):
        self.assertIn('path="res://guion/dia_hud_fases_app.gd" id="1"', self.escena)
        self.assertNotIn('path="res://guion/dia_clima_app.gd" id="1"', self.escena)


if __name__ == "__main__":
    unittest.main()
