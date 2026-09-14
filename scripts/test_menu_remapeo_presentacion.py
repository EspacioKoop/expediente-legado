from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "godot" / "guion" / "menu_global.gd"


class MenuRemapeoPresentacionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.menu = MENU.read_text(encoding="utf-8")

    def test_acciones_tienen_nombres_de_usuario(self):
        for etiqueta in (
            '"mover_adelante": "Avanzar"',
            '"mover_atras": "Retroceder"',
            '"interactuar": "Interactuar"',
            '"cancelar": "Volver / cancelar"',
        ):
            self.assertIn(etiqueta, self.menu)
        self.assertIn("nombre.text = _nombre_accion(accion)", self.menu)

    def test_mando_no_muestra_indices_crudos(self):
        self.assertNotIn('mando.text = "🎮 %d"', self.menu)
        self.assertIn("func _nombre_boton_mando(codigo: int)", self.menu)
        self.assertIn('JOY_BUTTON_A: "A / Cruz"', self.menu)
        self.assertIn('JOY_BUTTON_DPAD_UP: "Cruceta arriba"', self.menu)
        self.assertIn('"Botón %d" % codigo', self.menu)

    def test_captura_y_conflictos_son_legibles(self):
        self.assertIn('"una tecla" if tipo == "teclado" else "un botón del mando"', self.menu)
        self.assertIn('"⚠ %s ya usa ese control" % _nombre_accion(conflicto)', self.menu)
        self.assertIn('"↺ Controles restaurados"', self.menu)

    def test_botones_exponen_contexto_en_tooltip(self):
        self.assertIn('tecla.tooltip_text = "%s · teclado" % _nombre_accion(accion)', self.menu)
        self.assertIn('mando.tooltip_text = "%s · mando" % _nombre_accion(accion)', self.menu)
        self.assertIn('restaurar.tooltip_text = "Restaurar controles por defecto"', self.menu)


if __name__ == "__main__":
    unittest.main()
