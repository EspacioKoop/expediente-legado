"""Regresiones de memoria y VBlank de la ROM real con PyBoy 2.6.1."""

from pathlib import Path
import tempfile
import unittest

from pyboy import PyBoy


RAIZ = Path(__file__).resolve().parent


class PruebasROM(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rom = (RAIZ / "build/croc_riders_98.gbc").read_bytes()
        cls.simbolos = {}
        for linea in (RAIZ / "build/croc_riders_98.sym").read_text().splitlines():
            if linea and not linea.startswith(";"):
                direccion, nombre = linea.split()
                cls.simbolos[nombre] = int(direccion.split(":")[1], 16)

    def arrancar(self, cgb):
        carpeta = tempfile.TemporaryDirectory()
        self.addCleanup(carpeta.cleanup)
        ruta = Path(carpeta.name) / "prueba.gbc"
        ruta.write_bytes(self.rom)
        emulador = PyBoy(str(ruta), window="null", sound_emulated=False, cgb=cgb)
        self.addCleanup(lambda: emulador.stop(save=False))
        emulador.tick(120, False)
        return emulador

    def test_portada_limpia_en_dmg_y_cgb(self):
        for cgb in (False, True):
            with self.subTest(cgb=cgb):
                emulador = self.arrancar(cgb)
                # Todas las celdas salvo letras, piramides y flecha deben ser 0.
                ocupadas = {3 * 32 + x for x in range(7, 11)}
                ocupadas |= {5 * 32 + x for x in range(5, 11)}
                ocupadas |= {7 * 32 + 8, 7 * 32 + 9, 13 * 32 + 9}
                ocupadas |= {10 * 32 + x for x in range(7, 10)}
                fondo = emulador.memory[0x9800:0x9C00]
                self.assertTrue(all(v == 0 for i, v in enumerate(fondo)
                                    if i not in ocupadas))
                self.assertTrue(all(0 < fondo[i] < 52 for i in ocupadas))

    def vigilar_escrituras(self, emulador):
        """Instrumenta los LD a memoria sin sustituir la logica de la ROM.

        La seccion Juego contiene solo instrucciones; se recorre hasta Tiles.
        Las longitudes LR35902 permiten encontrar los stores, incluidos [HL]
        y direcciones absolutas, sin confundir sus operandos con instrucciones.
        """
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
        while pc < self.simbolos["Tiles"]:
            opcode = self.rom[pc]
            if opcode in stores_hl | {0x02, 0x12, 0xEA, 0x08}:
                emulador.hook_register(0, pc, escritura, (pc, opcode))
            pc += 3 if opcode in largos else 2 if opcode in cortos else 1
        self.assertEqual(pc, self.simbolos["Tiles"])
        return observadas

    def test_checkpoints_caben_en_vblank_y_conservan_hud(self):
        for cgb in (False, True):
            with self.subTest(cgb=cgb):
                emulador = self.arrancar(cgb)
                emulador.button_press("start")
                emulador.tick(1, False)
                emulador.button_release("start")
                emulador.tick(3, False)
                observadas = self.vigilar_escrituras(emulador)
                for distancia, etapa in ((24, 1), (46, 2), (68, 3)):
                    for nombre, valor in {"wDistance": distancia - 1,
                                          "wDistanceTick": 7, "wScore": 99,
                                          "wTurbo": 90, "wInv": 200}.items():
                        emulador.memory[self.simbolos[nombre]] = valor
                    observadas.clear()
                    # El checkpoint real debe terminar decorado y HUD sin
                    # bloquear el movimiento, incluso con nitro y score 99.
                    emulador.tick(7, False)
                    self.assertEqual(emulador.memory[self.simbolos["wStage"]], etapa)
                    self.assertEqual(emulador.memory[self.simbolos["wDecorDirty"]], 0)
                    self.assertEqual(emulador.memory[self.simbolos["wHudDirty"]], 0)
                    activas = [x for x in observadas if x[4]]
                    self.assertTrue(any(0xFE00 <= x[1] < 0xFEA0 for x in activas))
                    self.assertTrue(any(0x9800 <= x[1] < 0x9C00 for x in activas))
                    self.assertEqual([x for x in activas if x[2] < 144 or x[3] != 1], [])
                    self.assertEqual(emulador.memory[0x9806:0x9808], [21, 21])
                    self.assertEqual(emulador.memory[0x9801:0x9803],
                                     [12 + distancia // 10, 12 + distancia % 10])
                    esperado = [0] * 96
                    if etapa == 1:
                        for columna in (2, 13):
                            esperado[32 + columna:35 + columna] = [4, 5, 6]
                        esperado[40:43] = [7, 8, 8]
                    elif etapa == 2:
                        esperado[64:84] = [9] * 20
                        esperado[4] = esperado[36] = 10
                    else:
                        esperado[4] = esperado[36] = esperado[68] = 10
                        esperado[47] = 11
                    for fila in range(3):
                        inicio = 0x9820 + fila * 32
                        self.assertEqual(emulador.memory[inicio:inicio + 20],
                                         esperado[fila * 32:fila * 32 + 20])

    def iniciar_carrera(self, cgb=True):
        emulador = self.arrancar(cgb)
        self.pulsar(emulador, "start")
        emulador.tick(3, False)
        return emulador

    def pulsar(self, emulador, boton):
        emulador.button_press(boton)
        emulador.tick(2, False)
        emulador.button_release(boton)
        emulador.tick(1, False)

    def poner(self, emulador, **valores):
        for nombre, valor in valores.items():
            emulador.memory[self.simbolos[nombre]] = valor

    def leer(self, emulador, nombre):
        return emulador.memory[self.simbolos[nombre]]

    def test_rival_avisa_antes_de_cambiar_hacia_el_jugador(self):
        cambios = quietos = 0
        for semilla in range(8):
            with self.subTest(semilla=semilla):
                emulador = self.iniciar_carrera()
                # Jugador a la derecha, rival 1 a la izquierda; nadie choca.
                self.poner(emulador, wInv=255, wPlayerLane=2, wR1Lane=0,
                           wR1Y=64, wR1Dir=0, wR2Lane=2, wR2Y=8,
                           wHazLane=2, wHazY=32, wFrame=semilla)
                for _ in range(40):
                    if self.leer(emulador, "wR1Y") >= 72:
                        break
                    emulador.tick(1, False)
                direccion = self.leer(emulador, "wR1Dir")
                if direccion == 0:
                    quietos += 1
                    emulador.tick(40, False)
                    self.assertEqual(self.leer(emulador, "wR1Lane"), 0)
                    continue
                cambios += 1
                self.assertEqual(direccion, 1)
                # Aviso: vaiven de 2 px hacia el destino, sin sprites extra.
                xs = set()
                while self.leer(emulador, "wR1Dir"):
                    self.assertLess(self.leer(emulador, "wR1Y"), 88)
                    self.assertEqual(self.leer(emulador, "wR1Lane"), 0)
                    emulador.tick(1, False)
                    if self.leer(emulador, "wR1Dir"):
                        xs.add(emulador.memory[0xFE09])
                self.assertEqual(xs, {48, 50})
                self.assertEqual(self.leer(emulador, "wR1Lane"), 1)
                # El cambio llega antes de la zona de choque.
                self.assertLessEqual(self.leer(emulador, "wR1Y"), 88)
        self.assertGreater(cambios, 0)
        self.assertGreater(quietos, 0)

    def test_rebufo_lleno_prolonga_nitro(self):
        emulador = self.iniciar_carrera()
        self.poner(emulador, wInv=255, wPlayerLane=1, wR1Lane=1, wR1Y=56,
                   wR2Lane=0, wR2Y=8, wHazLane=0, wHazY=32, wDraft=0)
        observadas = self.vigilar_escrituras(emulador)
        emulador.tick(72, False)
        self.assertEqual(self.leer(emulador, "wDraft"), 32)
        # El medidor se redibuja por segmentos y siempre dentro de VBlank.
        activas = [x for x in observadas if x[4]]
        self.assertTrue(any(0x9810 <= x[1] < 0x9814 for x in activas))
        self.assertEqual([x for x in activas if x[2] < 144 or x[3] != 1], [])
        self.assertEqual(self.leer(emulador, "wDraftDirty"), 0)
        self.assertEqual(emulador.memory[0x9810:0x9814], [53] * 4)

        self.poner(emulador, wPlayerLane=2)
        self.pulsar(emulador, "a")
        self.assertGreater(self.leer(emulador, "wTurbo"), 140)
        self.assertEqual(self.leer(emulador, "wDraft"), 0)
        self.assertEqual(self.leer(emulador, "wNitro"), 2)
        emulador.tick(4, False)
        self.assertEqual(emulador.memory[0x9810:0x9814], [52] * 4)

        # Sin rebufo lleno, el nitro conserva su duracion original.
        self.poner(emulador, wTurbo=0, wDraft=31)
        self.pulsar(emulador, "a")
        self.assertLessEqual(self.leer(emulador, "wTurbo"), 90)
        self.assertEqual(self.leer(emulador, "wDraft"), 31)
        self.assertEqual(self.leer(emulador, "wNitro"), 1)

    def test_golpe_rompe_rebufo(self):
        emulador = self.iniciar_carrera()
        self.poner(emulador, wInv=0, wPlayerLane=1, wR1Lane=1, wR1Y=118,
                   wR2Lane=0, wR2Y=8, wHazLane=0, wHazY=32, wDraft=32)
        emulador.tick(2, False)
        self.assertEqual(self.leer(emulador, "wLives"), 2)
        self.assertEqual(self.leer(emulador, "wDraft"), 0)

    def test_adelantar_en_turbo_puntua_doble(self):
        emulador = self.iniciar_carrera()
        self.poner(emulador, wInv=255, wPlayerLane=2, wR1Lane=0, wR1Y=159,
                   wR2Lane=0, wR2Y=100, wHazLane=0, wHazY=32,
                   wScore=10, wTurbo=60)
        emulador.tick(1, False)
        self.assertEqual(self.leer(emulador, "wScore"), 12)

        self.poner(emulador, wTurbo=0, wR1Y=159, wR2Y=100)
        emulador.tick(2, False)
        self.assertEqual(self.leer(emulador, "wScore"), 13)

        self.poner(emulador, wTurbo=60, wR1Y=159, wR2Y=100, wScore=98)
        emulador.tick(1, False)
        self.assertEqual(self.leer(emulador, "wScore"), 99)


if __name__ == "__main__":
    unittest.main(verbosity=2)
