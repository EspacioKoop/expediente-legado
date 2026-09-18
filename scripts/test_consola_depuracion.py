"""La consola de pruebas (#116/#770) existe en desarrollo y no viaja en release."""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "godot"
CONSOLA = GODOT / "debug" / "consola_depuracion.gd"
CARGADOR = GODOT / "guion" / "cargador_consola_depuracion.gd"
CONSOLA_ANTIGUA = GODOT / "depuracion" / "consola_depuracion.gd"
PROYECTO = GODOT / "project.godot"
PRESETS = GODOT / "export_presets.cfg"
CLIMA = GODOT / "guion" / "dia_clima_app.gd"


class ConsolaDepuracionTest(unittest.TestCase):
    def setUp(self):
        self.consola = CONSOLA.read_text(encoding="utf-8")
        self.cargador = CARGADOR.read_text(encoding="utf-8")

    def test_el_autoload_es_un_cargador_sin_comandos(self):
        proyecto = PROYECTO.read_text(encoding="utf-8")
        self.assertIn(
            'ConsolaDepuracion="*res://guion/cargador_consola_depuracion.gd"',
            proyecto,
        )
        self.assertIn("OS.is_debug_build()", self.cargador)
        self.assertIn('res://debug/consola_depuracion.gd', self.cargador)
        self.assertNotIn("func ejecutar(", self.cargador)

    def test_la_implementacion_vive_solo_bajo_debug(self):
        self.assertTrue(CONSOLA.is_file())
        self.assertFalse(CONSOLA_ANTIGUA.exists())

    def test_se_abre_con_la_tecla_de_la_izquierda_del_uno(self):
        self.assertIn("KEY_QUOTELEFT", self.consola)
        self.assertIn('"º"', self.consola)

    def test_la_exportacion_publica_excluye_debug(self):
        filtros = re.findall(
            r'exclude_filter="([^"]*)"',
            PRESETS.read_text(encoding="utf-8"),
        )
        self.assertGreaterEqual(len(filtros), 2)
        for filtro in filtros[:2]:
            self.assertIn("debug/**", {p.strip() for p in filtro.split(",")})

    def test_cubre_lo_pedido_en_el_playtest(self):
        for comando in ("fase", "sala", "dia", "dinero", "pistas", "gato", "clima", "desatascar"):
            self.assertIn(f'"{comando}":', self.consola)

    def test_el_clima_forzado_llega_al_dia(self):
        self.assertIn(
            'jornada.get("clima_forzado", "")',
            CLIMA.read_text(encoding="utf-8"),
        )


if __name__ == "__main__":
    unittest.main()
