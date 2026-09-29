from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "godot" / "guion" / "llamadas_internas.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_llamadas_internas_app.gd"
IDLE = ROOT / "godot" / "guion" / "dia_companeros_idle_app.gd"
SCENE = ROOT / "godot" / "escenas" / "dia.tscn"


class LlamadasInternas1769Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = CORE.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.idle = IDLE.read_text(encoding="utf-8")
        cls.scene = SCENE.read_text(encoding="utf-8")

    def test_tres_variantes_y_maximo_dos(self):
        for tipo in ("companero", "administrativo", "equivocada"):
            self.assertIn(f'"id": "{tipo}"', self.core)
        self.assertIn("const MAX_LLAMADAS := 2", self.core)
        self.assertIn("Jornada.hora_minutos(jornada)", self.core)

    def test_no_se_superpone_con_superficies_modales(self):
        for guard in (
            'dia.get("_pantalla") != null',
            'dia.get("_entrada") != null',
            'is_instance_valid(dia.get("_dialogo_actual"))',
            "dia.partida.guardado_pendiente",
            "caminante.is_physics_processing()",
        ):
            self.assertIn(guard, self.controller)

    def test_usa_interaccion_y_rutina_existentes(self):
        self.assertIn("Interactuable3D.new()", self.controller)
        self.assertIn("CompanerosIdleController", self.controller)
        self.assertIn('has_method("reaccion_llamada_interna")', self.controller)
        self.assertIn("func reaccion_llamada_interna() -> bool:", self.idle)
        self.assertIn("idle.conversar(true)", self.idle)
        self.assertIn("idle.conversar(false)", self.idle)

    def test_ignorar_es_salida_segura(self):
        self.assertIn("const DURACION_TIMBRE := 10.0", self.controller)
        self.assertIn("LlamadasInternas.cancelar_activa", self.controller)
        self.assertIn('"resultado": resultado', self.core)
        for forbidden in (
            "Jornada.gastar",
            "Pistas",
            "Veredicto",
            "Sellos.registrar",
            "Inventario",
        ):
            self.assertNotIn(forbidden, self.core + self.controller)

    def test_controller_esta_montado_como_hijo(self):
        self.assertIn('path="res://guion/dia_llamadas_internas_app.gd"', self.scene)
        self.assertIn('[node name="LlamadasInternasController" type="Node" parent="."]', self.scene)


if __name__ == "__main__":
    unittest.main()
