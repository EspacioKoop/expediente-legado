from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
APP = RAIZ / "godot" / "guion" / "reconstruccion_expediente_app.gd"
ESCENA = RAIZ / "godot" / "escenas" / "reconstruccion_expediente.tscn"
VISOR = RAIZ / "godot" / "guion" / "visor_expediente.gd"


class ReconstruccionUiTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.app = APP.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")
        cls.visor = VISOR.read_text(encoding="utf-8")

    def test_la_escena_usa_la_ui_de_reconstruccion(self):
        self.assertIn("res://guion/reconstruccion_expediente_app.gd", self.escena)
        self.assertIn('name="ReconstruccionExpediente"', self.escena)

    def test_la_ui_delega_validacion_y_persistencia_en_el_contrato(self):
        self.assertIn("ReconstruccionExpediente.validar(caso, _orden)", self.app)
        self.assertIn("ReconstruccionExpediente.guardar_mejor(", self.app)
        self.assertIn("ReconstruccionExpediente.mejor_guardado(", self.app)
        self.assertNotIn("Acusacion.acusar", self.app)
        self.assertNotIn("Jornada.gastar", self.app)

    def test_reordena_con_mando_o_teclado(self):
        self.assertIn('event.is_action_pressed("ui_up")', self.app)
        self.assertIn('event.is_action_pressed("ui_down")', self.app)
        self.assertIn('event.is_action_pressed("ui_cancel")', self.app)
        self.assertIn("_mover_seleccion(-1)", self.app)
        self.assertIn("_mover_seleccion(1)", self.app)
        self.assertIn("boton.gui_input.connect", self.app)

    def test_todos_los_interactivos_son_enfocables_y_el_recorrido_es_explicito(self):
        self.assertIn("control.focus_mode = Control.FOCUS_ALL", self.app)
        for propiedad in (
            "focus_neighbor_top",
            "focus_neighbor_bottom",
            "focus_neighbor_left",
            "focus_neighbor_right",
            "focus_next",
            "focus_previous",
        ):
            self.assertIn(propiedad, self.app)
        self.assertIn("(i + 1) % controles.size()", self.app)
        self.assertIn("(i - 1 + controles.size()) % controles.size()", self.app)

    def test_el_resultado_distingue_los_tres_estados(self):
        self.assertIn("ReconstruccionExpediente.COMPATIBLE", self.app)
        self.assertIn("ReconstruccionExpediente.CONTRADICCION", self.app)
        self.assertIn("ReconstruccionExpediente.DATO_AUSENTE", self.app)
        self.assertIn("ORDEN COMPATIBLE", self.app)
        self.assertIn("CONTRADICCIÓN", self.app)
        self.assertIn("DATO AUSENTE", self.app)

    def test_el_visor_solo_expone_documentos_leidos_del_caso(self):
        self.assertIn("func _ids_leidos_del_caso()", self.visor)
        self.assertIn('jornada.get("leido_hoy", [])', self.visor)
        self.assertIn('registro.get("folio")', self.visor)
        self.assertIn('registro.get("id", "")', self.visor)
        self.assertIn("panel.visibles = visibles", self.visor)

    def test_hacen_falta_dos_documentos_para_abrir_el_modo(self):
        self.assertIn("visibles.size() < 2", self.visor)
        self.assertIn("_reconstruir.disabled = _ids_leidos_del_caso().size() < 2", self.visor)

    def test_la_ui_se_abre_y_vuelve_al_visor_sin_bloquear_el_flujo(self):
        self.assertIn("res://escenas/reconstruccion_expediente.tscn", self.visor)
        self.assertIn("panel.cerrada.connect(_cerrar_reconstruccion.bind(panel))", self.visor)
        self.assertIn("_reconstruir.grab_focus()", self.visor)
        self.assertIn('Callable(self, "_guardar_o_avisar")', self.visor)


if __name__ == "__main__":
    unittest.main()
