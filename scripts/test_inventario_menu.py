import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MENU = ROOT / "godot" / "guion" / "inventario_menu_app.gd"
CATALOGO_COMBINACIONES = ROOT / "godot" / "guion" / "combinaciones_objetos_catalogo.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_hud_fases_app.gd"
PREFERENCIAS = ROOT / "godot" / "guion" / "preferencias_siga.gd"
PRUEBA_GODOT = "pruebas/pruebas_inventario_menu.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class InventarioMenuTest(unittest.TestCase):
    def setUp(self):
        self.menu = MENU.read_text(encoding="utf-8")
        self.catalogo_combinaciones = CATALOGO_COMBINACIONES.read_text(encoding="utf-8")
        self.controlador = CONTROLADOR.read_text(encoding="utf-8")
        self.preferencias = PREFERENCIAS.read_text(encoding="utf-8")

    def test_superficie_reutiliza_el_inventario_persistente(self):
        self.assertIn("class_name InventarioMenuApp", self.menu)
        self.assertIn('estado_partida.get("inventario", {})', self.menu)
        self.assertIn("Inventario.CARRIED", self.menu)
        self.assertIn("Inventario.HOME_STORAGE", self.menu)
        self.assertIn('== "casa"', self.menu)
        self.assertNotIn("Partida.guardar", self.menu)
        self.assertNotIn("Inventario.vender", self.menu)

    def test_ui_es_navegable_y_no_un_overlay_paralelo(self):
        self.assertIn("Tree.new()", self.menu)
        self.assertIn("RichTextLabel.new()", self.menu)
        self.assertIn("InventarioMenuApp.new()", self.controlador)
        self.assertIn("hud.registrar(HUDLayer.MODAL, _inventario_panel)", self.controlador)
        self.assertIn("hud.activar(HUDLayer.MODAL)", self.controlador)
        self.assertIn("get_tree().paused = true", self.controlador)
        self.assertIn("get_tree().paused = false", self.controlador)

    def test_combinacion_reutiliza_inventario_y_objetos_reales(self):
        self.assertIn("CombinacionObjetos.combinar(", self.menu)
        self.assertIn("CombinacionesObjetosCatalogo.recetas()", self.menu)
        self.assertIn('name = "CombinacionSlotA"', self.menu)
        self.assertIn('name = "CombinacionSlotB"', self.menu)
        self.assertIn('name = "CombinacionEjecutar"', self.menu)
        self.assertIn('"palanca_kkryy"', self.catalogo_combinaciones)
        self.assertIn("RecompensaOnirica.ID", self.catalogo_combinaciones)
        self.assertIn(
            'PropsUtilizablesCC0.objeto_inventario("palanca_kkryy")',
            self.catalogo_combinaciones,
        )
        self.assertNotIn("Partida.guardar", self.catalogo_combinaciones)

    def test_drag_drop_usa_el_contrato_nativo_de_control(self):
        self.assertIn("set_drag_forwarding(", self.menu)
        self.assertIn("_datos_arrastre_inventario", self.menu)
        self.assertIn("_puede_soltar_en_slot.bind(\"a\")", self.menu)
        self.assertIn("_soltar_en_slot.bind(\"b\")", self.menu)
        self.assertIn("get_item_at_position(at_position)", self.menu)
        self.assertIn("set_drag_preview(vista)", self.menu)
        self.assertIn("Vector2.INF", self.menu)
        self.assertIn("Control.MOUSE_FILTER_IGNORE", self.menu)
        self.assertIn("item_activated.connect(_asignar_seleccion_al_primer_slot)", self.menu)

    def test_accion_inventario_es_semantica_y_remapeable(self):
        self.assertIn('"inventario": {"teclado": KEY_I, "mando": JOY_BUTTON_Y}', self.preferencias)
        self.assertIn('evento.is_action_pressed("inventario")', self.controlador)
        self.assertNotIn("KEY_I", self.controlador)
        self.assertNotIn("JOY_BUTTON_Y", self.controlador)

    def test_modelo_y_superficie_funcionan_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 15, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
