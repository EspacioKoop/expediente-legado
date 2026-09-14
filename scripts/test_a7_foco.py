from pathlib import Path
import unittest


RAIZ = Path(__file__).resolve().parents[1]
A7 = RAIZ / "godot" / "guion" / "acusacion_app.gd"


class FocoA7Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.codigo = A7.read_text(encoding="utf-8")

    def test_el_primer_control_recibe_foco_al_abrir(self):
        self.assertIn('_casillas[0].call_deferred("grab_focus")', self.codigo)
        self.assertIn('_declaracion.call_deferred("grab_focus")', self.codigo)

    def test_todos_los_interactivos_aceptan_foco(self):
        self.assertIn("control.focus_mode = Control.FOCUS_ALL", self.codigo)
        self.assertGreaterEqual(self.codigo.count("_hacer_enfocable("), 4)

    def test_el_recorrido_es_explicito_y_ciclico(self):
        for propiedad in (
            "focus_neighbor_top",
            "focus_neighbor_bottom",
            "focus_neighbor_left",
            "focus_neighbor_right",
            "focus_next",
            "focus_previous",
        ):
            self.assertIn(propiedad, self.codigo)
        self.assertIn("(i + 1) % controles.size()", self.codigo)
        self.assertIn("(i - 1 + controles.size()) % controles.size()", self.codigo)

    def test_presentar_solo_entra_en_la_cadena_cuando_esta_habilitado(self):
        self.assertIn("if not _presentar.disabled:", self.codigo)
        self.assertIn("controles.append(_presentar)", self.codigo)
        self.assertIn("_actualizar_vecinos_foco()", self.codigo)

    def test_ui_cancel_reutiliza_la_salida_del_formulario(self):
        self.assertIn('event.is_action_pressed("ui_cancel")', self.codigo)
        self.assertIn("cancelada.emit()", self.codigo)
        self.assertIn("get_viewport().set_input_as_handled()", self.codigo)

    def test_el_foco_tiene_marca_geometrica(self):
        self.assertIn('add_theme_stylebox_override("focus", foco)', self.codigo)
        for lado in ("left", "top", "right", "bottom"):
            self.assertIn(f"foco.border_width_{lado} = 2", self.codigo)

    def test_ui_accept_lo_resuelven_controles_base_button(self):
        # CheckBox y Button son BaseButton: al mantenerlos enfocables, Godot
        # resuelve ui_accept por la misma señal toggled/pressed que usa el ratón.
        self.assertIn("func _hacer_enfocable(control: BaseButton)", self.codigo)
        self.assertIn("casilla.toggled.connect", self.codigo)
        self.assertIn("_presentar.pressed.connect(_al_presentar)", self.codigo)

    def test_los_avisos_de_validacion_siguen_intactos(self):
        for clave in (
            "A7_FALTA_CASILLA",
            "A7_FALTA_DECLARACION",
            "A7_AVISO_CIERRE",
            "A7_SIN_JORNADA",
            "A7_YA_CERRADO",
        ):
            self.assertIn(f'tr("{clave}")', self.codigo)


if __name__ == "__main__":
    unittest.main()
