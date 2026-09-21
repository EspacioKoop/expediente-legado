from pathlib import Path
import tempfile
import unittest

try:
    from pyboy import PyBoy
except ImportError:  # pragma: no cover
    PyBoy = None


ROOT = Path(__file__).resolve().parent
ROM = ROOT / "build" / "sarnath_98.gbc"
SOURCE = ROOT / "main.asm"
SYMBOLS = ROOT / "build" / "sarnath_98.sym"


class Sarnath98SourceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_handshake_solo_en_final(self):
        self.assertIn('SECTION "Handshake", WRAM0[$C100]', self.source)
        self.assertIn("DEF MARCA_COMPLETADO EQU $A5", self.source)
        block = self.source.split("CompletarRutaFinal:", 1)[1].split("DibujarEstudio:", 1)[0]
        self.assertIn("ld [wSarnathCompletado], a", block)

    def test_tres_rutas_deterministas(self):
        self.assertIn("Ruta0:", self.source)
        self.assertIn("Ruta1:", self.source)
        self.assertIn("Ruta2:", self.source)
        self.assertIn("db KEY_UP, KEY_RIGHT, KEY_UP", self.source)
        self.assertIn("db KEY_LEFT, KEY_UP, KEY_RIGHT, KEY_DOWN", self.source)
        self.assertIn("db KEY_UP, KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_LEFT", self.source)

    def test_no_gamifica_practica_religiosa(self):
        lower = self.source.lower()
        for term in ("karma", "merito", "mérito", "iluminacion", "meditacion", "recitacion"):
            self.assertNotIn(term, lower)

    def test_cabecera_dual(self):
        self.assertTrue(ROM.exists())
        data = ROM.read_bytes()
        self.assertGreaterEqual(len(data), 32768)
        self.assertEqual(data[0x134:0x143].rstrip(b"\0"), b"SARNATH98")
        self.assertEqual(data[0x143], 0x80)


@unittest.skipIf(PyBoy is None, "PyBoy 2.6.1 no instalado")
class Sarnath98PlayTest(unittest.TestCase):
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
        path = Path(tmp.name) / "sarnath_98.gbc"
        path.write_bytes(self.rom)
        emulator = PyBoy(str(path), window="null", sound_emulated=False, cgb=True)
        self.addCleanup(lambda: emulator.stop(save=False))
        emulator.tick(90, False)
        return emulator

    def read(self, emulator, name, offset=0):
        return emulator.memory[self.symbols[name] + offset]

    def press(self, emulator, button):
        emulator.button_press(button)
        emulator.tick(2, False)
        emulator.button_release(button)
        emulator.tick(12, False)

    def route(self, emulator, buttons):
        self.press(emulator, "a")
        for button in buttons:
            self.press(emulator, button)

    def test_error_y_tres_rondas(self):
        emulator = self.start()
        self.assertEqual(self.read(emulator, "wSarnathCompletado"), 0)
        self.press(emulator, "start")

        self.press(emulator, "a")
        self.press(emulator, "down")
        self.assertEqual(self.read(emulator, "wRonda"), 0)
        self.assertEqual(self.read(emulator, "wSarnathCompletado"), 0)

        self.route(emulator, ["up", "right", "up"])
        self.assertEqual(self.read(emulator, "wRonda"), 1)
        self.assertEqual(self.read(emulator, "wSarnathCompletado"), 0)

        self.route(emulator, ["left", "up", "right", "down"])
        self.assertEqual(self.read(emulator, "wRonda"), 2)
        self.assertEqual(self.read(emulator, "wSarnathCompletado"), 0)

        self.route(emulator, ["up", "up", "right", "down", "left"])
        self.assertEqual(self.read(emulator, "wSarnathCompletado"), 0xA5)

        self.press(emulator, "a")
        self.assertEqual(self.read(emulator, "wSarnathCompletado"), 0)


if __name__ == "__main__":
    unittest.main()
