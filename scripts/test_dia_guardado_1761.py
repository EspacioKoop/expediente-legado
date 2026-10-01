from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = (ROOT / "godot/guion/dia_app.gd").read_text(encoding="utf-8")
GUARDADO = (ROOT / "godot/guion/dia_guardado_app.gd").read_text(encoding="utf-8")


class DiaGuardado1761Test(unittest.TestCase):
    def test_dia_app_delega_y_reduce_la_responsabilidad(self):
        self.assertLess(len(DIA.splitlines()), 850)
        self.assertIn("var _guardado := DiaGuardadoApp.new()", DIA)
        self.assertNotIn('var _transito_pendiente := ""', DIA)

    def test_wrappers_historicos_permanecen_en_dia_app(self):
        self.assertIn("func _guardar_o_avisar(destino: String) -> bool:", DIA)
        self.assertIn("return _guardado.guardar(self, partida, destino)", DIA)
        self.assertIn("func _reintentar_guardado() -> void:", DIA)
        self.assertIn("_guardado.reintentar(self, partida, jornada)", DIA)

    def test_helper_posee_transito_y_reutiliza_partida(self):
        self.assertIn('var transito_pendiente := ""', GUARDADO)
        self.assertIn("if partida.guardar():", GUARDADO)
        self.assertIn('host.get_node_or_null("EscritorioSigaController")', GUARDADO)
        self.assertIn('escritorio_controller.guardar_estado_aplicaciones()', GUARDADO)
        self.assertIn("transito_pendiente = destino", GUARDADO)
        self.assertIn('host.set("_hablando", false)', GUARDADO)

    def test_reintento_no_repite_reglas_de_jornada(self):
        self.assertIn("var destino := transito_pendiente", GUARDADO)
        self.assertIn('host.call("_entrar_en", destino)', GUARDADO)
        self.assertIn('host.call("_sonar", "puerta_abre")', GUARDADO)
        for forbidden in (
            "Jornada.fichar",
            "Jornada.despertar",
            "Jornada.gastar",
            "Acusacion.",
            "Sellos.",
            "Partida.new()",
        ):
            self.assertNotIn(forbidden, GUARDADO)


if __name__ == "__main__":
    unittest.main()
