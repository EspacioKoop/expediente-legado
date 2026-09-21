from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "godot" / "guion" / "menu_global.gd"
PROJECT = ROOT / "godot" / "project.godot"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"


class MenuGlobalTest(unittest.TestCase):
    def setUp(self):
        self.menu = MENU.read_text(encoding="utf-8")
        self.project = PROJECT.read_text(encoding="utf-8")
        self.textos = TEXTOS.read_text(encoding="utf-8")

    def test_es_autoload_y_no_depende_de_una_fase(self):
        self.assertIn('MenuGlobal="*res://guion/menu_global.gd"', self.project)
        self.assertIn('scene_file_path == "res://escenas/dia.tscn"', self.menu)
        for fase in ('"archivo"', '"casa"', '"sueño"'):
            self.assertNotIn(f"== {fase}", self.menu)

    def test_pausa_y_restaura_foco_del_legado(self):
        self.assertIn("get_tree().paused = true", self.menu)
        self.assertIn("get_tree().paused = false", self.menu)
        self.assertIn("gui_get_focus_owner", self.menu)
        self.assertIn("_foco_previo.grab_focus()", self.menu)
        self.assertIn('is_action_pressed("cancelar")', self.menu)

    def test_reutiliza_preferencias_de_controles(self):
        self.assertIn("PreferenciasSiga.cargar()", self.menu)
        self.assertIn("PreferenciasSiga.aplicar(_preferencias)", self.menu)
        self.assertIn("PreferenciasSiga.guardar(_preferencias)", self.menu)
        self.assertIn('"volumen"', self.menu)
        self.assertIn('"reduccion_movimiento"', self.menu)

    def test_textos_compartidos_y_traducibles(self):
        self.assertIn('"res://datos/textos.es.translation"', self.project)
        self.assertNotIn("menu_textos.es.translation", self.project)
        for clave in (
            "MENU_GLOBAL_TITULO",
            "MENU_GLOBAL_CONTINUAR",
            "MENU_GLOBAL_OPCIONES",
            "MENU_GLOBAL_VOLVER",
            "MENU_GLOBAL_SALIR",
            "MENU_GLOBAL_VOLUMEN",
            "MENU_GLOBAL_REDUCCION_MOVIMIENTO",
        ):
            self.assertIn(clave, self.textos)
            self.assertIn(f'tr("{clave}")', self.menu)

    def test_historial_de_decisiones_es_superficie_del_menu(self):
        for clave in (
            "MENU_GLOBAL_HISTORIAL_DECISIONES",
            "MENU_GLOBAL_HISTORIAL_SUBTITULO",
            "MENU_GLOBAL_HISTORIAL_RESUMEN",
            "MENU_GLOBAL_HISTORIAL_VACIO",
        ):
            self.assertIn(clave, self.textos)
            self.assertIn(f'tr("{clave}")', self.menu)
        self.assertIn("Historias.new()", self.menu)
        self.assertIn("_historias.historial(estado)", self.menu)
        self.assertIn("_historias.presion_indecision(estado)", self.menu)
        self.assertIn("_texto_eleccion", self.menu)
        self.assertIn("_historial_volver.grab_focus()", self.menu)

    def test_parte_incidencias_es_una_superficie_del_mismo_menu(self):
        self.assertIn("ParteIncidenciasApp.new()", self.menu)
        self.assertIn("ParteIncidencias.ETIQUETA", self.menu)
        self.assertIn("_mostrar_incidencias", self.menu)
        self.assertIn("_volver_de_incidencias", self.menu)
        self.assertIn("_incidencias.grab_focus()", self.menu)

    def test_metadatos_nativos_para_lector_de_pantalla(self):
        self.assertIn("_volumen.accessibility_name = volumen_titulo.text", self.menu)
        self.assertIn("slider.accessibility_name = etiqueta", self.menu)
        self.assertIn(
            "_estado_remapeo.accessibility_live = AccessibilityServer.LIVE_POLITE",
            self.menu,
        )
        self.assertIn(
            "restaurar.accessibility_name = restaurar.tooltip_text", self.menu
        )


if __name__ == "__main__":
    unittest.main()
