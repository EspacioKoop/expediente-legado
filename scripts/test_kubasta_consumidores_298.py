"""Consumidores reales del rol tipográfico de terminal (#298)."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ESTILO = ROOT / "godot" / "guion" / "estilo_siga.gd"
VISOR = ROOT / "godot" / "guion" / "visor_expediente.gd"
CONSOLA = ROOT / "godot" / "debug" / "consola_depuracion.gd"


class KubastaConsumidores298Test(unittest.TestCase):
    def setUp(self):
        self.estilo = ESTILO.read_text(encoding="utf-8")
        self.visor = VISOR.read_text(encoding="utf-8")
        self.consola = CONSOLA.read_text(encoding="utf-8")

    def test_theme_expone_terminal_font_para_label(self):
        self.assertIn(
            'tema.set_font("terminal_font", "Label", terminal)',
            self.estilo,
        )

    def test_visor_usa_terminal_solo_en_metadatos_y_estado(self):
        self.assertIn(
            'theme.get_font("terminal_font", "Label")',
            self.visor,
        )
        self.assertIn("_aplicar_fuente_terminal(_cabecera)", self.visor)
        self.assertIn("_aplicar_fuente_terminal(_estado)", self.visor)
        self.assertIn(
            'theme.get_font("document_font", "RichTextLabel")',
            self.visor,
        )

    def test_consola_usa_terminal_en_salida_y_entrada(self):
        self.assertIn(
            "var fuente_terminal := EstiloSiga.fuente_terminal()",
            self.consola,
        )
        self.assertIn(
            '_registro.add_theme_font_override("normal_font", fuente_terminal)',
            self.consola,
        )
        self.assertIn(
            '_registro.add_theme_font_override("bold_font", fuente_terminal)',
            self.consola,
        )
        self.assertIn(
            '_linea.add_theme_font_override("font", fuente_terminal)',
            self.consola,
        )


if __name__ == "__main__":
    unittest.main()
