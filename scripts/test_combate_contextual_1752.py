from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
POLITICA = ROOT / "godot" / "guion" / "combate_contextual.gd"
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_combate_contextual_app.gd"
PARED = ROOT / "godot" / "guion" / "dia_incidente_pared_app.gd"
CONDUCTA = ROOT / "godot" / "guion" / "incidentes_conducta.gd"
PREFERENCIAS = ROOT / "godot" / "guion" / "preferencias_siga.gd"


class CombateContextual1752Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.politica = POLITICA.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.pared = PARED.read_text(encoding="utf-8")
        cls.conducta = CONDUCTA.read_text(encoding="utf-8")
        cls.preferencias = PREFERENCIAS.read_text(encoding="utf-8")

    def test_sueno_delega_permiso_en_sueno_combate(self):
        self.assertIn('fase == "sueño"', self.politica)
        self.assertIn("SuenoCombate.se_pelea(objetivo, estado)", self.politica)
        self.assertIn('"plano": PLANO_SUENO', self.politica)

    def test_realidad_exige_permiso_y_consecuencia(self):
        self.assertIn('objetivo.get("combate_autorizado", false)', self.politica)
        self.assertIn('objetivo.get("consecuencia_combate", {})', self.politica)
        self.assertIn("and consecuencia_valida", self.politica)
        self.assertIn('"accion": ACCION_CONDUCTA', self.politica)
        self.assertIn('"genera_momentum": false', self.politica)

    def test_duelo_onirico_abre_hack_and_slash_3d(self):
        inicio = self.dia.index("func _abrir_duelo(")
        fin = self.dia.index("func _cerrar_expediente()", inicio)
        bloque = self.dia[inicio:fin]
        self.assertIn("CombateContextual.evaluar", bloque)
        self.assertIn("DiaCombateContextualApp.new()", bloque)
        self.assertNotIn("SuenoDuelo.new()", bloque)
        self.assertIn("JuicioCombate3D.new()", self.controlador)
        self.assertIn("_hacer_actual_camara()", self.controlador)
        self.assertIn("SuenoCombate.resolver", self.controlador)
        self.assertNotIn("JuicioCombate3D.new()", bloque)

    def test_host_contextual_conserva_partida_para_capa_simbolica(self):
        self.assertIn("var partida: Partida", self.controlador)
        self.assertIn("partida = partida_actual", self.controlador)
        self.assertIn('partida.estado.get("perfil_jugador", {})', self.controlador)
        self.assertIn("partida.estado,", self.controlador)
        self.assertIn("\t\t\tpartida,\n", self.dia)

    def test_realidad_expone_entrada_autorizada_y_consecuencia(self):
        self.assertIn("func abrir_combate_real(objetivo: Dictionary) -> bool:", self.dia)
        self.assertIn("CombateContextual.PLANO_REALIDAD", self.dia)
        self.assertIn("signal combate_real_terminado(", self.dia)
        self.assertIn('decision.get("consecuencia", {})', self.dia)

    def test_punetazo_pared_sigue_siendo_incidente_no_combate(self):
        self.assertIn("IncidentesConducta.registrar_en_partida(", self.pared)
        self.assertIn("IncidentesConducta.GOLPE_PARED", self.pared)
        self.assertIn('const GOLPE_PARED := "golpe_pared"', self.conducta)
        self.assertIn('return _resultado(true, "huir", true, reincidencia, true)', self.conducta)
        self.assertNotIn("GestorMomentum", self.pared)

    def test_interactuar_no_se_convierte_en_ataque_global(self):
        self.assertIn('"interactuar": {"teclado": 69, "mando": JOY_BUTTON_A}', self.preferencias)
        self.assertNotIn('"attack":', self.preferencias)
        self.assertNotIn('"heavy_attack":', self.preferencias)


if __name__ == "__main__":
    unittest.main()
