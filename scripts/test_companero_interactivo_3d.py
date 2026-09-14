from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "companero_interactivo_3d.gd"


class CompaneroInteractivo3DTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")

    def test_reutiliza_contrato_de_interaccion_3d(self):
        self.assertIn("extends Interactuable3D", self.source)
        self.assertIn("func texto_accion()", self.source)
        self.assertIn('return "Hablar con %s" % nombre', self.source)

    def test_conversacion_requiere_interaccion_explicita(self):
        self.assertIn("func interactuar(actor: Node) -> bool:", self.source)
        self.assertIn("conversacion_solicitada.emit", self.source)
        self.assertNotIn("body_entered.connect", self.source)
        self.assertNotIn("_physics_process", self.source)
        self.assertNotIn("randf", self.source)

    def test_fuente_de_dialogo_es_un_npc_concreto(self):
        self.assertIn("companero: CompaneroInteractivo3D", self.source)
        self.assertIn("@export var nombre_visible", self.source)
        self.assertIn("@export var clave_dialogo", self.source)
        self.assertIn("conversacion_solicitada.emit(self, actor, clave_dialogo)", self.source)

    def test_identificacion_visual_solo_en_foco(self):
        self.assertIn("Label3D.new()", self.source)
        self.assertIn('name = "IndicadorConversacion"', self.source)
        self.assertIn('_indicador.text = "◆"', self.source)
        self.assertIn("_indicador.visible = false", self.source)
        self.assertIn("func marcar_en_foco(en_foco: bool)", self.source)
        self.assertIn("_indicador.visible = en_foco and habilitado", self.source)

    def test_tiene_volumen_de_raycast_sin_trigger_de_proximidad(self):
        self.assertIn("CollisionShape3D.new()", self.source)
        self.assertIn("BoxShape3D.new()", self.source)
        self.assertIn("const TAM_COLISION", self.source)
        self.assertNotIn("monitoring", self.source)

    def test_no_hardcodea_entrada_fisica(self):
        self.assertNotIn('"E"', self.source)
        self.assertNotIn("KEY_", self.source)
        self.assertNotIn("JOY_BUTTON", self.source)


if __name__ == "__main__":
    unittest.main()
