from pathlib import Path
import re
import tempfile
import unittest

try:
    from pyboy import PyBoy
except ImportError:  # pragma: no cover - CI instala PyBoy explicitamente
    PyBoy = None


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "main.asm"
ROM = ROOT / "build" / "ryu_flow_98.gbc"
SIMBOLOS = ROOT / "build" / "ryu_flow_98.sym"
VARIANTES = ROOT / "assets" / "juego_variantes.inc"
PRIMER_TILE_SPRITE = 240


def _parches():
    """Parches de juego_variantes.inc: nombre -> [(fila, columna, tile, atributos)]."""
    parches, actual = {}, None
    for linea in VARIANTES.read_text(encoding="utf-8").splitlines():
        if linea.endswith(":"):
            actual = parches.setdefault(linea[len("JuegoCGB_"):-1], [])
            continue
        valores = re.findall(r"\$?[0-9A-Fa-f]+", linea.split(";", 1)[0].replace("db", ""))
        if actual is not None and len(valores) == 4:
            actual.append(tuple(int(v.lstrip("$"), 16 if v.startswith("$") else 10) for v in valores))
    return parches


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
        self.assertTrue(ROM.exists(), "falta compilar build/ryu_flow_98.gbc")
        data = ROM.read_bytes()
        self.assertGreaterEqual(len(data), 32768)
        self.assertEqual(data[0x134:0x143].rstrip(b"\0"), b"RYUFLOW98")
        self.assertEqual(data[0x143], 0x80)


class ArteCGBTest(unittest.TestCase):
    """Pantalla de juego y victoria convertidas de la lámina (#808)."""

    def test_los_parches_caben_y_no_pisan_los_tiles_de_sprite(self):
        parches = _parches()
        self.assertEqual(len(parches), 12)
        banco1 = len(re.findall(r"^    db ", (ROOT / "assets" / "juego_tiles1.inc").read_text(), re.M))
        self.assertLessEqual(banco1, PRIMER_TILE_SPRITE)
        for nombre in ("Abierta1", "Abierta2", "Abierta3", "Correcta1", "Correcta2", "Correcta3"):
            with self.subTest(parche=nombre):
                propio, base = parches[nombre], parches[nombre + "_Base"]
                self.assertTrue(propio)
                self.assertEqual([c[:2] for c in propio], [c[:2] for c in base])
                for fila, columna, _tile, atributos in propio:
                    self.assertLess(fila, 18)
                    self.assertLess(columna, 20)
                    self.assertEqual(atributos & 0b10010000, 0)

    def test_los_sprites_se_vuelcan_tras_despertar_en_vblank(self):
        self.assertIn("DEF OAM_BASE   EQU $C200", self.source)
        self.assertIn("    halt\n    call VolcarOAM\n", self.source)
        # El DMA desde la interrupción bloqueaba los controles en el núcleo de la portátil.
        self.assertNotIn("rDMA", self.source)

    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")


@unittest.skipIf(PyBoy is None, "PyBoy 2.6.1 no instalado")
class PartidaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rom = ROM.read_bytes()
        cls.simbolos = {}
        for linea in SIMBOLOS.read_text().splitlines():
            if linea and not linea.startswith(";"):
                direccion, nombre = linea.split()
                cls.simbolos[nombre] = int(direccion.split(":")[1], 16)
        cls.parches = _parches()

    def arrancar(self, cgb):
        carpeta = tempfile.TemporaryDirectory()
        self.addCleanup(carpeta.cleanup)
        ruta = Path(carpeta.name) / "ryu_flow_98.gbc"
        ruta.write_bytes(self.rom)
        emulador = PyBoy(str(ruta), window="null", sound_emulated=False, cgb=cgb)
        self.addCleanup(lambda: emulador.stop(save=False))
        emulador.tick(90, False)
        return emulador

    def leer(self, emulador, nombre, desplazamiento=0):
        return emulador.memory[self.simbolos[nombre] + desplazamiento]

    def pulsar(self, emulador, boton):
        emulador.button_press(boton)
        emulador.tick(2, False)
        emulador.button_release(boton)
        emulador.tick(12, False)

    def assert_parche(self, emulador, nombre):
        for fila, columna, tile, _atributos in self.parches[nombre]:
            self.assertEqual(emulador.memory[0x9800 + fila * 32 + columna], tile, f"{nombre} ({fila},{columna})")

    def test_gbc_abre_compuertas_cuenta_y_despierta_al_dragon(self):
        emulador = self.arrancar(cgb=True)
        self.pulsar(emulador, "start")
        self.assertEqual(self.leer(emulador, "wModoCGB"), 1)
        # Arranque %101: la segunda abierta y ninguna en su sitio.
        self.assert_parche(emulador, "Abierta1_Base")
        self.assert_parche(emulador, "Abierta2")
        self.assert_parche(emulador, "Abierta3_Base")
        self.assert_parche(emulador, "Correcta1_Base")
        self.assertEqual(self.leer(emulador, "wCorrectas"), 0)

        self.pulsar(emulador, "a")
        self.assert_parche(emulador, "Abierta1")
        self.assert_parche(emulador, "Correcta1")
        self.assertEqual(self.leer(emulador, "wCorrectas"), 1)
        self.assertEqual([self.leer(emulador, "wMovimientos", i) for i in range(3)], [0, 0, 1])
        # Cursor y cifras del HUD en la OAM real (copiada por DMA).
        self.assertEqual(emulador.memory[0xFE00 + 2], PRIMER_TILE_SPRITE + 10)
        self.assertEqual(emulador.memory[0xFE00 + 6], PRIMER_TILE_SPRITE + 1)
        self.assertEqual(self.leer(emulador, "wRyuFlowCompletado"), 0)

        self.pulsar(emulador, "right")
        self.pulsar(emulador, "a")
        self.assert_parche(emulador, "Abierta2_Base")
        self.pulsar(emulador, "right")
        self.pulsar(emulador, "a")
        emulador.tick(10, False)
        self.assertEqual(self.leer(emulador, "wRyuFlowCompletado"), 0xA5)
        self.assertEqual(self.leer(emulador, "wPantallaCGB"), 1)
        # Sin cursor ni cifras sobre la pantalla de victoria.
        self.assertEqual(emulador.memory[0xFE00], 0)

        self.pulsar(emulador, "a")
        self.assertEqual(self.leer(emulador, "wRyuFlowCompletado"), 0)
        self.assertEqual(self.leer(emulador, "wCorrectas"), 0)

    def test_game_boy_clasica_conserva_la_version_de_texto(self):
        emulador = self.arrancar(cgb=False)
        self.pulsar(emulador, "start")
        self.assertEqual(self.leer(emulador, "wModoCGB"), 0)
        for boton in ("a", "right", "a", "right", "a"):
            self.pulsar(emulador, boton)
        emulador.tick(10, False)
        self.assertEqual(self.leer(emulador, "wRyuFlowCompletado"), 0xA5)


if __name__ == "__main__":
    unittest.main()
