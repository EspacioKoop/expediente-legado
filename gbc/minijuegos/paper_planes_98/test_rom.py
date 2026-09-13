"""Regresiones de rutinas de la ROM compilada, ejecutadas con PyBoy 2.6.1.

El arnés llama al código máquina real con LCD apagada para aislar los
contratos de memoria. No sustituye el playtest ni mide el presupuesto VBlank.
"""

from pathlib import Path
import tempfile
import unittest

from pyboy import PyBoy


RAIZ = Path(__file__).resolve().parent
ROM = RAIZ / "build/paper_planes_98.gbc"
SIMBOLOS = RAIZ / "build/paper_planes_98.sym"


class PruebasROM(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rom = ROM.read_bytes()
        cls.simbolos = {}
        for linea in SIMBOLOS.read_text().splitlines():
            if linea and not linea.startswith(";"):
                direccion, nombre = linea.split()
                cls.simbolos[nombre] = int(direccion.split(":")[1], 16)

    def ejecutar(self, rutina, preparar):
        """Arranca una copia temporal y llama a una rutina una sola vez."""
        direccion = self.simbolos[rutina]
        programa = bytes([
            0xF3,                         # di
            0x31, 0xFF, 0xDF,             # ld sp, $DFFF
            0xAF, 0xE0, 0x40,             # xor a / ldh [rLCDC], a
            0xCD, direccion & 255, direccion >> 8,
            0x3E, 0xA5, 0xEA, 0xFF, 0xCF, # marca de retorno
            0x18, 0xFE,                   # espera sin repetir la rutina
        ])
        # El arnés ocupa únicamente relleno de la ROM, nunca código del juego.
        self.assertEqual(self.rom[0x3F00:0x3F00 + len(programa)],
                         bytes(len(programa)))
        rom = bytearray(self.rom)
        rom[0x100:0x103] = bytes([0xC3, 0x00, 0x3F])
        rom[0x3F00:0x3F00 + len(programa)] = programa
        with tempfile.TemporaryDirectory() as carpeta:
            ruta = Path(carpeta) / "prueba.gbc"
            ruta.write_bytes(rom)
            emulador = PyBoy(str(ruta), window="null", sound_emulated=False)
            try:
                def al_entrar(_):
                    emulador.memory[0xCFFF] = 0
                    preparar(emulador)

                emulador.hook_register(0, 0x3F00, al_entrar, None)
                emulador.tick(120, False)
                self.assertEqual(emulador.memory[0xCFFF], 0xA5,
                                 "La rutina no devolvió el control")
                return bytes(emulador.memory[0:0x10000])
            finally:
                emulador.stop(save=False)

    def test_limpia_las_1024_celdas_sin_salirse(self):
        def preparar(emulador):
            emulador.memory[0x97FF:0x9C01] = [0x55] * 1026

        memoria = self.ejecutar("LimpiarBG", preparar)
        self.assertEqual(memoria[0x9800:0x9C00], bytes(1024))
        self.assertEqual(memoria[0x97FF], 0x55)
        self.assertEqual(memoria[0x9C00], 0x55)

    def test_los_cuatro_hitos_se_escriben_en_oam(self):
        for tipo, cantidad in enumerate((8, 22, 18, 17)):
            with self.subTest(hito=tipo):
                def preparar(emulador):
                    for nombre, valor in {"wTipoHito": tipo, "wHitoX": 120,
                                          "wAvionX": 40, "wAvionY": 80,
                                          "wInv": 0}.items():
                        emulador.memory[self.simbolos[nombre]] = valor

                memoria = self.ejecutar("ActualizarOAM", preparar)
                sprites = memoria[0xFE00:0xFEA0]
                self.assertEqual(sprites[:8], bytes([80, 40, 1, 0, 80, 48, 2, 0]))
                self.assertTrue(all(sprites[i * 4] for i in range(2, cantidad + 2)))
                self.assertEqual(sprites[(cantidad + 2) * 4:],
                                 bytes(160 - (cantidad + 2) * 4))
                self.assertTrue(all(0 < sprites[i * 4 + 2] <= 9
                                    for i in range(2, cantidad + 2)))

    def test_hud_actualiza_digitos_sin_restos(self):
        def tile(caracter):
            if caracter == " ":
                return 0
            if caracter.isdigit():
                return 13 + int(caracter)
            if caracter == "/":
                return 51
            return 23 + ord(caracter) - ord("A")

        for vidas, hito, puntos in ((3, 0, 0), (2, 1, 1), (1, 2, 3), (0, 3, 4)):
            with self.subTest(vidas=vidas, hito=hito, puntos=puntos):
                def preparar(emulador):
                    emulador.memory[0x9800:0x9840] = [0] * 64
                    for nombre, valor in {"wVidas": vidas, "wTipoHito": hito,
                                          "wScore": puntos}.items():
                        emulador.memory[self.simbolos[nombre]] = valor

                memoria = self.ejecutar("DibujarHUD", preparar)
                for fila, texto in enumerate((f"NYC 98  FOLD {vidas}",
                                              f"GATE {hito + 1}/4 SCORE {puntos:02}")):
                    esperado = bytes(map(tile, texto.ljust(20)))
                    inicio = 0x9800 + fila * 32
                    self.assertEqual(memoria[inicio:inicio + 20], esperado)


if __name__ == "__main__":
    unittest.main(verbosity=2)
