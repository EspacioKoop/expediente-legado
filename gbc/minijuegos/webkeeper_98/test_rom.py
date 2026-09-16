"""Regresiones de WEBKEEPER 98 sobre la ROM compilada con PyBoy 2.6.1."""

from pathlib import Path
import tempfile
import unittest

try:
    from pyboy import PyBoy
except ImportError:  # pragma: no cover - CI instala PyBoy explicitamente
    PyBoy = None


RAIZ = Path(__file__).resolve().parent
ROM = RAIZ / "build/webkeeper_98.gbc"
SIMBOLOS = RAIZ / "build/webkeeper_98.sym"

ESTADO_TITULO = 0
ESTADO_HISTORIA = 1
ESTADO_PARTIDO = 2
ESTADO_DERROTA = 3
ESTADO_VICTORIA = 4


class CabeceraROM(unittest.TestCase):
    def test_rom_dual_con_titulo_propio(self):
        datos = ROM.read_bytes()
        self.assertEqual(len(datos), 32768)
        self.assertEqual(datos[0x134:0x143].rstrip(b"\0"), b"WEBKEEPER98")
        self.assertEqual(datos[0x143], 0x80)


@unittest.skipIf(PyBoy is None, "PyBoy 2.6.1 no instalado")
class PruebasWebkeeper(unittest.TestCase):
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
        ruta = Path(carpeta.name) / "webkeeper.gbc"
        ruta.write_bytes(self.rom)
        emulador = PyBoy(str(ruta), window="null", sound_emulated=False, cgb=cgb)
        self.addCleanup(lambda: emulador.stop(save=False))
        emulador.tick(90, False)
        return emulador

    def leer(self, emulador, nombre):
        return emulador.memory[self.simbolos[nombre]]

    def poner(self, emulador, nombre, valor):
        emulador.memory[self.simbolos[nombre]] = valor

    def pulsar(self, emulador, boton, espera=2):
        emulador.button_press(boton)
        emulador.tick(2, False)
        emulador.button_release(boton)
        emulador.tick(espera, False)

    def entrar_partido(self, emulador):
        self.pulsar(emulador, "a")
        self.assertEqual(self.leer(emulador, "wEstado"), ESTADO_HISTORIA)
        self.pulsar(emulador, "a")
        self.assertEqual(self.leer(emulador, "wEstado"), ESTADO_PARTIDO)

    def resolver_ultimo_como_parada(self, emulador, total, necesarias):
        self.poner(emulador, "wTiro", total - 1)
        self.poner(emulador, "wParadas", necesarias - 1)
        self.poner(emulador, "wPorteroCarril", 1)
        self.poner(emulador, "wPorteroAltura", 0)
        self.poner(emulador, "wObjetivoCarril", 1)
        self.poner(emulador, "wObjetivoAltura", 0)
        self.poner(emulador, "wVentanaParada", 10)
        self.poner(emulador, "wTimerTiro", 0)
        emulador.tick(1, False)

    def resolver_ultimo_como_gol(self, emulador, total):
        self.poner(emulador, "wTiro", total - 1)
        self.poner(emulador, "wParadas", 0)
        self.poner(emulador, "wPorteroCarril", 1)
        self.poner(emulador, "wPorteroAltura", 0)
        self.poner(emulador, "wObjetivoCarril", 2)
        self.poner(emulador, "wObjetivoAltura", 1)
        self.poner(emulador, "wVentanaParada", 0)
        self.poner(emulador, "wVentanaRed", 0)
        self.poner(emulador, "wTimerTiro", 0)
        emulador.tick(1, False)

    def test_portada_no_publica_handshake(self):
        for cgb in (False, True):
            with self.subTest(cgb=cgb):
                emulador = self.arrancar(cgb)
                self.assertEqual(self.leer(emulador, "wEstado"), ESTADO_TITULO)
                self.assertEqual(emulador.memory[0xC100], 0)

    def test_trama_entra_al_debut_antes_del_partido(self):
        emulador = self.arrancar()
        self.entrar_partido(emulador)
        self.assertEqual(self.leer(emulador, "wPartido"), 0)
        self.assertEqual(self.leer(emulador, "wTiro"), 0)
        self.assertEqual(self.leer(emulador, "wParadas"), 0)
        self.assertEqual(emulador.memory[0xC100], 0)

    def test_estirada_exige_carril_y_altura(self):
        emulador = self.arrancar()
        self.entrar_partido(emulador)
        self.poner(emulador, "wObjetivoCarril", 1)
        self.poner(emulador, "wObjetivoAltura", 1)
        self.poner(emulador, "wPorteroCarril", 1)
        self.poner(emulador, "wPorteroAltura", 1)
        self.poner(emulador, "wVentanaParada", 10)
        self.poner(emulador, "wTimerTiro", 0)
        emulador.tick(1, False)
        self.assertEqual(self.leer(emulador, "wParadas"), 1)
        self.assertEqual(self.leer(emulador, "wUltimoFueParada"), 1)

    def test_telarana_cubre_ambas_alturas_del_carril(self):
        emulador = self.arrancar()
        self.entrar_partido(emulador)
        self.poner(emulador, "wObjetivoCarril", 1)
        self.poner(emulador, "wObjetivoAltura", 1)
        self.poner(emulador, "wPorteroCarril", 1)
        self.poner(emulador, "wPorteroAltura", 0)
        self.poner(emulador, "wVentanaRed", 10)
        self.poner(emulador, "wTimerTiro", 0)
        emulador.tick(1, False)
        self.assertEqual(self.leer(emulador, "wParadas"), 1)
        self.assertEqual(self.leer(emulador, "wUltimoFueParada"), 1)

    def test_perder_repite_solo_el_partido_actual(self):
        emulador = self.arrancar()
        self.entrar_partido(emulador)
        self.resolver_ultimo_como_gol(emulador, 6)
        self.assertEqual(self.leer(emulador, "wEstado"), ESTADO_DERROTA)
        self.assertEqual(self.leer(emulador, "wPartido"), 0)
        self.assertEqual(self.leer(emulador, "wDerrotasPartido"), 1)
        self.assertEqual(emulador.memory[0xC100], 0)
        self.pulsar(emulador, "a")
        self.assertEqual(self.leer(emulador, "wEstado"), ESTADO_PARTIDO)
        self.assertEqual(self.leer(emulador, "wPartido"), 0)

    def test_dos_derrotas_activan_ayuda_sin_saltar_partido(self):
        emulador = self.arrancar()
        self.entrar_partido(emulador)
        self.resolver_ultimo_como_gol(emulador, 6)
        self.pulsar(emulador, "a")
        self.resolver_ultimo_como_gol(emulador, 6)
        self.assertEqual(self.leer(emulador, "wEstado"), ESTADO_DERROTA)
        self.assertEqual(self.leer(emulador, "wDerrotasPartido"), 2)
        self.assertEqual(self.leer(emulador, "wAyuda"), 1)
        self.pulsar(emulador, "a")
        self.assertEqual(self.leer(emulador, "wEstado"), ESTADO_PARTIDO)
        self.assertEqual(self.leer(emulador, "wAyuda"), 1)
        self.assertEqual(self.leer(emulador, "wPartido"), 0)

    def test_amago_revela_el_destino_real_con_margen(self):
        emulador = self.arrancar()
        self.poner(emulador, "wPartido", 1)
        self.poner(emulador, "wEstado", ESTADO_HISTORIA)
        self.pulsar(emulador, "a")
        self.assertEqual(self.leer(emulador, "wTiroAmago"), 1)
        # Primer tiro real: izquierda/raso. El amago inicial enseña derecha/alto.
        self.assertEqual(emulador.memory[0xFE05], 120)
        self.assertEqual(emulador.memory[0xFE04], 64)
        emulador.tick(52, False)
        self.assertLessEqual(self.leer(emulador, "wTimerTiro"), 40)
        self.assertEqual(emulador.memory[0xFE05], 48)
        self.assertEqual(emulador.memory[0xFE04], 96)

    def test_ayuda_elimina_el_destino_falso_desde_el_inicio(self):
        emulador = self.arrancar()
        self.poner(emulador, "wPartido", 1)
        self.poner(emulador, "wDerrotasPartido", 2)
        self.poner(emulador, "wEstado", ESTADO_HISTORIA)
        self.pulsar(emulador, "a")
        self.assertEqual(self.leer(emulador, "wAyuda"), 1)
        self.assertEqual(self.leer(emulador, "wTiroAmago"), 1)
        self.assertEqual(emulador.memory[0xFE05], 48)
        self.assertEqual(emulador.memory[0xFE04], 96)

    def test_tres_partidos_publican_handshake_solo_al_final(self):
        emulador = self.arrancar()
        self.entrar_partido(emulador)

        self.resolver_ultimo_como_parada(emulador, 6, 3)
        self.assertEqual(self.leer(emulador, "wEstado"), ESTADO_HISTORIA)
        self.assertEqual(self.leer(emulador, "wPartido"), 1)
        self.assertEqual(emulador.memory[0xC100], 0)

        self.pulsar(emulador, "a")
        self.resolver_ultimo_como_parada(emulador, 8, 4)
        self.assertEqual(self.leer(emulador, "wEstado"), ESTADO_HISTORIA)
        self.assertEqual(self.leer(emulador, "wPartido"), 2)
        self.assertEqual(emulador.memory[0xC100], 0)

        self.pulsar(emulador, "a")
        self.resolver_ultimo_como_parada(emulador, 9, 5)
        self.assertEqual(self.leer(emulador, "wEstado"), ESTADO_VICTORIA)
        self.assertEqual(emulador.memory[0xC100], 0xA5)


if __name__ == "__main__":
    unittest.main()
