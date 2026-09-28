from pathlib import Path
import re
import unittest

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "godot/guion/menu_global.gd"
PRUEBA = "pruebas/pruebas_menu_global_foco_113.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class MenuGlobalFoco113Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.menu = MENU.read_text(encoding="utf-8")

    def test_menu_declara_cadena_vertical_explicita(self):
        self.assertIn("func _controles_foco(panel: Control)", self.menu)
        self.assertIn("func _encadenar_foco_panel(panel: Control)", self.menu)
        self.assertIn("focus_neighbor_top", self.menu)
        self.assertIn("focus_neighbor_bottom", self.menu)
        self.assertIn("focus_previous", self.menu)
        self.assertIn("focus_next", self.menu)
        self.assertIn("_enfocar_primero(_panel_opciones, _volumen)", self.menu)

    def test_volver_restaura_el_lanzador_que_abrió_el_panel(self):
        self.assertIn("_mostrar_principal.bind(_opciones)", self.menu)
        self.assertIn("_mostrar_principal.bind(_sellos)", self.menu)
        self.assertIn("_mostrar_principal.bind(_historial_boton)", self.menu)
        self.assertIn("func _mostrar_principal(foco_destino: Control = null)", self.menu)

    def test_no_hardcodea_botones_de_mando(self):
        bloque = self.menu.split("func _encadenar_foco_panel", 1)[1].split(
            "\n\nfunc _enfocar_primero", 1
        )[0]
        self.assertNotIn("JOY_BUTTON_", bloque)
        self.assertNotIn("Input.", bloque)

    def test_contrato_runtime_en_godot_real(self):
        resultado = ejecutar_script(PRUEBA)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
