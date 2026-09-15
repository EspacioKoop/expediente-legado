from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "preferencias_siga.gd"


class PreferenciasSigaTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")

    def test_adaptador_y_persistencia_son_aislados(self):
        self.assertIn("class_name PreferenciasSiga", self.source)
        self.assertIn("extends RefCounted", self.source)
        for funcion in ("nuevas", "conflicto", "remapear", "aplicar", "guardar", "cargar"):
            self.assertIn(f"static func {funcion}", self.source)
        self.assertNotIn("Partida", self.source)

    def test_cubre_teclado_mando_y_conflictos(self):
        self.assertIn('"teclado"', self.source)
        self.assertIn('"mando"', self.source)
        self.assertIn('"motivo": "conflicto"', self.source)
        self.assertIn("InputMap.action_add_event", self.source)

    def test_remapeo_llega_a_los_controles_nativos_de_godot(self):
        self.assertIn('_copiar_accion_ui("interactuar", "ui_accept")', self.source)
        self.assertIn('_copiar_accion_ui("cancelar", "ui_cancel")', self.source)
        self.assertIn("InputMap.action_erase_events(destino)", self.source)
        self.assertIn("InputMap.action_get_events(origen)", self.source)
        self.assertIn("evento.duplicate() as InputEvent", self.source)
        self.assertIn("enter.keycode = KEY_ENTER", self.source)
        self.assertIn("_sincronizar_acciones_ui()", self.source)

    def test_guardado_es_atomico_y_preferencias_no_partida(self):
        self.assertIn('var temporal := ruta + ".nuevo"', self.source)
        self.assertIn("DirAccess.rename_absolute", self.source)
        self.assertIn('"reduccion_movimiento"', self.source)
        self.assertIn('"volumen"', self.source)

    def test_camara_tiene_preferencias_persistentes_y_acotadas(self):
        for clave in (
            '"sensibilidad_camara_raton"',
            '"sensibilidad_camara_mando"',
            '"invertir_camara_y"',
        ):
            self.assertIn(clave, self.source)
        self.assertIn("SENSIBILIDAD_CAMARA_MIN := 0.25", self.source)
        self.assertIn("SENSIBILIDAD_CAMARA_MAX := 3.0", self.source)
        self.assertGreaterEqual(self.source.count("clampf("), 3)

    def test_posicion_del_asistente_gato_es_opcional_y_valida(self):
        self.assertIn('"posicion_asistente_gato": null', self.source)
        self.assertIn('posicion.has("x") and posicion.has("y")', self.source)


if __name__ == "__main__":
    unittest.main()
