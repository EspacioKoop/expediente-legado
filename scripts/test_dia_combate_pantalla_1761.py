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

    def test_helper_posee_solo_lifecycle_visual(self):
        self.assertIn("class_name DiaCombatePantallaApp", self.helper)
        self.assertIn("CanvasLayer.new()", self.helper)
        self.assertIn("DiaCombateContextualApp.new()", self.helper)
        self.assertIn("anfitrion.add_child(_app)", self.helper)
        self.assertIn("_app.terminado.connect(al_terminar)", self.helper)
        self.assertIn("_app.abrir(", self.helper)
        self.assertIn("func cerrar() -> void:", self.helper)

        for prohibido in (
            "CombateContextual.evaluar",
            "Partida.guardar",
            "_entrar_en(",
            "combate_real_terminado.emit",
            "_rivales",
        ):
            with self.subTest(prohibido=prohibido):
                self.assertNotIn(prohibido, self.helper)

    def test_dia_conserva_autorizacion_y_consecuencias(self):
        inicio = self.dia.index("func _abrir_combate_hack_slash")
        fin = self.dia.index("func _cerrar_combate_hack_slash", inicio)
        apertura = self.dia[inicio:fin]
        self.assertIn("CombateContextual.evaluar(", apertura)
        self.assertIn('decision.get("permitido", false)', apertura)
        self.assertIn("_combate_pantalla.abrir(", apertura)

        cierre = self.dia[fin : self.dia.index("func _cerrar_expediente", fin)]
        self.assertIn("_combate_pantalla.cerrar()", cierre)
        self.assertIn("combate_real_terminado.emit", cierre)
        self.assertIn("_guardar_o_avisar", cierre)
        self.assertIn('_entrar_en("archivo")', cierre)
        self.assertIn("_rivales.erase", cierre)

    def test_wrappers_publicos_siguen_en_dia(self):
        self.assertIn("func _abrir_duelo(", self.dia)
        self.assertIn("func abrir_combate_real(", self.dia)
        self.assertIn("func _abrir_combate_hack_slash(", self.dia)
        self.assertIn("var _combate_contextual_app: DiaCombateContextualApp", self.dia)
        self.assertIn("var _pantalla: CanvasLayer", self.dia)


if __name__ == "__main__":
    unittest.main()
