from pathlib import Path
import tempfile
import unittest

try:
    from pyboy import PyBoy
except ImportError:  # pragma: no cover
    PyBoy = None


ROOT = Path(__file__).resolve().parent
ROM = ROOT / "build" / "sueno_98.gbc"
SOURCE = ROOT / "main.asm"
SYMBOLS = ROOT / "build" / "sueno_98.sym"


class Sueno98SourceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_handshake_solo_en_objetivo_final(self):
        self.assertIn('SECTION "Handshake", WRAM0[$C100]', self.source)
        self.assertIn("DEF MARCA_COMPLETADO EQU $A5", self.source)
        bloque = self.source.split("CompletarObjetivoFinal:", 1)[1].split(
            "DibujarTitulo:", 1
        )[0]
        self.assertIn("ld [wSuenoCompletado], a", bloque)

    def test_tres_composiciones_deterministas(self):
        self.assertIn("Objetivos:", self.source)
        self.assertIn("db %00000101, %00000110, %00000011", self.source)

    def test_rom_no_conoce_estado_literario(self):
        lower = self.source.lower()
        for termino in ("literaturaeventos", "partida", "conocimiento", "insight"):
            self.assertNotIn(termino, lower)

    def test_cabecera_dual(self):
        self.assertTrue(ROM.exists())
        data = ROM.read_bytes()
        self.assertGreaterEqual(len(data), 32768)
        self.assertEqual(data[0x134:0x143].rstrip(b"\0"), b"SUENO98")
        self.assertEqual(data[0x143], 0x80)


@unittest.skipIf(PyBoy is None, "PyBoy 2.6.1 no instalado")
class Sueno98PlayTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rom = ROM.read_bytes()
        cls.symbols = {}
        for line in SYMBOLS.read_text(encoding="utf-8").splitlines():
            if line and not line.startswith(";"):
                address, name = line.split()
                cls.symbols[name] = int(address.split(":")[1], 16)

    def start(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        path = Path(tmp.name) / "sueno_98.gbc"
        path.write_bytes(self.rom)
        emulator = PyBoy(str(path), window="null", sound_emulated=False, cgb=True)
        self.addCleanup(lambda: emulator.stop(save=False))
        emulator.tick(90, False)
        return emulator

    def read(self, emulator, name):
        return emulator.memory[self.symbols[name]]

    def press(self, emulator, button):
        emulator.button_press(button)
        emulator.tick(2, False)
        emulator.button_release(button)
        emulator.tick(12, False)

    def test_arranque_error_parciales_y_final(self):
        emulator = self.start()
        self.assertEqual(self.read(emulator, "wSuenoCompletado"), 0)
        self.press(emulator, "start")
        self.assertEqual(self.read(emulator, "wSuenoCompletado"), 0)

        self.press(emulator, "start")
        self.assertEqual(self.read(emulator, "wRonda"), 0)
        self.assertEqual(self.read(emulator, "wSuenoCompletado"), 0)

        self.press(emulator, "a")
        self.press(emulator, "right")
        self.press(emulator, "right")
        self.press(emulator, "a")
        self.assertEqual(self.read(emulator, "wSuenoCompletado"), 0)
        self.press(emulator, "start")
        self.assertEqual(self.read(emulator, "wRonda"), 1)
        self.assertEqual(self.read(emulator, "wSuenoCompletado"), 0)

        self.press(emulator, "right")
        self.press(emulator, "a")
        self.press(emulator, "right")
        self.press(emulator, "a")
        self.press(emulator, "start")
        self.assertEqual(self.read(emulator, "wRonda"), 2)
        self.assertEqual(self.read(emulator, "wSuenoCompletado"), 0)

        self.press(emulator, "a")
        self.press(emulator, "right")
        self.press(emulator, "a")
        self.assertEqual(self.read(emulator, "wSuenoCompletado"), 0)
        self.press(emulator, "start")
        self.assertEqual(self.read(emulator, "wSuenoCompletado"), 0xA5)

        self.press(emulator, "a")
        self.assertEqual(self.read(emulator, "wSuenoCompletado"), 0)


if __name__ == "__main__":
    unittest.main()
