from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA_CALLE = ROOT / "godot" / "guion" / "dia_calle_app.gd"
JORNADA = ROOT / "godot" / "guion" / "jornada.gd"


class TrayectoCalleTest(unittest.TestCase):
    def test_jornada_declara_trayecto_y_no_calle(self):
        texto = JORNADA.read_text(encoding="utf-8")
        self.assertIn('"trayecto"', texto)
        self.assertNotIn('const FASES := ["archivo", "calle"', texto)

    def test_capa_visual_se_aplica_a_trayecto(self):
        texto = DIA_CALLE.read_text(encoding="utf-8")
        self.assertIn('if fase != "trayecto":', texto)
        self.assertNotIn('if fase != "calle":', texto)

    def test_recomposicion_sigue_siendo_solo_presentacion(self):
        texto = DIA_CALLE.read_text(encoding="utf-8")
        self.assertIn('espacio.erase("pantallas")', texto)
        self.assertIn('espacio["bultos"] = _bultos_calle()', texto)
        self.assertIn('espacio["ventanas"] = _ventanas_calle()', texto)
        for prohibido in ("dinero", "acciones", "pistas_descubiertas", "veredictos"):
            self.assertNotIn(f'jornada["{prohibido}"]', texto)


if __name__ == "__main__":
    unittest.main()
