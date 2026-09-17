"""Todas las ROMs propias son cartuchos MBC5 con RAM y batería (#808).

El estándar vive en `gbc/minijuegos/comun/cartucho.mk` (cabecera con rgbfix) y
`gbc/minijuegos/comun/cartucho.asm` (registros del MBC5 y cambio de banco). Así
cualquier ROM puede crecer más allá de 32 KiB y guardar récords en su `.sav`.
"""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
MINIJUEGOS = ROOT / "gbc" / "minijuegos"
COMUN = MINIJUEGOS / "comun"


def _roms():
    for makefile in sorted(MINIJUEGOS.glob("*/Makefile")):
        carpeta = makefile.parent
        fuentes = [carpeta / nombre for nombre in ("main.asm", "game.asm") if (carpeta / nombre).exists()]
        yield carpeta.name, makefile, fuentes[0]


class CartuchosMBC5Test(unittest.TestCase):
    def test_hay_roms_propias(self):
        self.assertGreaterEqual(len(list(_roms())), 7)

    def test_la_cabecera_estandar_es_mbc5_con_ram_y_bateria(self):
        texto = (COMUN / "cartucho.mk").read_text(encoding="utf-8")
        self.assertIn("RGBFIX_CARTUCHO := -m 0x1B -r 0x02 -p 255 -v", texto)

    def test_cada_makefile_usa_el_cartucho_estandar(self):
        for rom, makefile, _fuente in _roms():
            with self.subTest(rom=rom):
                texto = makefile.read_text(encoding="utf-8")
                self.assertIn("include ../comun/cartucho.mk", texto)
                lineas = [linea.strip() for linea in texto.splitlines() if linea.strip().startswith("rgbfix")]
                self.assertEqual(lineas, ["rgbfix $(RGBFIX_CARTUCHO) $@"])

    def test_cada_rom_inicia_el_cartucho_y_carga_pantallas_por_banco(self):
        for rom, _makefile, fuente in _roms():
            with self.subTest(rom=rom):
                texto = fuente.read_text(encoding="utf-8")
                self.assertIn('INCLUDE "../comun/cartucho.asm"', texto)
                self.assertIn("Inicio:\n    di\n    ld sp, $DFFF\n    call IniciarCartucho\n", texto)
                # Las pantallas pueden caer en cualquier banco: nunca se cargan sin mapearlo.
                self.assertNotRegex(texto, r"call CargarPantallaCGB\b")

    def test_las_roms_compiladas_llevan_la_cabecera(self):
        compiladas = [(rom, MINIJUEGOS / rom / "build" / f"{rom}.gbc") for rom, _m, _f in _roms()]
        compiladas = [(rom, ruta) for rom, ruta in compiladas if ruta.exists()]
        if not compiladas:
            self.skipTest("ninguna ROM compilada")
        for rom, ruta in compiladas:
            with self.subTest(rom=rom):
                datos = ruta.read_bytes()
                self.assertEqual(datos[0x147], 0x1B)
                self.assertEqual(datos[0x149], 0x02)
                self.assertEqual(len(datos), 32768 << datos[0x148])


if __name__ == "__main__":
    unittest.main()
