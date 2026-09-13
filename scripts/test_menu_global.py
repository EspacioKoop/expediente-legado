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


if __name__ == "__main__":
    unittest.main()
