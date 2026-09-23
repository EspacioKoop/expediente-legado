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

    def test_cabecera_sigue_siendo_dual_mode(self):
        self.assertEqual(self.rom[0x134:0x141], b"PAPERPLANES98")
        self.assertEqual(self.rom[0x143], 0x80)

    def test_limpia_las_1024_celdas_sin_salirse(self):
        def preparar(emulador):
            emulador.memory[0x97FF:0x9C01] = [0x55] * 1026

        memoria = self.ejecutar("LimpiarBG", preparar)
        self.assertEqual(memoria[0x9800:0x9C00], bytes(1024))
        self.assertEqual(memoria[0x97FF], 0x55)
        self.assertEqual(memoria[0x9C00], 0x55)

    def test_fondo_respeta_stride_y_anchura_visible(self):
        def preparar(emulador):
            emulador.memory[0x9800:0x9C00] = [0x55] * 1024

        memoria = self.ejecutar("DibujarFondoBase", preparar)
        self.assertEqual(memoria[0x9800 + 5 * 32 + 2], 12)
        self.assertEqual(memoria[0x9800 + 8 * 32 + 15], 12)
        self.assertEqual(memoria[0x9800 + 11 * 32 + 7], 12)
        self.assertEqual(
            memoria[0x9800 + 15 * 32:0x9800 + 15 * 32 + 20],
            bytes([10]) * 20,
        )
        for fila in (16, 17):
            inicio = 0x9800 + fila * 32
            self.assertEqual(memoria[inicio:inicio + 20], bytes([11]) * 20)
            self.assertEqual(memoria[inicio + 20:inicio + 32], bytes([0x55]) * 12)

    def test_fondo_de_juego_anade_base_urbana_sin_invadir_padding(self):
        def preparar(emulador):
            emulador.memory[0x9800:0x9C00] = [0] * 1024

        memoria = self.ejecutar("DibujarFondoJuego", preparar)
        inicio = 0x9800 + 14 * 32
        self.assertEqual(memoria[inicio:inicio + 20], bytes([3]) * 20)
        self.assertEqual(memoria[inicio + 20:inicio + 32], bytes(12))

    def test_avion_tiene_silueta_16x8_de_alto_contraste(self):
        inicio = self.simbolos["Tiles"] + 16
        avion = self.rom[inicio:inicio + 32]
        esperado = bytes([
            0x01, 0x01, 0x03, 0x03, 0x0F, 0x0F, 0xFF, 0xFF,
            0x0F, 0x0F, 0x03, 0x03, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x80, 0x80, 0xC0, 0xC0, 0xFF, 0xFF,
            0xFE, 0xFE, 0xFC, 0xFC, 0xF8, 0xF8, 0x38, 0x38,
        ])
        self.assertEqual(avion, esperado)

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

    def test_viento_alterna_y_b_estabiliza(self):
        casos = (
            (0, 8, 0, 79),  # Liberty: racha suave hacia arriba.
            (1, 8, 0, 81),  # WTC: racha más frecuente hacia abajo.
            (2, 8, 0, 79),
            (3, 8, 0, 81),
            (1, 8, 2, 80),  # B anula la racha y mantiene la altura.
            (1, 9, 0, 80),  # Fuera del pulso no hay desplazamiento.
        )
        for tipo, frame, keys, esperado in casos:
            with self.subTest(hito=tipo, frame=frame, keys=keys):
                def preparar(emulador):
                    for nombre, valor in {"wTipoHito": tipo, "wFrame": frame,
                                          "wKeys": keys, "wAvionY": 80}.items():
                        emulador.memory[self.simbolos[nombre]] = valor

                memoria = self.ejecutar("AplicarViento", preparar)
                self.assertEqual(memoria[self.simbolos["wAvionY"]], esperado)

    def test_paso_perfecto_dobla_puntos_y_cuenta_precision(self):
        precisos = (64, 52, 88, 54)
        normales = (48, 42, 74, 42)
        for tipo, (y_precisa, y_normal) in enumerate(zip(precisos, normales)):
            with self.subTest(hito=tipo, clase="perfecto"):
                def preparar(emulador):
                    valores = {
                        "wTipoHito": tipo, "wHitoX": 40, "wAvionX": 40,
                        "wAvionY": y_precisa, "wGateChecked": 0,
                        "wLandCrashed": 0, "wScore": 0, "wPerfectos": 0,
                        "wVidas": 3,
                    }
                    for nombre, valor in valores.items():
                        emulador.memory[self.simbolos[nombre]] = valor

                memoria = self.ejecutar("ComprobarPaso", preparar)
                self.assertEqual(memoria[self.simbolos["wScore"]], 2)
                self.assertEqual(memoria[self.simbolos["wPerfectos"]], 1)
                self.assertEqual(memoria[self.simbolos["wGateChecked"]], 1)

            with self.subTest(hito=tipo, clase="normal"):
                def preparar(emulador):
                    valores = {
                        "wTipoHito": tipo, "wHitoX": 40, "wAvionX": 40,
                        "wAvionY": y_normal, "wGateChecked": 0,
                        "wLandCrashed": 0, "wScore": 0, "wPerfectos": 0,
                        "wVidas": 3,
                    }
                    for nombre, valor in valores.items():
                        emulador.memory[self.simbolos[nombre]] = valor

                memoria = self.ejecutar("ComprobarPaso", preparar)
                self.assertEqual(memoria[self.simbolos["wScore"]], 1)
                self.assertEqual(memoria[self.simbolos["wPerfectos"]], 0)

    def test_hud_cabe_en_una_fila_y_deja_la_segunda_libre(self):
        def tile(caracter):
            if caracter == " ":
                return 0
            if caracter.isdigit():
                return 13 + int(caracter)
            if caracter == "/":
                return 51
            return 23 + ord(caracter) - ord("A")

        casos = (
            (3, 0, 0, 0, "UP"),
            (2, 1, 2, 1, "DN"),
            (1, 2, 5, 2, "UP"),
            (0, 3, 8, 4, "DN"),
        )
        for vidas, hito, puntos, perfectos, viento in casos:
            with self.subTest(vidas=vidas, hito=hito, puntos=puntos):
                def preparar(emulador):
                    emulador.memory[0x9800:0x9840] = [0] * 64
                    valores = {"wVidas": vidas, "wTipoHito": hito,
                               "wScore": puntos, "wPerfectos": perfectos}
                    for nombre, valor in valores.items():
                        emulador.memory[self.simbolos[nombre]] = valor

                memoria = self.ejecutar("DibujarHUD", preparar)
                texto = f"F{vidas} W{viento} G{hito + 1}/4 S{puntos:02} P{perfectos}"
                esperado = bytes(map(tile, texto.ljust(20)))
                self.assertEqual(memoria[0x9800:0x9800 + 20], esperado)
                self.assertEqual(memoria[0x9820:0x9820 + 20], bytes(20))


    def test_cambio_de_hito_no_reintroduce_rotulo_en_tercera_fila(self):
        def preparar(emulador):
            emulador.memory[0x9800:0x9860] = [0] * 96
            valores = {
                "wTipoHito": 0,
                "wVidas": 3,
                "wScore": 0,
                "wPerfectos": 0,
                "wGateChecked": 1,
                "wLandCrashed": 1,
            }
            for nombre, valor in valores.items():
                emulador.memory[self.simbolos[nombre]] = valor

        memoria = self.ejecutar("SiguienteHito", preparar)
        self.assertEqual(memoria[self.simbolos["wTipoHito"]], 1)
        self.assertNotEqual(memoria[0x9800:0x9800 + 20], bytes(20))
        self.assertEqual(memoria[0x9820:0x9820 + 20], bytes(20))
        self.assertEqual(memoria[0x9840:0x9840 + 20], bytes(20))


if __name__ == "__main__":
    unittest.main(verbosity=2)
