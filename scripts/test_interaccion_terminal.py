from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CAPA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
CATALOGO = ROOT / "godot" / "guion" / "espacios_catalogo.gd"


class InteraccionTerminalTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.capa = CAPA.read_text(encoding="utf-8")
        cls.catalogo = CATALOGO.read_text(encoding="utf-8")

    def test_reutiliza_el_puesto_real_del_catalogo(self):
        self.assertIn('"destino": "expediente"', self.catalogo)
        self.assertIn('"rotulo": "SALIDA_PUESTO"', self.catalogo)
        self.assertIn('_buscar_zona_destino(_mundo, "expediente")', self.capa)

    def test_desactiva_el_trigger_automatico_y_su_colision(self):
        self.assertIn("zona.monitoring = false", self.capa)
        self.assertIn("zona.monitorable = false", self.capa)
        self.assertIn("zona.collision_layer = 0", self.capa)

    def test_monta_interactuable_con_verbo_usar(self):
        self.assertIn("Interactuable3D.new()", self.capa)
        self.assertIn("Interactuable3D.Verbo.USAR", self.capa)
        self.assertIn('terminal.name = "TerminalSIGAInteractuable"', self.capa)
        self.assertIn("BoxShape3D.new()", self.capa)
        self.assertIn("TAM_TERMINAL_INTERACTIVO", self.capa)

    def test_reutiliza_la_apertura_existente_sin_duplicar_estado(self):
        self.assertIn("terminal.activado.connect(_activar_terminal_siga)", self.capa)
        self.assertIn("_abrir_expediente()", self.capa)
        self.assertIn('_sonar("documento")', self.capa)
        callback = self.capa.split("func _activar_terminal_siga", 1)[1].split(
            "func _buscar_zona_destino", 1
        )[0]
        for prohibido in ("Partida.new()", "Jornada.", "pistas_descubiertas", "visor.tscn"):
            self.assertNotIn(prohibido, callback)

    def test_solo_se_monta_en_archivo(self):
        bloque = self.capa.split("func _entrar_en(fase: String) -> void:", 1)[1].split(
            "func _montar_terminal_interactivo", 1
        )[0]
        self.assertIn('if fase == "archivo":', bloque)
        self.assertIn("_montar_terminal_interactivo()", bloque)


if __name__ == "__main__":
    unittest.main()
