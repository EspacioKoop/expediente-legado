import re
import unittest

from scripts.godot_pruebas import ejecutar_script


PRUEBA_GODOT = "pruebas/pruebas_senales_moderacion_377.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SenalesModeracion377RuntimeTest(unittest.TestCase):
    """Verifica moderación local cerrada sobre señales visibles."""

    def test_moderacion_senales_en_godot_headless(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=60)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 13, resultado.stdout)

    def test_superficie_no_toca_campana_ni_texto_libre(self):
        from pathlib import Path

        root = Path(__file__).resolve().parents[1]
        rutas = [
            root / "godot/guion/senales/senal_moderacion_ui.gd",
            root / "godot/guion/senales/senal_player.gd",
            root / "godot/guion/dia_senales_multiplayer_app.gd",
        ]
        # Solo cuenta el código: un comentario que explica que la red no toca
        # Partida no debe hacer fallar la comprobación de que no la toca (#1536).
        codigo = "\n".join(
            linea
            for ruta in rutas
            for linea in ruta.read_text(encoding="utf-8").splitlines()
            if not linea.lstrip().startswith("#")
        )
        self.assertNotIn("LineEdit.new", codigo)
        self.assertNotIn("TextEdit.new", codigo)
        self.assertNotIn("Partida.", codigo)
        self.assertNotIn("VisorExpediente", codigo)
        self.assertIn("ocultar_evento", codigo)
        self.assertIn("reportar_evento", codigo)
        moderacion = rutas[0].read_text(encoding="utf-8")
        self.assertIn('signal.moderate.title', moderacion)
        self.assertIn('signal.moderate.hide', moderacion)
        self.assertIn('signal.moderate.report', moderacion)
        self.assertIn('signal.moderate.cancel', moderacion)
        self.assertIn("_boton_ocultar.grab_focus()", moderacion)
        self.assertIn('event.is_action_pressed("ui_cancel")', moderacion)


if __name__ == "__main__":
    unittest.main()
