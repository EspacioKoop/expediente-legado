from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "godot" / "guion" / "menu_global.gd"
PREFERENCIAS = ROOT / "godot" / "guion" / "preferencias_siga.gd"


class MenuRemapeoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.menu = MENU.read_text(encoding="utf-8")
        cls.preferencias = PREFERENCIAS.read_text(encoding="utf-8")

    def test_expone_todas_las_acciones_semanticas(self):
        self.assertIn("for accion in PreferenciasSiga.ACCIONES", self.menu)
        self.assertIn('["teclado", "mando"]', self.menu)
        self.assertIn("_botones_remapeo", self.menu)

    def test_captura_teclado_y_mando(self):
        self.assertIn("evento is InputEventKey", self.menu)
        self.assertIn("evento.physical_keycode", self.menu)
        self.assertIn("evento is InputEventJoypadButton", self.menu)
        self.assertIn("evento.button_index", self.menu)

    def test_reutiliza_conflictos_y_persistencia_del_adaptador(self):
        self.assertIn("PreferenciasSiga.remapear", self.menu)
        self.assertIn("PreferenciasSiga.aplicar(_preferencias)", self.menu)
        self.assertIn("PreferenciasSiga.guardar(_preferencias)", self.menu)
        self.assertIn('"motivo": "conflicto"', self.preferencias)

    def test_restaurar_controles_no_resetea_otras_preferencias(self):
        self.assertIn(
            '_preferencias["acciones"] = PreferenciasSiga.nuevas()["acciones"].duplicate(true)',
            self.menu,
        )
        self.assertNotIn("_preferencias = PreferenciasSiga.nuevas()", self.menu)

    def test_cancelar_captura_al_salir_del_menu(self):
        self.assertIn("func _cancelar_captura()", self.menu)
        cierre = self.menu.split("func _cerrar() -> void:", 1)[1].split("func ", 1)[0]
        self.assertIn("_cancelar_captura()", cierre)


if __name__ == "__main__":
    unittest.main()
