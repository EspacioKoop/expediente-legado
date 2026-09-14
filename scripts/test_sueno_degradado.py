from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
ALQUILER = ROOT / "godot" / "guion" / "dia_alquiler_app.gd"


class SuenoDegradadoTest(unittest.TestCase):
    def test_la_capa_aplica_la_politica_despues_de_dormir(self):
        source = DIA.read_text(encoding="utf-8")
        dormir = source.index("var noche := Jornada.dormir(jornada)")
        politica = source.index("_aplicar_politica_sueno()", dormir)
        self.assertLess(dormir, politica)

    def test_la_politica_se_aplica_sin_duplicar_jornada(self):
        source = DIA.read_text(encoding="utf-8")
        self.assertIn("func _opciones_sueno() -> Dictionary:", source)
        self.assertIn("Sueno.noche(", source)
        self.assertNotIn("Jornada.dormir(", source[source.index("func _aplicar_politica_sueno"):])

    def test_la_oficina_pide_una_escena_y_prioriza_vistas(self):
        source = ALQUILER.read_text(encoding="utf-8")
        self.assertIn('if _vivienda() == "oficina":', source)
        self.assertIn('"cantidad": 1', source)
        self.assertIn('"priorizar_vistas": true', source)

    def test_la_politica_no_borra_el_mapa(self):
        source = DIA.read_text(encoding="utf-8")
        bloque = source[source.index("func _aplicar_politica_sueno"):]
        self.assertNotIn('jornada["mapa"] = []', bloque)
        self.assertIn('jornada["mapa_anoche"] = jornada["mapa"].duplicate()', bloque)


if __name__ == "__main__":
    unittest.main()
