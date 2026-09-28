from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
ENTORNO = ROOT / "godot" / "guion" / "dia_entorno_app.gd"
CIELO = ROOT / "godot" / "guion" / "dia_cielo_app.gd"


class DiaEntorno1761Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.entorno = ENTORNO.read_text(encoding="utf-8")
        cls.cielo = CIELO.read_text(encoding="utf-8")

    def test_dia_conserva_hook_y_campos_historicos(self):
        bloque = self.dia.split("func _montar_entorno() -> void:", 1)[1].split(
            "func _montar_interfaz", 1
        )[0]
        self.assertIn("DiaEntornoApp.montar(self, partida.estado)", bloque)
        self.assertIn('_ambiente = entorno["ambiente"]', bloque)
        self.assertIn('_sol = entorno["sol"]', bloque)
        self.assertIn('_caminante = entorno["caminante"]', bloque)
        self.assertIn("super._montar_entorno()", self.cielo)

    def test_render_y_cuerpo_viven_en_constructor(self):
        for token in (
            "WorldEnvironment.new()",
            "Environment.new()",
            "ssao_enabled = true",
            "ssil_enabled = true",
            "DirectionalLight3D.new()",
            'load("res://escenas/caminante.tscn")',
            "FiltroPantalla.aplicar",
        ):
            self.assertIn(token, self.entorno)
            self.assertNotIn(token, self.dia)

    def test_constructor_no_decide_jornada(self):
        for token in (
            "Jornada.",
            "_entrar_en",
            "_guardar_o_avisar",
            "Sueno.",
            "Acusacion.",
        ):
            self.assertNotIn(token, self.entorno)

    def test_dia_baja_de_700_lineas(self):
        self.assertLess(len(self.dia.splitlines()), 700)


if __name__ == "__main__":
    unittest.main()
