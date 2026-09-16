from pathlib import Path
import json
import unittest


ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "godot" / "guion" / "menu_global.gd"
TEXTOS = ROOT / "godot" / "datos" / "menu_remapeo_textos.json"


class MenuRemapeoPresentacionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.menu = MENU.read_text(encoding="utf-8")
        cls.textos = json.loads(TEXTOS.read_text(encoding="utf-8"))

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
        self.assertIn("return PreferenciasSiga.nombre_boton_mando(codigo)", self.menu)

    def test_captura_y_conflictos_son_legibles(self):
        self.assertEqual(self.textos["captura_teclado"], "una tecla")
        self.assertEqual(self.textos["captura_mando"], "un botón del mando")
        self.assertEqual(self.textos["conflicto"], "⚠ %s ya usa ese control")
        self.assertEqual(self.textos["restaurado"], "↺ Controles restaurados")
        self.assertIn('_texto_remapeo("captura_estado")', self.menu)
        self.assertIn('_texto_remapeo("conflicto")', self.menu)

    def test_botones_exponen_contexto_en_tooltip(self):
        self.assertEqual(self.textos["restaurar_tooltip"], "Restaurar controles por defecto")
        self.assertEqual(self.textos["tooltip_teclado"], "%s · teclado")
        self.assertEqual(self.textos["tooltip_mando"], "%s · mando")
        self.assertIn('restaurar.tooltip_text = _texto_remapeo("restaurar_tooltip")', self.menu)
        self.assertIn('tecla.tooltip_text = _texto_remapeo("tooltip_teclado")', self.menu)
        self.assertIn('mando.tooltip_text = _texto_remapeo("tooltip_mando")', self.menu)

    def test_copy_de_remapeo_no_vive_en_la_pantalla(self):
        for texto in self.textos.values():
            self.assertNotIn(f'= "{texto}"', self.menu)


if __name__ == "__main__":
    unittest.main()
