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


def _constantes_dragon():
    texto = (ROOT / "assets" / "dragon_constantes.inc").read_text(encoding="utf-8")
    return {nombre: int(valor) for nombre, valor in re.findall(r"DEF (\w+) EQU (\d+)", texto)}


def _fotogramas(nombre):
    """dragon_<nombre>_fotogramas.inc: lista de fotogramas con sus (fila, columna, tile)."""
    fotogramas = []
    for linea in (ROOT / "assets" / f"dragon_{nombre}_fotogramas.inc").read_text(encoding="utf-8").splitlines():
        if linea.endswith(":"):
            fotogramas.append([])
        elif linea.strip().startswith("db ") and fotogramas:
            valores = [int(v) for v in linea.strip()[3:].split(",")]
            if len(valores) == 3:
                fotogramas[-1].append(tuple(valores))
    return fotogramas


def _niveles(source):
    """Tabla Niveles: por nivel, (siguiente, acoplado, inicial, solución)."""
    bloque = source.split("Niveles:", 1)[1].split("ColumnasCompuertaDMG:", 1)[0]
    estados = {"ABIERTA": 0, "MEDIA": 1, "CERRADA": 2}
    valores = []
    for linea in bloque.splitlines():
        linea = linea.split(";", 1)[0].strip()
        if linea.startswith("db "):
            valores += [estados.get(v.strip(), None) if v.strip() in estados else int(v) for v in linea[3:].split(",")]
    return [(valores[k:k + 3], valores[k + 3], valores[k + 4:k + 7], valores[k + 7:k + 10])
            for k in range(0, len(valores), 10)]


def _pulsaciones_minimas(siguiente, acoplado, inicial, solucion):
    """Búsqueda en anchura sobre los estados del nivel."""
    from collections import deque

    inicio = (tuple(inicial), 0)
    vistos = {inicio: 0}
    cola = deque([inicio])
    while cola:
        estado, tocados = cola.popleft()
        if list(estado) == solucion and tocados == 0b111:
            return vistos[(estado, tocados)]
        for i in range(3):
            nuevo = list(estado)
            for j in {i, i + 1} if acoplado else {i}:
                if j < 3:
                    nuevo[j] = siguiente[nuevo[j]]
            clave = (tuple(nuevo), tocados | 1 << i)
            if clave not in vistos:
                vistos[clave] = vistos[(estado, tocados)] + 1
                cola.append(clave)
    return None


class RyuFlowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")
        cls.niveles = _niveles(cls.source)

    def test_cada_nivel_arranca_con_las_tres_compuertas_incorrectas(self):
        self.assertEqual(len(self.niveles), 3)
        for n, (_siguiente, _acoplado, inicial, solucion) in enumerate(self.niveles, start=1):
            with self.subTest(nivel=n):
                self.assertTrue(all(a != b for a, b in zip(inicial, solucion)))

    def test_los_niveles_tienen_solucion_y_crecen(self):
        minimas = [_pulsaciones_minimas(*nivel) for nivel in self.niveles]
        self.assertEqual(minimas, [3, 6, 6])
        # El primero solo abre y cierra; el segundo añade la posición media; en
        # el tercero cada compuerta arrastra a la de su derecha.
        self.assertEqual([nivel[1] for nivel in self.niveles], [0, 0, 1])
        self.assertNotIn(1, self.niveles[0][0][::2])

    def test_exige_manipular_las_tres_compuertas(self):
        self.assertIn("DEF TODAS_TOCADAS        EQU %00000111", self.source)
        bloque = self.source.split("ComprobarSolucion:", 1)[1].split("CompletarFlujo:", 1)[0]
        self.assertIn("cp TODAS_TOCADAS", bloque)
        self.assertIn("ld de, NIVEL_SOLUCION", bloque)

    def test_completion_marker_es_estable_y_no_se_escribe_al_arrancar(self):
        self.assertIn('SECTION "Handshake", WRAM0[$C100]', self.source)
        self.assertIn("DEF MARCA_COMPLETADO     EQU $A5", self.source)
        bloque = self.source.split("CompletarFlujo:", 1)[1].split("DesactivarLCD:", 1)[0]
        self.assertIn("ld a, MARCA_COMPLETADO", bloque)
        self.assertIn("ld [wRyuFlowCompletado], a", bloque)
        # Solo el último nivel lleva a CompletarFlujo.
        bloque = self.source.split("ComprobarSolucion:", 1)[1].split("CompletarFlujo:", 1)[0]
        self.assertIn("cp NUM_NIVELES - 1", bloque)

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
        self.assertEqual(len(parches), 24)
        banco1 = len(re.findall(r"^    db ", (ROOT / "assets" / "juego_tiles1.inc").read_text(), re.M))
        self.assertLessEqual(banco1, PRIMER_TILE_SPRITE)
        nombres = [f"{tipo}{n}" for tipo in ("Abierta", "Media", "Correcta", "Dialogo") for n in (1, 2, 3)]
        for nombre in nombres:
            with self.subTest(parche=nombre):
                propio, base = parches[nombre], parches[nombre + "_Base"]
                self.assertTrue(propio)
                self.assertEqual([c[:2] for c in propio], [c[:2] for c in base])
                for fila, columna, _tile, atributos in propio:
                    self.assertLess(fila, 18)
                    self.assertLess(columna, 20)
                    self.assertEqual(atributos & 0b10010000, 0)

    def test_el_agua_tiene_paleta_propia_y_tres_brillos_por_nivel(self):
        def palabras(ruta):
            return [int(v, 16) for v in re.findall(r"\$([0-9A-Fa-f]{4})", ruta.read_text().split("\n", 1)[-1]
                    if ruta.name == "juego_agua.inc" else ruta.read_text())]

        agua = palabras(ROOT / "assets" / "juego_agua.inc")
        self.assertEqual(len(agua), 3 * 3 * 4)
        for n, nombre in enumerate(("juego_paletas", "juego_paletas_amanecer", "juego_paletas_noche")):
            with self.subTest(nivel=nombre):
                paletas = palabras(ROOT / "assets" / f"{nombre}.inc")
                # El primer brillo de cada nivel es su paleta del agua sin tocar.
                self.assertEqual(agua[n * 12:n * 12 + 4], paletas[2 * 4:3 * 4])
                # Nada del rojo de los torii colado en la paleta: la espuma del
                # amanecer es crema (31,28,23), el naranja que se coló era (24,15,9).
                for color in agua[n * 12:(n + 1) * 12]:
                    rojo, azul = color & 31, color >> 10 & 31
                    self.assertLessEqual(rojo - azul, 10)
        self.assertIn("    halt\n    call VolcarOAM\n    call AnimarAgua\n", self.source)

    def test_el_dragon_cabe_en_vram_y_respeta_los_sprites_por_linea(self):
        constantes = _constantes_dragon()
        for pantalla, tiles_dragon in (("juego", "DRAGON_TILES_CABEZA"), ("victoria", "DRAGON_TILES_RUGIDO")):
            with self.subTest(pantalla=pantalla):
                banco1 = len(re.findall(r"^    db ", (ROOT / "assets" / f"{pantalla}_tiles1.inc").read_text(), re.M))
                self.assertLessEqual(banco1, PRIMER_TILE_SPRITE - constantes[tiles_dragon])
        # Cabeza (y 58) lejos del cursor y del HUD: basta con que cada fila de tiles
        # no pase de 10 sprites. El rugido va solo en la victoria.
        for nombre in ("cabeza", "rugido"):
            for k, entradas in enumerate(_fotogramas(nombre)):
                with self.subTest(sprite=nombre, fotograma=k):
                    por_fila = {}
                    for fila, _columna, _tile in entradas:
                        por_fila[fila] = por_fila.get(fila, 0) + 1
                    self.assertLessEqual(max(por_fila.values()), 10)
        self.assertEqual(len(_fotogramas("cabeza")), constantes["DRAGON_FOTOGRAMAS_CABEZA"])
        self.assertEqual(len(_fotogramas("rugido")), 2)

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

    def cerrar_dialogo(self, emulador, nivel):
        self.assertEqual(self.leer(emulador, "wNivel"), nivel)
        self.assert_parche(emulador, f"Dialogo{nivel + 1}")
        # Con el cuadro abierto no hay cursor ni cifras.
        self.assertEqual(emulador.memory[0xFE00], 0)
        self.pulsar(emulador, "a")
        self.assert_parche(emulador, f"Dialogo{nivel + 1}_Base")

    def jugar(self, emulador, secuencia):
        for boton in secuencia:
            self.pulsar(emulador, boton)

    def test_gbc_tres_niveles_con_dialogos_hasta_despertar_al_dragon(self):
        emulador = self.arrancar(cgb=True)
        self.pulsar(emulador, "start")
        self.assertEqual(self.leer(emulador, "wModoCGB"), 1)
        paso = self.leer(emulador, "wAguaPaso")
        emulador.tick(25, False)  # 4 pasos de 10 fotogramas volverían al mismo brillo
        self.assertNotEqual(self.leer(emulador, "wAguaPaso"), paso, "el agua no se anima")
        self.cerrar_dialogo(emulador, 0)
        # Arranque del 1-1: la segunda abierta y ninguna en su sitio.
        self.assert_parche(emulador, "Abierta1_Base")
        self.assert_parche(emulador, "Abierta2")
        self.assert_parche(emulador, "Abierta3_Base")
        self.assert_parche(emulador, "Correcta1_Base")
        self.assertEqual(self.leer(emulador, "wCorrectas"), 0)

        # La cabeza del dragón acompaña a la partida.
        constantes = _constantes_dragon()
        primer_cabeza = PRIMER_TILE_SPRITE - constantes["DRAGON_TILES_CABEZA"]
        self.assertTrue(primer_cabeza <= emulador.memory[0xFE00 + 6 * 4 + 2] < PRIMER_TILE_SPRITE)
        self.assertEqual(self.leer(emulador, "wReaccion"), 0)

        self.pulsar(emulador, "a")
        self.assert_parche(emulador, "Abierta1")
        self.assert_parche(emulador, "Correcta1")
        self.assertEqual(self.leer(emulador, "wCorrectas"), 1)
        # Acertar despierta al dragón.
        self.assertGreater(self.leer(emulador, "wReaccion"), 0)
        self.assertEqual([self.leer(emulador, "wMovimientos", i) for i in range(3)], [0, 0, 1])
        # Cursor, nivel y dragones en la OAM real.
        self.assertEqual(emulador.memory[0xFE00 + 2], PRIMER_TILE_SPRITE + 10)
        self.assertEqual(emulador.memory[0xFE04 + 2], PRIMER_TILE_SPRITE + 1)
        self.assertEqual(emulador.memory[0xFE08 + 2], PRIMER_TILE_SPRITE + 1)

        self.jugar(emulador, ["right", "a", "right", "a"])
        emulador.tick(60, False)
        self.assertEqual(self.leer(emulador, "wRyuFlowCompletado"), 0)

        # 1-2, amanecer: la compuerta pasa por la posición media.
        self.cerrar_dialogo(emulador, 1)
        self.assertEqual(emulador.memory[0xFE04 + 2], PRIMER_TILE_SPRITE + 2)
        # Ciclo abierta -> media -> cerrada: la primera, cerrada, pasa por abierta.
        self.pulsar(emulador, "a")
        self.assert_parche(emulador, "Abierta1")
        self.pulsar(emulador, "a")
        self.assert_parche(emulador, "Media1")
        self.jugar(emulador, ["right", "a", "a", "right", "a", "a"])
        emulador.tick(60, False)
        self.assertEqual(self.leer(emulador, "wRyuFlowCompletado"), 0)

        # 1-3, noche: pulsar la primera arrastra a la segunda.
        self.cerrar_dialogo(emulador, 2)
        self.pulsar(emulador, "a")
        self.assertEqual([self.leer(emulador, "wEstados", i) for i in range(3)], [0, 0, 2])
        self.jugar(emulador, ["a", "right", "a", "a", "right", "a", "a"])
        emulador.tick(10, False)
        self.assertEqual(self.leer(emulador, "wRyuFlowCompletado"), 0xA5)
        self.assertEqual(self.leer(emulador, "wPantallaCGB"), 1)
        # En la victoria ruge el dragón y no queda cursor ni cifras.
        constantes = _constantes_dragon()
        primer_rugido = PRIMER_TILE_SPRITE - constantes["DRAGON_TILES_RUGIDO"]
        tiles = [emulador.memory[0xFE00 + 4 * k + 2] for k in range(40) if emulador.memory[0xFE00 + 4 * k]]
        self.assertTrue(tiles)
        self.assertTrue(all(primer_rugido <= t < PRIMER_TILE_SPRITE for t in tiles), tiles)

        self.pulsar(emulador, "a")
        self.assertEqual(self.leer(emulador, "wRyuFlowCompletado"), 0)
        self.assertEqual(self.leer(emulador, "wNivel"), 0)

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
