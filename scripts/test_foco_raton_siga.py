from pathlib import Path
import unittest

from scripts.godot_pruebas import comprobar_contrato


ROOT = Path(__file__).resolve().parents[1]
CAMINANTE = ROOT / "godot" / "guion" / "caminante.gd"
ESCRITORIO = ROOT / "godot" / "guion" / "escritorio_siga_visual.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_escritorio_siga_app.gd"


class FocoRatonSigaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.caminante = CAMINANTE.read_text(encoding="utf-8")
        cls.escritorio = ESCRITORIO.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")

    def test_recaptura_exige_clic_deliberado_y_caminante_activo(self):
        self.assertIn("static func debe_recapturar_raton", self.caminante)
        for boton in ["MOUSE_BUTTON_LEFT", "MOUSE_BUTTON_RIGHT", "MOUSE_BUTTON_MIDDLE"]:
            self.assertIn(boton, self.caminante)
        self.assertIn("is_physics_processing()", self.caminante)
        self.assertIn("get_tree().paused", self.caminante)

    def test_escritorio_recupera_foco_por_acciones_ui(self):
        self.assertIn("func recuperar_foco", self.escritorio)
        for accion in [
            "ui_up",
            "ui_down",
            "ui_left",
            "ui_right",
            "ui_accept",
            "ui_focus_next",
            "ui_focus_prev",
        ]:
            self.assertIn(accion, self.escritorio)
        self.assertIn("_boton_menu_visual", self.escritorio)
        self.assertIn("_modal_id", self.escritorio)

    def test_menu_global_ofrece_salida_de_rescate_del_puesto(self):
        self.assertIn('get_node_or_null("/root/MenuGlobal")', self.controlador)
        self.assertIn('name = "SalirPuestoSiga"', self.controlador)
        self.assertIn('tr("PUESTO_LEVANTARSE")', self.controlador)
        self.assertIn("pressed.connect(_salir_desde_menu_global)", self.controlador)
        self.assertIn('_menu_global.call("_cerrar")', self.controlador)
        self.assertIn("dia._cerrar_expediente()", self.controlador)
        self.assertIn("_boton_salida_menu_global.queue_free()", self.controlador)

    def test_contrato_runtime(self):
        comprobar_contrato(
            self,
            "pruebas/pruebas_foco_raton_siga.gd",
            "Foco/ratón #793: OK",
            timeout=60,
        )


if __name__ == "__main__":
    unittest.main()
