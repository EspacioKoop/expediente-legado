from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "main.asm"
ROM = ROOT / "build" / "ryu_flow.gbc"


class RyuFlowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_arranca_con_tres_compuertas_incorrectas(self):
        self.assertIn("DEF COMPUERTAS_INICIALES EQU %00000101", self.source)
        self.assertIn("DEF SOLUCION_COMPUERTAS  EQU %00000010", self.source)
        self.assertIn("ld a, COMPUERTAS_INICIALES", self.source)

    def test_exige_manipular_las_tres_compuertas(self):
        self.assertIn("DEF TODAS_TOCADAS        EQU %00000111", self.source)
        self.assertIn("or %00000001", self.source)
        self.assertIn("or %00000010", self.source)
        self.assertIn("or %00000100", self.source)
        bloque = self.source.split("ComprobarSolucion:", 1)[1].split("CompletarFlujo:", 1)[0]
        self.assertIn("cp TODAS_TOCADAS", bloque)
        self.assertIn("cp SOLUCION_COMPUERTAS", bloque)

    def test_completion_marker_es_estable_y_no_se_escribe_al_arrancar(self):
        self.assertIn('SECTION "Handshake", WRAM0[$C100]', self.source)
        self.assertIn("DEF MARCA_COMPLETADO     EQU $A5", self.source)
        bloque = self.source.split("CompletarFlujo:", 1)[1].split("DesactivarLCD:", 1)[0]
        self.assertIn("ld a, MARCA_COMPLETADO", bloque)
        self.assertIn("ld [wRyuFlowCompletado], a", bloque)

    def test_rom_compilada_es_dual_mode_y_tiene_titulo_propio(self):
        self.assertTrue(ROM.exists(), "falta compilar build/ryu_flow.gbc")
        data = ROM.read_bytes()
        self.assertGreaterEqual(len(data), 32768)
        self.assertEqual(data[0x134:0x13F].rstrip(b"\0"), b"RYUFLOW98")
        self.assertEqual(data[0x143], 0x80)


if __name__ == "__main__":
    unittest.main()
