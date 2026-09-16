"""La consola de pruebas (#770) se carga siempre y sobrevive a la exportación."""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONSOLA = ROOT / "godot" / "depuracion" / "consola_depuracion.gd"
PROYECTO = ROOT / "godot" / "project.godot"
PRESETS = ROOT / "godot" / "export_presets.cfg"
CLIMA = ROOT / "godot" / "guion" / "dia_clima_app.gd"


class ConsolaDepuracionTest(unittest.TestCase):
    def setUp(self):
        self.consola = CONSOLA.read_text(encoding="utf-8")

    def test_es_autoload(self):
        self.assertIn(
            'ConsolaDepuracion="*res://depuracion/consola_depuracion.gd"',
            PROYECTO.read_text(encoding="utf-8"),
        )

    def test_se_abre_con_la_tecla_de_la_izquierda_del_uno(self):
        self.assertIn("KEY_QUOTELEFT", self.consola)
        self.assertIn('"º"', self.consola)

    def test_la_exportacion_no_la_excluye(self):
        for filtro in re.findall(r'exclude_filter="([^"]*)"', PRESETS.read_text(encoding="utf-8")):
            for patron in filtro.split(","):
                self.assertFalse(patron.strip().startswith("depuracion"), patron)

    def test_cubre_lo_pedido_en_el_playtest(self):
        for comando in ("fase", "sala", "dia", "dinero", "pistas", "gato", "clima", "desatascar"):
            self.assertIn(f'"{comando}":', self.consola)

    def test_el_clima_forzado_llega_al_dia(self):
        self.assertIn('jornada.get("clima_forzado", "")', CLIMA.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
