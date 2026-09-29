import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot/guion/navegador_siga.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_navegador_identidad_791.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class NavegadorIdentidad791Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_identidad_es_local_y_diferencia_shell_de_pagina(self):
        for token in (
            'const FONDO_CROMO := Color("#d7d1c4")',
            'const FONDO_DIRECCION := Color("#fff7d6")',
            'const FONDO_PAGINA := Color("#fbfaf2")',
            'const FONDO_LATERAL := Color("#e5eaf0")',
            "_estilizar_boton_cromo(_atras)",
            "_estilizar_linea_web98(_direccion)",
            '_pagina.add_theme_stylebox_override(',
            "_estilizar_lista_web98(_historial_lista, FONDO_LATERAL)",
        ):
            self.assertIn(token, self.source)

    def test_no_cambia_modelos_red_o_persistencia(self):
        self.assertIn("Web98Indice.new()", self.source)
        self.assertIn("Web98Prensa.new()", self.source)
        self.assertIn("Bbs98Modelo.new()", self.source)
        self.assertNotIn("HTTPClient", self.source)
        self.assertNotIn("HTTPRequest", self.source)
        self.assertNotIn("FileAccess.", self.source)
        self.assertNotIn("DirAccess.", self.source)
        self.assertNotIn("OS.execute", self.source)

    def test_preserva_navegacion_y_foco(self):
        for token in (
            "_atras.pressed.connect(ir_atras)",
            "_adelante.pressed.connect(ir_adelante)",
            "_direccion.text_submitted.connect",
            "_busqueda.text_submitted.connect(_mostrar_busqueda)",
            "_enlaces.item_activated.connect(_activar_enlace)",
            '"focus", _caja_web98(FONDO_DIRECCION, FOCO_WEB98',
            '"focus", _caja_web98(fondo, FOCO_WEB98',
        ):
            self.assertIn(token, self.source)

    def test_flujo_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 17, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
