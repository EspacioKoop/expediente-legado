from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CATALOGO = ROOT / "docs" / "gbc-fixtures.md"


class GbcFixtureCatalogTest(unittest.TestCase):
    def setUp(self):
        self.texto = CATALOGO.read_text(encoding="utf-8")

    def test_hay_al_menos_cinco_candidatos_revisados(self):
        filas = [
            linea
            for linea in self.texto.splitlines()
            if linea.startswith("|")
            and "---" not in linea
            and "proyecto" not in linea
        ]
        self.assertGreaterEqual(len(filas), 5)

    def test_hay_pruebas_reproducibles_de_joypad_video_y_cgb(self):
        self.assertIn("simple-gb-asm-examples/joypad", self.texto)
        self.assertIn("simple-gb-asm-examples/vblank", self.texto)
        self.assertIn("cgb-acid2", self.texto)

    def test_separacion_entre_redistribucion_y_fixture_externo(self):
        self.assertIn("solo fixture externo", self.texto)
        self.assertIn("SHA-256 obligatorio", self.texto)
        self.assertIn("No se versiona aquí ninguna BIOS, ROM comercial", self.texto)

    def test_licencias_de_los_candidatos_clave_quedan_explicitas(self):
        for licencia in ("CC0-1.0", "MIT", "Zlib", "GPL-3.0+", "CC BY-SA 4.0"):
            with self.subTest(licencia=licencia):
                self.assertIn(licencia, self.texto)


if __name__ == "__main__":
    unittest.main()
