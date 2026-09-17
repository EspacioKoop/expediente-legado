"""Contrato preparatorio de Kubasta para terminales (#298)."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ESTILO = ROOT / "godot" / "guion" / "estilo_siga.gd"
DOC = ROOT / "docs" / "assets" / "kubasta-terminal-298.md"


class KubastaTerminal298Test(unittest.TestCase):
    def setUp(self):
        self.estilo = ESTILO.read_text(encoding="utf-8")
        self.doc = DOC.read_text(encoding="utf-8")

    def test_terminal_es_un_rol_independiente(self):
        self.assertIn("static func fuente_terminal() -> Font:", self.estilo)
        self.assertIn("return fuente_mono()", self.estilo)
        self.assertIn(
            'tema.set_font("terminal_font", "RichTextLabel", terminal)',
            self.estilo,
        )
        self.assertIn(
            'tema.set_font("terminal_font", "LineEdit", terminal)',
            self.estilo,
        )

    def test_mono_generica_conserva_el_fallback_reproducible(self):
        self.assertIn(
            'const RUTA_FUENTE_MONO := "res://assets/fonts/IBMPlexMono-Regular.ttf"',
            self.estilo,
        )
        self.assertIn("static func fuente_mono() -> Font:", self.estilo)
        self.assertNotIn("Kubasta.ttf", self.estilo)

    def test_contrato_fija_fuente_licencia_y_matriz_de_validacion(self):
        for texto in (
            "https://zichy.itch.io/kubasta",
            "CC0-1.0",
            "Kubasta.ttf",
            "áéíóúüñ¿¡",
            "10/12/14/16 px",
            "escalado entero",
            "escalado no entero",
            "SHA-256",
            "Git LFS",
        ):
            with self.subTest(texto=texto):
                self.assertIn(texto, self.doc)

    def test_no_se_promete_cambio_global(self):
        self.assertIn("no sustituye la fuente global", self.doc.lower())
        self.assertIn("IBM Plex Mono", self.doc)


if __name__ == "__main__":
    unittest.main()
