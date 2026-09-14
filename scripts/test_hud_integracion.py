from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot" / "guion"


class HUDIntegracionTest(unittest.TestCase):
    def setUp(self):
        self.dia = (GUION / "dia_clima_app.gd").read_text(encoding="utf-8")
        self.caminante = (GUION / "caminante.gd").read_text(encoding="utf-8")

    def test_frases_de_companeros_no_se_disparan_por_proximidad(self):
        self.assertIn("_desactivar_frases_proximidad(_mundo)", self.dia)
        self.assertIn("hijo.monitoring = false", self.dia)
        self.assertIn("hijo.monitorable = false", self.dia)
        self.assertIn('salida.get_meta("frase", "")', self.dia)
        self.assertIn("return\n\n\tsuper._al_pisar_salida", self.dia)

    def test_oficina_monta_npcs_conversables_en_posicion_de_figura(self):
        self.assertIn("CompaneroInteractivo3D.new()", self.dia)
        self.assertIn('companero.position = figura["pos"]', self.dia)
        self.assertIn("companero.nombre_visible", self.dia)
        self.assertIn("companero.clave_dialogo", self.dia)
        self.assertIn("companero.conversacion_solicitada.connect(_iniciar_conversacion)", self.dia)

    def test_dialogo_nace_del_npc_activado(self):
        self.assertIn("func _iniciar_conversacion(", self.dia)
        self.assertIn("DialogoDiegetico.mostrar(", self.dia)
        self.assertIn("_hud_prioridades, _caminante, companero, tr(clave_dialogo)", self.dia)

    def test_prompt_vive_en_arbitro_y_muestra_remapeo_real(self):
        self.assertIn("func conectar_hud(hud: HUDLayer)", self.caminante)
        self.assertIn("hud.registrar(HUDLayer.INTERACCION, _prompt_interaccion)", self.caminante)
        self.assertIn("InputMap.action_get_events(accion)", self.caminante)
        self.assertIn("_evento_pertenece_a_dispositivo(evento)", self.caminante)
        self.assertNotIn("var capa := CanvasLayer.new()", self.caminante)

    def test_prompt_usa_solo_el_ultimo_dispositivo(self):
        self.assertIn("enum DispositivoEntrada", self.caminante)
        self.assertIn("TECLADO_RATON", self.caminante)
        self.assertIn("MANDO", self.caminante)
        self.assertIn("InputEventJoypadButton", self.caminante)
        self.assertIn("InputEventKey", self.caminante)
        self.assertIn("InputEventMouseButton", self.caminante)
        self.assertIn("func _registrar_dispositivo_entrada(evento: InputEvent)", self.caminante)
        self.assertIn("_refrescar_prompt_interaccion()", self.caminante)
        self.assertNotIn('" / ".join(entradas)', self.caminante)

    def test_prompt_de_mando_evitar_indices_crudos_comunes(self):
        self.assertIn('JOY_BUTTON_A: "A / Cruz"', self.caminante)
        self.assertIn('JOY_BUTTON_B: "B / Círculo"', self.caminante)
        self.assertIn('JOY_BUTTON_DPAD_UP: "Cruceta arriba"', self.caminante)
        self.assertIn('"Botón %d" % evento.button_index', self.caminante)

    def test_drift_no_cambia_el_tipo_de_prompt(self):
        self.assertIn("UMBRAL_CAMBIO_DISPOSITIVO := 0.35", self.caminante)
        self.assertIn(
            "absf(evento.axis_value) >= UMBRAL_CAMBIO_DISPOSITIVO", self.caminante
        )
        cuerpo = self.caminante.split("func _mirar_con_mando", 1)[1]
        self.assertIn("if magnitud >= UMBRAL_CAMBIO_DISPOSITIVO:", cuerpo)
        self.assertIn("_usar_dispositivo_entrada(DispositivoEntrada.MANDO)", cuerpo)

    def test_mirar_npc_activa_senal_visual(self):
        self.assertIn("_marcar_objetivo(_objetivo_foco, false)", self.caminante)
        self.assertIn("_marcar_objetivo(_objetivo_foco, true)", self.caminante)
        self.assertIn("objetivo is CompaneroInteractivo3D", self.caminante)
        self.assertIn("objetivo.marcar_en_foco(en_foco)", self.caminante)

    def test_tutorial_dialogo_y_modal_comparten_jerarquia(self):
        self.assertIn("HUDLayer.TUTORIAL", self.dia)
        self.assertIn("HUDLayer.DIALOGO", self.dia)
        self.assertIn("HUDLayer.MODAL", self.dia)
        self.assertIn("_pista_puesto", self.dia)
        self.assertIn("_caminante.conectar_hud(_hud_prioridades)", self.dia)


if __name__ == "__main__":
    unittest.main()
