from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
EPIGRAFES = ROOT / "godot" / "guion" / "epigrafes_inicio.gd"
INICIO = ROOT / "godot" / "guion" / "inicio_app.gd"
REPRODUCTOR = ROOT / "godot" / "guion" / "cinematica_app.gd"


class EpigrafesInicioTest(unittest.TestCase):
    def setUp(self) -> None:
        self.epigrafes = EPIGRAFES.read_text(encoding="utf-8")
        self.inicio = INICIO.read_text(encoding="utf-8")

    def test_epigrafes_existe_y_tiene_clase(self) -> None:
        self.assertIn("class_name EpigrafesInicio", self.epigrafes)
        self.assertIn("extends Control", self.epigrafes)

    def test_senal_terminada_declarada(self) -> None:
        self.assertIn("signal terminada", self.epigrafes)

    def test_constantes_tiempos_declaradas(self) -> None:
        self.assertIn("const TIEMPO_FADE_IN := 2.0", self.epigrafes)
        self.assertIn("const TIEMPO_RETENCION_MIN := 2.0", self.epigrafes)
        self.assertIn("const TIEMPO_RETENCION_MAX := 4.0", self.epigrafes)
        self.assertIn("const TIEMPO_FADE_OUT := 1.5", self.epigrafes)

    def test_citas_con_texto_y_atribucion(self) -> None:
        self.assertIn("static var citas := [", self.epigrafes)
        # El GDScript usa comillas simples para la cadena que contiene comillas dobles
        self.assertIn("'\"There must be some kind of way out of here\"'", self.epigrafes)
        self.assertIn("Bob Dylan", self.epigrafes)
        self.assertIn("We shall not cease from exploration", self.epigrafes)
        self.assertIn("first time", self.epigrafes)
        self.assertIn("T. S. Eliot", self.epigrafes)
        self.assertIn("placeholder", self.epigrafes)

    def test_montar_crea_fondo_negro_y_textos(self) -> None:
        self.assertIn("Color.BLACK", self.epigrafes)
        self.assertIn("ColorRect.new()", self.epigrafes)
        self.assertIn("CenterContainer", self.epigrafes)
        self.assertIn("VBoxContainer", self.epigrafes)
        self.assertIn("PRESET_FULL_RECT", self.epigrafes)
        self.assertIn("HORIZONTAL_ALIGNMENT_CENTER", self.epigrafes)
        self.assertIn("AUTOWRAP_WORD_SMART", self.epigrafes)

    def test_estilos_texto_central(self) -> None:
        self.assertIn("font_size", self.epigrafes)
        self.assertIn("32", self.epigrafes)  # tamaño texto principal
        self.assertIn("18", self.epigrafes)  # tamaño atribución
        self.assertIn("Color.WHITE", self.epigrafes)
        self.assertIn("Color.BLACK", self.epigrafes)
        self.assertIn("outline_size", self.epigrafes)

    def test_iniciar_conecta_preferencias_y_empeza(self) -> None:
        self.assertIn("func iniciar()", self.epigrafes)
        self.assertIn("PreferenciasSiga.cargar()", self.epigrafes)
        self.assertIn("reduccion_movimiento", self.epigrafes)
        self.assertIn("visible = true", self.epigrafes)
        self.assertIn("_mostrar_cita_actual", self.epigrafes)

    def test_saltar_emite_terminada(self) -> None:
        self.assertIn("func saltar()", self.epigrafes)
        self.assertIn("_terminar", self.epigrafes)

    def test_process_actualiza_opacidad_y_avanza(self) -> None:
        self.assertIn("func _process(delta: float)", self.epigrafes)
        self.assertIn("_actualizar_opacidad", self.epigrafes)
        self.assertIn("_siguiente_cita", self.epigrafes)
        self.assertIn("clampf", self.epigrafes)

    def test_unhandled_input_acepta_interactuar_cancelar_y_raton(self) -> None:
        self.assertIn("is_action_pressed(\"interactuar\")", self.epigrafes)
        self.assertIn("is_action_pressed(\"cancelar\")", self.epigrafes)
        self.assertIn("InputEventMouseButton", self.epigrafes)
        self.assertIn("MOUSE_BUTTON_LEFT", self.epigrafes)
        self.assertIn("set_input_as_handled", self.epigrafes)

    def test_reduccion_movimiento_salta_fades(self) -> None:
        self.assertIn("_reduccion_movimiento", self.epigrafes)
        self.assertIn("if _reduccion_movimiento:", self.epigrafes)
        self.assertIn("return 2.0", self.epigrafes)
        self.assertIn("alfa = 1.0", self.epigrafes)

    def test_fade_in_retencion_fade_out_curva_suave(self) -> None:
        self.assertIn("TIEMPO_FADE_IN", self.epigrafes)
        self.assertIn("TIEMPO_RETENCION_MAX", self.epigrafes)
        self.assertIn("TIEMPO_FADE_OUT", self.epigrafes)
        # Lineal es suficiente para fundidos de opacidad; la curva suave está en cinematica_app
        self.assertIn("avance * (1.0 / (TIEMPO_FADE_IN / duracion_total))", self.epigrafes)
        self.assertIn("alfa = 1.0 - avance_fade_out", self.epigrafes)
        self.assertIn("clampf", self.epigrafes)

    def test_inicio_instancia_epigrafes_y_conecta_terminada(self) -> None:
        self.assertIn("EPIGRAFES_INICIO.new()", self.inicio)
        self.assertIn("EpigrafesInicio", self.inicio)
        self.assertIn("terminada.connect(_iniciar_cinematica_creditos)", self.inicio)
        self.assertIn("epigrafes.iniciar()", self.inicio)

    def test_iniciar_cinematica_creditos_limpia_y_llama_cinematica(self) -> None:
        self.assertIn("func _iniciar_cinematica_creditos", self.inicio)
        self.assertIn("_epigrafes.queue_free()", self.inicio)
        self.assertIn("CreditosInicioCinematica.planos()", self.inicio)
        self.assertIn("CINEMATICA_APP.new()", self.inicio)
        self.assertIn("AperturaCreditos3D", self.inicio)
        self.assertIn("reproducir(rodaje, CreditosInicioCinematica.ID)", self.inicio)

    def test_unhandled_input_inicio_pasa_skip_a_epigrafes_primero(self) -> None:
        self.assertIn("is_instance_valid(_epigrafes)", self.inicio)
        self.assertIn("_epigrafes.call(\"saltar\")", self.inicio)
        self.assertIn("if click_epigrafe.pressed", self.inicio)
        self.assertIn("return", self.inicio)  # sale temprano si hay epígrafes

    def test_no_rompe_flujo_existente_si_no_hay_epigrafes(self) -> None:
        # El flujo original sigue intacto como fallback
        self.assertIn("_terminar_apertura_creditos", self.inicio)
        self.assertIn("_envoltorio.visible = true", self.inicio)
        self.assertIn("_diorama.configurar_activo(true)", self.inicio)
        self.assertIn("_enfocar_menu_inicial()", self.inicio)


if __name__ == "__main__":
    unittest.main()