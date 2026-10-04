from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot/guion/dia_app.gd"
HELPER = ROOT / "godot/guion/dia_combate_pantalla_app.gd"


class DiaCombatePantalla1761Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.helper = HELPER.read_text(encoding="utf-8")

    def test_dia_conserva_autorizacion_y_wrappers(self):
        self.assertIn("func _abrir_combate_hack_slash(", self.dia)
        self.assertIn("func abrir_combate_real(", self.dia)
        self.assertIn("func _abrir_duelo(", self.dia)
        inicio = self.dia.index("func _abrir_combate_hack_slash(")
        fin = self.dia.index("func _cerrar_combate_hack_slash(", inicio)
        bloque = self.dia[inicio:fin]
        self.assertIn("CombateContextual.evaluar(", bloque)
        self.assertIn('decision.get("permitido", false)', bloque)
        self.assertIn("_combate_pantalla", bloque)\n        self.assertIn(". abrir(", bloque)

    def test_helper_posee_solo_lifecycle_visual(self):
        for token in (
            "CanvasLayer.new()",
            "DiaCombateContextualApp.new()",
            "app.terminado.connect(al_terminar)",
            "app.abrir(",
            "app.queue_free()",
            "pantalla.queue_free()",
        ):
            self.assertIn(token, self.helper)

        for prohibido in (
            "CombateContextual.evaluar",
            "Partida.guardar",
            "_entrar_en(",
            "combate_real_terminado.emit",
            "_rivales",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, self.helper)

    def test_dia_conserva_consecuencias_despues_de_limpieza(self):
        inicio = self.dia.index("func _cerrar_combate_hack_slash(")
        fin = self.dia.index("func _cerrar_expediente(", inicio)
        bloque = self.dia[inicio:fin]
        limpiar = bloque.index("_combate_pantalla.cerrar(")
        realidad = bloque.index("CombateContextual.PLANO_REALIDAD")
        self.assertLess(limpiar, realidad)
        self.assertIn("combate_real_terminado.emit", bloque)
        self.assertIn('_guardar_o_avisar("")', bloque)
        self.assertIn('_entrar_en("archivo")', bloque)
        self.assertIn("_rivales.erase(", bloque)

    def test_estado_compatible_sigue_en_dia(self):
        self.assertIn("var _combate_contextual_app: DiaCombateContextualApp", self.dia)\n        self.assertIn("var _combate_pantalla := DIA_COMBATE_PANTALLA_APP.new()", self.dia)
        self.assertIn("var _pantalla: CanvasLayer", self.dia)
        self.assertIn('_combate_contextual_app = montado["app"]', self.dia)
        self.assertIn('_pantalla = montado["pantalla"]', self.dia)


if __name__ == "__main__":
    unittest.main()
