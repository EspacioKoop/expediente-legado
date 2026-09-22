from pathlib import Path
import tempfile
import unittest

try:
    from pyboy import PyBoy
except ImportError:  # pragma: no cover - CI instala PyBoy explicitamente
    PyBoy = None


ROOT = Path(__file__).resolve().parent
ROM = ROOT / "build" / "jali_98.gbc"
SOURCE = ROOT / "main.asm"
SYMBOLS = ROOT / "build" / "jali_98.sym"


class Jali98SourceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_handshake_solo_en_final(self):
        self.assertIn('SECTION "Handshake", WRAM0[$C100]', self.source)
        self.assertIn("DEF MARCA_COMPLETADO EQU $A5", self.source)
        block = self.source.split("CompletarJali:", 1)[1].split("ActualizarJuego:", 1)[0]
        self.assertIn("ld a, MARCA_COMPLETADO", block)
        self.assertIn("ld [wJaliCompletado], a", block)
        start = self.source.split("IniciarJuego:", 1)[1].split("SeleccionarAnterior:", 1)[0]
        self.assertIn("ld [wJaliCompletado], a", start)

    def test_solucion_exige_tres_bandas_manipuladas(self):
        self.assertIn("DEF TODAS_TOCADAS    EQU %00000111", self.source)
        block = self.source.split("ComprobarSolucion:", 1)[1].split("CompletarJali:", 1)[0]
        self.assertIn("cp TODAS_TOCADAS", block)
        for phase in ("cp 1", "cp 3", "cp 2"):
            self.assertIn(phase, block)

    def test_representacion_evade_texto_sagrado_como_mecanica(self):
        lower = self.source.lower()
        for term in ("quran", "allah", "coran"):
            self.assertNotIn(term, lower)

    def test_rom_compilada_es_dual_y_tiene_cabecera_estable(self):
        self.assertTrue(ROM.exists(), "falta compilar build/jali_98.gbc")
        data = ROM.read_bytes()
        self.assertGreaterEqual(len(data), 32768)
        self.assertEqual(data[0x134:0x143].rstrip(b"\0"), b"JALI98")
        self.assertEqual(data[0x143], 0x80)


@unittest.skipIf(PyBoy is None, "PyBoy 2.6.1 no instalado")
class Jali98PlayTest(unittest.TestCase):
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
        path = Path(tmp.name) / "jali_98.gbc"
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

    def test_arranque_parcial_y_solucion(self):
        emulator = self.start()
        self.assertEqual(self.read(emulator, "wJaliCompletado"), 0)

        self.press(emulator, "start")
        self.assertEqual(self.read(emulator, "wJaliCompletado"), 0)

        self.press(emulator, "right")
        self.assertEqual(self.read(emulator, "wFases"), 1)
        self.assertEqual(self.read(emulator, "wJaliCompletado"), 0)

        self.press(emulator, "down")
        self.press(emulator, "left")
        self.assertEqual(self.read(emulator, "wFases", 1), 3)
        self.assertEqual(self.read(emulator, "wJaliCompletado"), 0)

        self.press(emulator, "down")
        self.press(emulator, "right")
        self.assertEqual(self.read(emulator, "wJaliCompletado"), 0)
        self.press(emulator, "right")
        self.assertEqual(self.read(emulator, "wFases", 2), 2)
        self.assertEqual(self.read(emulator, "wJaliCompletado"), 0xA5)

        self.press(emulator, "a")
        self.assertEqual(self.read(emulator, "wJaliCompletado"), 0)


if __name__ == "__main__":
    unittest.main()
