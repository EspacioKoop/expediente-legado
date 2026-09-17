import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
VISOR = ROOT / "godot" / "guion" / "visor_publicacion.gd"
ESCENA = ROOT / "godot" / "escenas" / "visor_publicacion.tscn"
DOC = ROOT / "docs" / "publicaciones-98.md"
PRUEBA_GODOT = "res://pruebas/pruebas_visor_publicacion.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class VisorPublicacion674Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.visor = VISOR.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_es_ventana_modal_con_contenido_scrollable(self):
        self.assertIn("class_name VisorPublicacion", self.visor)
        self.assertIn("extends Window", self.visor)
        self.assertIn("RichTextLabel.new()", self.visor)
        self.assertIn("scroll_active = true", self.visor)
        self.assertIn("focus_mode = Control.FOCUS_ALL", self.visor)
        self.assertIn("popup_centered()", self.visor)

    def test_reutiliza_contrato_de_lectura_y_cierre(self):
        self.assertIn("Publicaciones98.por_id(item_id)", self.visor)
        self.assertIn("Publicaciones98.hojear", self.visor)
        self.assertIn("Publicaciones98.cerrar_tras_lectura", self.visor)
        self.assertNotIn("SemillasOniricas.activar_semilla_onirica", self.visor)
        self.assertNotIn("Jornada.gastar", self.visor)

    def test_ofrece_escalado_acotado(self):
        self.assertIn("const TAMANOS_TEXTO := [18, 22, 26, 30]", self.visor)
        self.assertIn("func reducir_texto()", self.visor)
        self.assertIn("func ampliar_texto()", self.visor)
        self.assertIn('"A−"', self.visor)
        self.assertIn('"A+"', self.visor)

    def test_teclado_y_mando_tienen_rutas_explicitas(self):
        for token in (
            "KEY_PAGEUP",
            "KEY_PAGEDOWN",
            "JOY_BUTTON_A",
            "JOY_BUTTON_B",
            "JOY_BUTTON_LEFT_SHOULDER",
            "JOY_BUTTON_RIGHT_SHOULDER",
            'is_action_pressed("cancelar")',
            'is_action_pressed("ui_cancel")',
        ):
            self.assertIn(token, self.visor)

    def test_escena_apunta_al_visor(self):
        self.assertIn('type="Window"', self.escena)
        self.assertIn('path="res://guion/visor_publicacion.gd"', self.escena)

    def test_documentacion_refleja_el_segundo_corte(self):
        self.assertIn("visor de publicaciones", self.doc.lower())
        self.assertIn("pageup", self.doc.lower())
        self.assertIn("l1/r1", self.doc.lower())
        self.assertIn("materialización 3d", self.doc.lower())
        self.assertIn("no cierra #674", self.doc.lower())

    def test_runtime_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--quit-after",
                "600",
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout, resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout, resultado.stdout)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
