import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]


class TelefonoFijoTest(unittest.TestCase):
    def test_contrato_del_telefono_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_telefono_fijo.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("0 fallos", resultado.stdout)

    def test_integracion_reutiliza_jornada_e_interaccion(self):
        modelo = (ROOT / "godot" / "guion" / "telefono_fijo.gd").read_text()
        aparato = (ROOT / "godot" / "guion" / "telefono_fijo_interactivo_3d.gd").read_text()
        controlador = (ROOT / "godot" / "guion" / "dia_telefono_fijo_app.gd").read_text()
        escena = (ROOT / "godot" / "escenas" / "dia.tscn").read_text()

        self.assertIn('const CLAVE := "telefono_fijo"', modelo)
        self.assertIn("extends Interactuable3D", aparato)
        self.assertIn('nombre_objeto = "teléfono fijo"', aparato)
        self.assertIn("TelefonoFijo.perder_activa", controlador)
        self.assertIn("_guardar_o_avisar", controlador)
        self.assertIn("dia_telefono_fijo_app.gd", escena)
        self.assertIn("static func mensajes_guardados", modelo)
        self.assertIn("static func escuchar_mensaje", modelo)
        self.assertNotIn("Time.get_", modelo)
        self.assertNotIn("OS.get_time", modelo)

    def test_panel_cubre_texto_teclado_y_mando(self):
        panel = (ROOT / "godot" / "guion" / "telefono_fijo_panel.gd").read_text()

        self.assertIn("extends Window", panel)
        self.assertIn("RichTextLabel.new()", panel)
        self.assertIn("JOY_BUTTON_A", panel)
        self.assertIn("JOY_BUTTON_B", panel)
        self.assertIn('is_action_pressed("cancelar")', panel)
        self.assertIn("TelefonoFijo.escuchar_siguiente", panel)
        self.assertIn("TelefonoFijo.mensajes_guardados", panel)
        self.assertIn("TelefonoFijo.escuchar_mensaje", panel)
        self.assertIn('boton.name = "Mensaje_%d"', panel)
        self.assertIn("_enfocar_mensaje.call_deferred", panel)
        self.assertIn("TelefonoFijo.llamar", panel)
        self.assertIn("TelefonoFijo.descolgar", panel)
        self.assertIn("TelefonoFijo.colgar", panel)


if __name__ == "__main__":
    unittest.main()
