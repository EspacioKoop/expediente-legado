from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "dialogo_diegetico.gd"


class DialogoDiegeticoTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")

    def test_componente_no_duplica_catalogo(self):
        self.assertIn("class_name DialogoDiegetico", self.source)
        self.assertIn("static func mostrar(", self.source)
        self.assertNotIn("Companeros.frase_de", self.source)
        self.assertNotIn("textos.csv", self.source)

    def test_atribuye_al_npc_interactuado_y_no_a_un_vecino(self):
        self.assertIn("companero: CompaneroInteractivo3D", self.source)
        self.assertIn("companero.nombre_visible", self.source)
        self.assertIn("companero.global_position", self.source)
        self.assertNotIn("_hablante_mas_cercano", self.source)
        self.assertNotIn("DISTANCIA_HABLANTE_MAX", self.source)

    def test_subtitulo_inferior_y_direccion_discreta(self):
        self.assertIn("Control.PRESET_CENTER_BOTTOM", self.source)
        self.assertIn('return "▶"', self.source)
        self.assertIn('return "◀"', self.source)
        self.assertIn('return "▲"', self.source)
        self.assertIn('panel.name = "DialogoDiegetico"', self.source)

    def test_dialogo_tiene_rol_visual_distinto_del_tutorial(self):
        self.assertIn('HUDEstilo.caja_dialogo()', self.source)
        self.assertIn('hablante.name = "HablanteDialogoDiegetico"', self.source)
        self.assertIn('HUDEstilo.HABLANTE_DIALOGO', self.source)
        self.assertIn('HUDEstilo.TEXTO_DIALOGO', self.source)
        self.assertIn('contenido.add_child(hablante)', self.source)
        self.assertIn('contenido.add_child(etiqueta)', self.source)

    def test_dialogo_toma_prioridad_en_hud_y_se_libera(self):
        self.assertIn("hud.registrar(HUDLayer.DIALOGO, panel)", self.source)
        self.assertIn("hud.activar(HUDLayer.DIALOGO)", self.source)
        self.assertIn("hud.desactivar(HUDLayer.DIALOGO)", self.source)

    def test_desaparicion_automatica_y_no_bloquea(self):
        self.assertIn("const DURACION := 3.4", self.source)
        self.assertIn("create_timer(DURACION)", self.source)
        self.assertIn("Control.MOUSE_FILTER_IGNORE", self.source)
        self.assertNotIn("set_physics_process(false)", self.source)

    def test_tono_breve_pasa_por_sonido_y_bus_global(self):
        self.assertIn("AudioStreamWAV", self.source)
        self.assertIn("const DURACION_TONO := 0.08", self.source)
        self.assertIn("Sonido.sonar_stream(hud, _tono())", self.source)
        self.assertNotIn("AudioServer.set_bus", self.source)


if __name__ == "__main__":
    unittest.main()
