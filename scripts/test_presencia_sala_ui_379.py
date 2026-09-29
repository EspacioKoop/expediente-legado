import json
import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
CONTROLADOR = ROOT / "godot" / "guion" / "dia_presencia_coop_app.gd"
PANEL = ROOT / "godot" / "guion" / "red" / "presencia_sala_panel.gd"
TEXTOS = ROOT / "godot" / "datos" / "presencia_sala_textos.json"
PRUEBA_GODOT = "pruebas/pruebas_presencia_sala_ui_379.gd"
RESUMEN = re.compile(r"Presencia UI #379: (\d+) pasadas, 0 fallos")


class PresenciaSalaUi379Test(unittest.TestCase):
    def test_endpoint_e_identidad_viven_fuera_de_partida(self) -> None:
        fuente = CONTROLADOR.read_text(encoding="utf-8")
        self.assertIn('AJUSTE_ENDPOINT := "multiplayer/presencia/websocket_url"', fuente)
        self.assertIn("ProjectSettings.get_setting(AJUSTE_ENDPOINT", fuente)
        self.assertIn("IdentidadOnline.new()", fuente)
        self.assertIn("TransporteOnlineFactory.crear(endpoint, false)", fuente)
        self.assertNotIn("TransporteWebSocket", fuente)
        self.assertNotIn("Partida.guardar", fuente)
        self.assertNotIn('jornada["multiplayer"', fuente)

    def test_panel_solo_recoge_intencion(self) -> None:
        fuente = PANEL.read_text(encoding="utf-8")
        self.assertIn("signal crear_sala_solicitada", fuente)
        self.assertIn("signal unirse_sala_solicitada", fuente)
        self.assertIn("signal ocultar_participante_solicitado", fuente)
        self.assertNotIn("TransporteWebSocket", fuente)
        self.assertNotIn("IdentidadOnline", fuente)

        textos = json.loads(TEXTOS.read_text(encoding="utf-8"))
        for clave in ("titulo", "crear", "unirse", "salir", "ocultar", "sin_endpoint"):
            self.assertTrue(textos[clave].strip(), clave)

    def test_recorrido_ui_websocket_real(self) -> None:
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=90)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
