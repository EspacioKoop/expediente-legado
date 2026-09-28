from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
GUARDADO = ROOT / "godot" / "guion" / "dia_guardado_app.gd"


class DiaGuardado1761Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.guardado = GUARDADO.read_text(encoding="utf-8")

    def test_dia_mantiene_api_pero_no_estado_de_transito(self):
        self.assertIn("func _guardar_o_avisar(destino: String) -> bool:", self.dia)
        self.assertIn("func _reintentar_guardado() -> void:", self.dia)
        self.assertIn("DiaGuardadoApp.new()", self.dia)
        self.assertNotIn('var _transito_pendiente := ""', self.dia)
        self.assertIn('var _transito_pendiente := ""', self.guardado)

    def test_guardado_real_y_apps_viven_en_controlador(self):
        self.assertIn("if _partida.guardar():", self.guardado)
        self.assertIn('get_node_or_null("EscritorioSigaController")', self.guardado)
        self.assertIn('has_method("guardar_estado_aplicaciones")', self.guardado)
        self.assertNotIn('get_node_or_null("EscritorioSigaController")', self.dia)

    def test_reintento_no_reaplica_reglas_de_jornada(self):
        bloque = self.guardado.split("func reintentar_guardado(", 1)[1].split(
            "func destino_pendiente", 1
        )[0]
        self.assertIn("guardar_o_avisar(destino)", bloque)
        self.assertIn('sonar.call("puerta_abre")', bloque)
        self.assertIn("entrar_en.call(destino)", bloque)
        for prohibido in (
            "Jornada.fichar_salida",
            "Jornada.dormir",
            "Jornada.despertar",
            "Jornada.gastar",
            "Sellos.",
            "Acusacion.",
        ):
            self.assertNotIn(prohibido, bloque)

    def test_dia_recupera_margen_estructural(self):
        self.assertLess(len(self.dia.splitlines()), 850)


if __name__ == "__main__":
    unittest.main()
