from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ESTILO = ROOT / "godot" / "guion" / "estilo_siga.gd"


class TipografiaSigaTest(unittest.TestCase):
    def test_la_interfaz_no_depende_de_fuentes_del_sistema(self):
        texto = ESTILO.read_text(encoding="utf-8")
        bloque = texto.split("static func fuente()", 1)[1].split(
            "static func fuente_mono()", 1
        )[0]

        self.assertIn("ThemeDB.get_default_theme().default_font", bloque)
        self.assertNotIn("SystemFont", bloque)
        self.assertNotIn("FONT_ANTIALIASING_NONE", bloque)

    def test_el_tema_siga_usa_la_fuente_de_interfaz_centralizada(self):
        texto = ESTILO.read_text(encoding="utf-8")
        bloque = texto.split("static func tema()", 1)[1]

        self.assertIn("var fuente := fuente()", bloque)
        self.assertIn("tema.default_font = fuente", bloque)


if __name__ == "__main__":
    unittest.main()
