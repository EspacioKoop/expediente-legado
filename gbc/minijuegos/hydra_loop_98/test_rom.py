"""Regresiones de HYDRA LOOP 98 sobre la ROM compilada con PyBoy 2.6.1."""

from pathlib import Path
import tempfile
import unittest

try:
    from pyboy import PyBoy
except ImportError:  # pragma: no cover - CI instala PyBoy explicitamente
    PyBoy = None


RAIZ = Path(__file__).resolve().parent
ROM = RAIZ / "build/hydra_loop_98.gbc"
SIMBOLOS = RAIZ / "build/hydra_loop_98.sym"
NIVEL_1 = [2, 0, 2, 0, 0, 0, 2, 0, 2, 0]
NIVEL_2 = [1, 3, 0, 1, 0, 3, 0, 1, 0, 2]
BG = 0x9800
# Indices de tile de main.asm (EQU no exportadas al .sym).
TILE_CABEZA, TILE_HUECO, TILE_SELLO, TILE_CUELLO_LUZ = 3, 9, 21, 27
TILE_PLACA_AGUA, TILE_PLACA_DUDA, TILE_GLIFO, TILE_DIGITO = 34, 35, 36, 39
TILE_L, TILE_O, TILE_P, TILE_R, TILE_T = 49, 50, 51, 52, 53
TILE_ICONO, TILE_RELOJ_ON = 54, 55


def celda(fila, col):
    return BG + fila * 32 + col


class CabeceraROM(unittest.TestCase):
    def test_rom_dual_con_titulo_propio(self):
        datos = ROM.read_bytes()
        self.assertEqual(len(datos), 32768)
        self.assertEqual(datos[0x134:0x143].rstrip(b"\0"), b"HYDRALOOP98")
        self.assertEqual(datos[0x143], 0x80)


@unittest.skipIf(PyBoy is None, "PyBoy 2.6.1 no instalado")
class PruebasHydraLoop(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rom = ROM.read_bytes()
        cls.simbolos = {}
        for linea in SIMBOLOS.read_text().splitlines():
            if linea and not linea.startswith(";"):
                direccion, nombre = linea.split()
                cls.simbolos[nombre] = int(direccion.split(":")[1], 16)

    def arrancar(self, cgb=True):
        carpeta = tempfile.TemporaryDirectory()
        self.addCleanup(carpeta.cleanup)
        ruta = Path(carpeta.name) / "prueba.gbc"
        ruta.write_bytes(self.rom)
        emulador = PyBoy(str(ruta), window="null", sound_emulated=False, cgb=cgb)
        self.addCleanup(lambda: emulador.stop(save=False))
        emulador.tick(90, False)
        return emulador

    def pulsar(self, emulador, boton, espera=2):
        emulador.button_press(boton)
        emulador.tick(2, False)
        emulador.button_release(boton)
        emulador.tick(espera, False)

    def jugar(self, cgb=True):
        emulador = self.arrancar(cgb)
        self.pulsar(emulador, "start")
        self.assertEqual(self.leer(emulador, "wEstado"), 1)
        return emulador

    def leer(self, emulador, nombre, cuantos=None):
        base = self.simbolos[nombre]
        if cuantos is None:
            return emulador.memory[base]
        return emulador.memory[base:base + cuantos]

    def poner(self, emulador, nombre, valor):
        base = self.simbolos[nombre]
        if isinstance(valor, list):
            emulador.memory[base:base + len(valor)] = valor
        else:
            emulador.memory[base] = valor

    def observar(self, emulador, hueco):
        self.poner(emulador, "wCursor", hueco)
        self.pulsar(emulador, "b")
        self.assertGreater(self.leer(emulador, "wBloqueo"), 0)
        emulador.tick(32, False)
        self.assertEqual(self.leer(emulador, "wBloqueo"), 0)

    def accion(self, emulador, objetivo):
        self.poner(emulador, "wCursor", objetivo)
        self.pulsar(emulador, "a")

    def test_portada_no_marca_handshake(self):
        for cgb in (False, True):
            with self.subTest(cgb=cgb):
                emulador = self.arrancar(cgb)
                self.assertEqual(self.leer(emulador, "wEstado"), 0)
                self.assertEqual(emulador.memory[0xC100], 0)

    def test_nivel_1_arranca_con_una_raiz_comun_sin_leer(self):
        emulador = self.jugar()
        self.assertEqual(self.leer(emulador, "wCabezas", 10), NIVEL_1)
        self.assertEqual(self.leer(emulador, "wObservadas", 10), [0] * 10)
        # HUD: nivel 1, cuatro cabezas, reloj lleno.
        self.assertEqual(emulador.memory[BG:BG + 2], [TILE_L, TILE_DIGITO + 1])
        self.assertEqual(emulador.memory[BG + 4:BG + 7],
                         [TILE_ICONO, TILE_DIGITO, TILE_DIGITO + 4])
        self.assertEqual(emulador.memory[BG + 13:BG + 19], [TILE_RELOJ_ON] * 6)
        # Hueco 0 con cabeza sin leer y hueco 1 vacio, con sus placas.
        self.assertEqual(emulador.memory[celda(2, 1)], TILE_CABEZA)
        self.assertEqual(emulador.memory[celda(3, 3)], TILE_PLACA_DUDA)
        self.assertEqual(emulador.memory[celda(2, 5)], TILE_HUECO)
        self.assertEqual(emulador.memory[celda(3, 7)], TILE_PLACA_AGUA)

    def test_cortar_una_cabeza_hace_brotar_dos_de_la_misma_raiz(self):
        emulador = self.jugar()
        self.accion(emulador, 0)
        cabezas = self.leer(emulador, "wCabezas", 10)
        self.assertEqual(cabezas.count(2), 5)
        self.assertEqual(set(cabezas) - {0}, {2})

    def test_observar_muestra_la_marca_de_la_raiz(self):
        emulador = self.jugar()
        self.observar(emulador, 2)
        self.assertEqual(self.leer(emulador, "wObservadas", 10)[2], 1)
        self.assertEqual(self.leer(emulador, "wNodoLeido"), 1)
        # Placa del hueco 2 (fila 3, columna 11): cuadrado del nodo central.
        self.assertEqual(emulador.memory[celda(3, 11)], TILE_GLIFO + 1)
        self.assertEqual(emulador.memory[celda(13, 11)], TILE_GLIFO + 1)

    def test_el_cuello_se_ilumina_solo_mientras_dura_la_lectura(self):
        emulador = self.jugar()
        observadas = self.vigilar_escrituras(emulador)
        self.poner(emulador, "wCursor", 0)
        self.pulsar(emulador, "b")
        emulador.tick(2, False)
        self.assertEqual(emulador.memory[celda(4, 1):celda(4, 3)],
                         [TILE_CUELLO_LUZ, TILE_CUELLO_LUZ + 1])
        # Las demas cabezas no delatan su raiz.
        self.assertEqual(emulador.memory[celda(4, 9):celda(4, 11)],
                         [TILE_CABEZA + 4, TILE_CABEZA + 5])
        emulador.tick(34, False)
        self.assertEqual(self.leer(emulador, "wBloqueo"), 0)
        self.assertEqual(emulador.memory[celda(4, 1):celda(4, 3)],
                         [TILE_CABEZA + 4, TILE_CABEZA + 5])
        self.assertEqual(emulador.memory[celda(3, 3)], TILE_GLIFO + 1)
        # Encender y apagar el cuello tambien cabe en VBlank.
        activas = [x for x in observadas if x[4]]
        self.assertTrue(any(x[1] == celda(4, 1) for x in activas))
        self.assertEqual([x for x in activas if x[2] < 144 or x[3] != 1], [])

    def test_sellar_sin_leer_el_nodo_hace_crecer_la_raiz_dominante(self):
        emulador = self.jugar()
        self.observar(emulador, 0)
        self.accion(emulador, 11)
        self.assertEqual(self.leer(emulador, "wSellados", 3), [0, 0, 0])
        self.assertEqual(self.leer(emulador, "wCabezas", 10).count(2), 5)

    def test_sellar_un_nodo_leido_limpia_sus_cabezas_y_avanza(self):
        emulador = self.jugar()
        self.observar(emulador, 0)
        self.observar(emulador, 8)
        self.accion(emulador, 11)
        self.assertEqual(self.leer(emulador, "wNivel"), 1)
        self.assertEqual(self.leer(emulador, "wCabezas", 10), NIVEL_2)
        self.assertEqual(emulador.memory[0xC100], 0)

    def test_nodo_equivocado_no_se_sella_aunque_se_haya_leido_otro(self):
        emulador = self.jugar()
        self.observar(emulador, 0)
        self.observar(emulador, 2)
        self.accion(emulador, 10)
        self.assertEqual(self.leer(emulador, "wSellados", 3), [0, 0, 0])
        self.assertEqual(self.leer(emulador, "wCabezas", 10).count(2), 5)

    def test_sellado_repartido_escribe_vram_solo_en_vblank(self):
        emulador = self.jugar()
        # Dos raices: sellar N0 redibuja nodo, cuatro huecos y HUD en dos frames.
        self.poner(emulador, "wCabezas", [1, 1, 1, 1, 0, 2, 2, 0, 0, 0])
        self.poner(emulador, "wObservadas", [1, 1, 0, 0, 0, 0, 0, 0, 0, 0])
        observadas = self.vigilar_escrituras(emulador)
        self.accion(emulador, 10)
        emulador.tick(4, False)
        self.assertEqual(self.leer(emulador, "wSellados", 3), [1, 0, 0])
        self.assertEqual(self.leer(emulador, "wCabezas", 10), [0, 0, 0, 0, 0, 2, 2, 0, 0, 0])
        self.assertEqual(self.leer(emulador, "wPendientes", 15), [0] * 15)
        activas = [x for x in observadas if x[4]]
        self.assertTrue(any(0x9800 <= x[1] < 0x9C00 for x in activas))
        self.assertTrue(any(0xFE00 <= x[1] < 0xFEA0 for x in activas))
        self.assertEqual([x for x in activas if x[2] < 144 or x[3] != 1], [])
        # Nodo 0 sellado en pantalla y cabezas retiradas.
        self.assertEqual(emulador.memory[celda(12, 3)], TILE_SELLO)
        self.assertEqual(emulador.memory[celda(2, 1)], TILE_HUECO)
        self.assertEqual(emulador.memory[celda(2, 13)], TILE_HUECO)
        self.assertEqual(emulador.memory[celda(3, 3)], TILE_PLACA_AGUA)

    def test_el_reloj_hace_brotar_la_raiz_dominante(self):
        emulador = self.jugar()
        self.poner(emulador, "wCabezas", [1, 0, 3, 0, 3, 0, 0, 0, 0, 0])
        self.poner(emulador, "wSegmentos", 1)
        self.poner(emulador, "wTick", 1)
        emulador.tick(2, False)
        cabezas = self.leer(emulador, "wCabezas", 10)
        self.assertEqual(cabezas.count(3), 3)
        self.assertEqual(cabezas.count(1), 1)
        self.assertEqual(self.leer(emulador, "wSegmentos"), 6)

    def test_sin_hueco_para_brotar_la_hidra_desborda(self):
        emulador = self.jugar()
        self.poner(emulador, "wCabezas", [2] * 10)
        self.accion(emulador, 0)
        self.assertEqual(self.leer(emulador, "wEstado"), 2)
        self.assertEqual(emulador.memory[0xC100], 0)
        # Pantalla LOOP y reintento del mismo nivel.
        self.assertEqual(emulador.memory[celda(6, 8):celda(6, 12)],
                         [TILE_L, TILE_O, TILE_O, TILE_P])
        self.pulsar(emulador, "start")
        self.assertEqual(self.leer(emulador, "wEstado"), 1)
        self.assertEqual(self.leer(emulador, "wCabezas", 10), NIVEL_1)

    def test_romper_el_ultimo_nivel_publica_el_handshake(self):
        emulador = self.jugar()
        self.poner(emulador, "wNivel", 2)
        self.poner(emulador, "wCabezas", [0, 3, 0, 0, 3, 0, 0, 0, 0, 0])
        self.poner(emulador, "wObservadas", [0, 1, 0, 0, 1, 0, 0, 0, 0, 0])
        self.accion(emulador, 12)
        self.assertEqual(self.leer(emulador, "wEstado"), 3)
        self.assertEqual(emulador.memory[0xC100], 0xA5)
        self.assertEqual(emulador.memory[celda(8, 8):celda(8, 12)],
                         [TILE_R, TILE_O, TILE_T, TILE_O])

    def test_niveles_2_y_3_son_resolubles_con_las_reglas(self):
        """Resuelve los niveles reales sin tocar WRAM, salvo el cursor."""
        emulador = self.jugar(cgb=False)
        self.observar(emulador, 0)
        self.observar(emulador, 2)
        self.accion(emulador, 11)
        self.assertEqual(self.leer(emulador, "wNivel"), 1)
        # Nivel 2: N0 x3, N2 x2 y una cabeza suelta de N1 que hay que cortar.
        for hueco in (0, 3):
            self.observar(emulador, hueco)
        self.accion(emulador, 10)
        for hueco in (1, 5):
            self.observar(emulador, hueco)
        self.accion(emulador, 12)
        self.accion(emulador, 9)
        brotes = [i for i, v in enumerate(self.leer(emulador, "wCabezas", 10)) if v]
        self.assertEqual(len(brotes), 2)
        for hueco in brotes:
            self.observar(emulador, hueco)
        self.accion(emulador, 11)
        self.assertEqual(self.leer(emulador, "wNivel"), 2)
        # Nivel 3: tres raices con dos o mas cabezas cada una.
        for nodo, huecos in ((11, (1, 5)), (10, (2, 8)), (12, (4, 6))):
            for hueco in huecos:
                self.observar(emulador, hueco)
            if nodo != 12:
                self.accion(emulador, nodo)
        self.accion(emulador, 12)
        self.assertEqual(self.leer(emulador, "wEstado"), 3)
        self.assertEqual(emulador.memory[0xC100], 0xA5)

    def vigilar_escrituras(self, emulador):
        """Instrumenta los LD a memoria del codigo (Inicio..FinCodigo)."""
        largos = {0x01, 0x08, 0x11, 0x21, 0x31, 0xC2, 0xC3, 0xC4,
                  0xCA, 0xCC, 0xCD, 0xD2, 0xD4, 0xDA, 0xDC, 0xEA, 0xFA}
        cortos = {0x06, 0x0E, 0x10, 0x16, 0x18, 0x1E, 0x20, 0x26,
                  0x28, 0x2E, 0x30, 0x36, 0x38, 0x3E, 0xC6, 0xCB,
                  0xCE, 0xD6, 0xDE, 0xE0, 0xE6, 0xE8, 0xEE, 0xF0,
                  0xF6, 0xF8, 0xFE}
        stores_hl = {0x22, 0x32, 0x36, 0x70, 0x71, 0x72, 0x73,
                     0x74, 0x75, 0x77}
        observadas = []

        def escritura(contexto):
            pc, opcode = contexto
            registros = emulador.register_file
            if opcode in stores_hl:
                destino = registros.HL
            elif opcode == 0x02:
                destino = registros.B * 256 + registros.C
            elif opcode == 0x12:
                destino = registros.D * 256 + registros.E
            else:
                destino = self.rom[pc + 1] + self.rom[pc + 2] * 256
            if 0x8000 <= destino < 0xA000 or 0xFE00 <= destino < 0xFEA0:
                observadas.append((pc, destino, emulador.memory[0xFF44],
                                   emulador.memory[0xFF41] & 3,
                                   bool(emulador.memory[0xFF40] & 0x80)))

        pc = self.simbolos["Inicio"]
        while pc < self.simbolos["FinCodigo"]:
            opcode = self.rom[pc]
            if opcode in stores_hl | {0x02, 0x12, 0xEA, 0x08}:
                emulador.hook_register(0, pc, escritura, (pc, opcode))
            pc += 3 if opcode in largos else 2 if opcode in cortos else 1
        self.assertEqual(pc, self.simbolos["FinCodigo"])
        return observadas


if __name__ == "__main__":
    unittest.main(verbosity=2)
