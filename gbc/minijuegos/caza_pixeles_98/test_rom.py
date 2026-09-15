from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "main.asm"
ROM = ROOT / "build" / "caza_pixeles_98.gbc"


class CazaPixeles98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_combo_tiene_ventana_y_tres_multiplicadores(self):
        self.assertIn("DEF COMBO_DURACION    EQU 90", self.source)
        self.assertIn("DEF COMBO_X2          EQU 3", self.source)
        self.assertIn("DEF COMBO_X3          EQU 6", self.source)
        self.assertIn("RegistrarCaptura:", self.source)
        self.assertIn("TickCombo:", self.source)
        self.assertIn("wMultiplicador", self.source)
        self.assertIn("ld a, 99", self.source)

    def test_objetivos_usan_rng_y_no_repeticion_inmediata(self):
        self.assertIn("DEF rDIV", self.source)
        self.assertIn("AvanzarRng:", self.source)
        self.assertIn("xor $B8", self.source)
        self.assertIn("call AvanzarRng", self.source)
        self.assertIn("wRng", self.source)
        self.assertIn("cp b\n    jr nz, .indice_listo", self.source)

    def test_dificultad_tolera_saltos_de_puntuacion(self):
        bloque = self.source.split("AjustarDificultad:", 1)[1].split("AvanzarRng:", 1)[0]
        self.assertIn("cp 20\n    jr nc, .nivel3", bloque)
        self.assertIn("cp 10\n    jr nc, .nivel2", bloque)
        self.assertIn("cp 5\n    ret c", bloque)

    def test_hud_expone_multiplicador(self):
        self.assertIn("ld hl, BG_MAP + 9", self.source)
        self.assertIn("ld a, TILE_X", self.source)
        self.assertIn("ld hl, BG_MAP + 10", self.source)

    def test_rom_compilada_conserva_cabecera(self):
        self.assertTrue(ROM.exists(), "falta compilar build/caza_pixeles_98.gbc")
        data = ROM.read_bytes()
        self.assertGreaterEqual(len(data), 32768)
        self.assertEqual(data[0x134:0x13F].rstrip(b"\0"), b"CAZAPIXEL98")
        self.assertEqual(data[0x143], 0x80)


if __name__ == "__main__":
    unittest.main()
