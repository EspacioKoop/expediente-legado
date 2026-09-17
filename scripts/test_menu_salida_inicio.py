import json
from pathlib import Path
import unittest

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot" / "project.godot"
MENU = ROOT / "godot" / "guion" / "menu_salida_inicio.gd"
TEXTOS = ROOT / "godot" / "datos" / "menu_salida_inicio_textos.json"


class MenuSalidaInicioTest(unittest.TestCase):
    def setUp(self):
        self.project = PROJECT.read_text(encoding="utf-8")
        self.menu = MENU.read_text(encoding="utf-8")
        self.textos = json.loads(TEXTOS.read_text(encoding="utf-8"))

    def test_se_monta_despues_del_menu_global(self):
        global_pos = self.project.index('MenuGlobal="*res://guion/menu_global.gd"')
        salida_pos = self.project.index(
            'MenuSalidaInicio="*res://guion/menu_salida_inicio.gd"'
        )
        self.assertLess(global_pos, salida_pos)
        self.assertIn('get_node_or_null("/root/MenuGlobal")', self.menu)

    def test_etiqueta_y_confirmacion_son_explicitas(self):
        self.assertEqual(self.textos["volver_inicio"], "Volver al menú de inicio")
        self.assertIn("Se guardará la partida antes de salir", self.textos["confirmar"])
        self.assertIn("ConfirmationDialog.new()", self.menu)
        self.assertIn("get_cancel_button().grab_focus.call_deferred()", self.menu)

    def test_guarda_antes_de_cambiar_de_escena(self):
        guardar = self.menu.index("SalidaPartida.guardar_desde(escena)")
        cambiar = self.menu.index("get_tree().change_scene_to_file(RUTA_INICIO)")
        self.assertLess(guardar, cambiar)
        self.assertIn('tr("ARCHIVO_ERROR_GUARDAR")', self.menu)
        self.assertIn('const RUTA_DIA := "res://escenas/dia.tscn"', self.menu)
        self.assertIn('const RUTA_INICIO := "res://escenas/inicio.tscn"', self.menu)
        self.assertNotIn("get_tree().quit", self.menu)

    def test_contrato_ejecutable_en_godot(self):
        resultado = ejecutar_script("res://pruebas/pruebas_menu_salida_inicio.gd")
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("11 pasadas, 0 fallos", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
