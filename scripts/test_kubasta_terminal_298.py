"""Contrato de Kubasta para terminales (#298)."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ESTILO = ROOT / "godot" / "guion" / "estilo_siga.gd"
DOC = ROOT / "docs" / "assets" / "kubasta-terminal-298.md"
MATERIALIZADOR = ROOT / "scripts" / "materializar_kubasta_298.py"


class KubastaTerminal298Test(unittest.TestCase):
    def setUp(self):
        self.estilo = ESTILO.read_text(encoding="utf-8")
        self.doc = DOC.read_text(encoding="utf-8")
        self.materializador = MATERIALIZADOR.read_text(encoding="utf-8")

    def test_terminal_es_un_rol_independiente_con_fallback(self):
        self.assertIn(
            'const RUTA_FUENTE_TERMINAL := "res://assets/fonts/Kubasta.ttf"',
            self.estilo,
        )
        self.assertIn("static func fuente_terminal() -> Font:", self.estilo)
        self.assertIn("ResourceLoader.exists(RUTA_FUENTE_TERMINAL)", self.estilo)
        self.assertIn("return kubasta", self.estilo)
        self.assertIn("return fuente_mono()", self.estilo)
        self.assertIn(
            'tema.set_font("terminal_font", "RichTextLabel", terminal)',
            self.estilo,
        )
        self.assertIn(
            'tema.set_font("terminal_font", "LineEdit", terminal)',
            self.estilo,
        )

    def test_mono_generica_sigue_siend_IBM_plex(self):
        self.assertIn(
            'const RUTA_FUENTE_MONO := "res://assets/fonts/IBMPlexMono-Regular.ttf"',
            self.estilo,
        )
        bloque_mono = self.estilo.split("static func fuente_mono() -> Font:", 1)[1].split(
            "static func fuente_terminal() -> Font:", 1
        )[0]
        self.assertNotIn("Kubasta.ttf", bloque_mono)

    def test_paquete_y_ttf_auditados_quedan_fijados(self):
        for texto in (
            "e2d4c74fbec43a9c5b9d1b818fb943976144be2980bd504e83b0f4f21a8a288c",
            "73febb398631f45a0763e275dcb8c4d60fe74ac9e00e74edb21b176f7b4d6824",
            "150.820 bytes",
            "902 puntos Unicode",
            "áéíóúüñ¿¡ ÁÉÍÓÚÜÑ",
            "10/12/14/16 px",
        ):
            with self.subTest(texto=texto):
                self.assertIn(texto, self.doc)

    def test_materializador_exige_procedencia_y_lfs_real(self):
        for texto in (
            'DESTINO_REL = Path("godot/assets/fonts/Kubasta.ttf")',
            'PROCEDENCIA_REL = Path("godot/assets/procedencia.json")',
            "filter=lfs",
            "puntero LFS canónico",
            "paquete_sha256",
            "archivo_origen",
        ):
            with self.subTest(texto=texto):
                self.assertIn(texto, self.materializador)

    def test_no_se_promete_cambio_global(self):
        self.assertIn("no cambia visualmente", self.doc.lower())
        self.assertIn("IBM Plex Mono", self.doc)
        doc_normalizado = " ".join(self.doc.split())
        self.assertIn("no se convierte Kubasta en fuente global", doc_normalizado)


if __name__ == "__main__":
    unittest.main()
