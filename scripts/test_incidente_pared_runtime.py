from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONTROLLER = ROOT / "godot" / "guion" / "dia_incidente_pared_app.gd"
INTERACTUABLE = ROOT / "godot" / "guion" / "interactuable_3d.gd"
COMPANEROS = ROOT / "godot" / "guion" / "dia_companeros_idle_app.gd"
IDLE = ROOT / "godot" / "guion" / "companero_idle_3d.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"


class IncidenteParedRuntimeContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.interactuable = INTERACTUABLE.read_text(encoding="utf-8")
        cls.companeros = COMPANEROS.read_text(encoding="utf-8")
        cls.idle = IDLE.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_dia_monta_controller_del_incidente(self):
        self.assertIn('path="res://guion/dia_incidente_pared_app.gd"', self.escena)
        self.assertIn('[node name="IncidenteParedController"', self.escena)

    def test_pared_reutiliza_interactuable_semantico(self):
        for token in (
            "Interactuable3D.new()",
            "Interactuable3D.Verbo.GOLPEAR",
            'pared.name = "ParedGolpeableOficina"',
            "CollisionShape3D.new()",
            "BoxShape3D.new()",
        ):
            self.assertIn(token, self.controller)
        self.assertIn("GOLPEAR", self.interactuable)
        self.assertIn('Verbo.GOLPEAR: "Golpear"', self.interactuable)

    def test_consumo_del_resultado_persistente(self):
        self.assertIn("IncidentesConducta.registrar_en_partida(", self.controller)
        self.assertIn("IncidentesConducta.GOLPE_PARED", self.controller)
        self.assertIn("IncidentesConducta.OFICINA", self.controller)
        self.assertIn('resultado.get("reaccion", "")', self.controller)
        self.assertIn('resultado.get("fin_jornada", false)', self.controller)
        self.assertIn('resultado.get("despido", false)', self.controller)

    def test_primer_incidente_envia_a_casa_sin_fichar(self):
        self.assertIn('dia._entrar_en("casa")', self.controller)
        self.assertIn('dia._guardar_o_avisar("")', self.controller)
        self.assertNotIn("Jornada.fichar_salida", self.controller)
        for forbidden in ('["dinero"]', '["acciones"]', "Jornada.gastar"):
            self.assertNotIn(forbidden, self.controller)

    def test_reincidencia_reutiliza_despido_existente(self):
        self.assertIn("Acusacion.perder_vida", self.controller)
        self.assertIn("dia._reasignar()", self.controller)
        self.assertNotIn("Prometeo.reiniciar_vuelta", self.controller)
        self.assertNotIn("Jornada.reiniciar_vuelta", self.controller)

    def test_companeros_reciben_reaccion_de_huida(self):
        self.assertIn('get_node_or_null("CompanerosIdleController")', self.controller)
        self.assertIn('controller.has_method("huir_de")', self.controller)
        self.assertIn("func huir_de(origen_global: Vector3)", self.companeros)
        self.assertIn("idle.huir_de(origen_global)", self.companeros)
        self.assertIn("func huir_de(origen_global: Vector3)", self.idle)
        self.assertIn('tween_property(objetivo, "position"', self.idle)

    def test_golpe_tiene_feedback_y_bloquea_doble_input(self):
        self.assertIn("Sonido.impacto_careo()", self.controller)
        self.assertIn("pared.habilitado = false", self.controller)
        self.assertIn("dia._caminante.set_physics_process(false)", self.controller)
        self.assertIn("DEMORA_TRANSICION", self.controller)


if __name__ == "__main__":
    unittest.main()
