"""Pantallas de título GBC convertidas de las láminas aprobadas (#808).

Comprueba que los datos generados por `scripts/gbc_imagen_a_tiles.py` caben en
el hardware y que cada ROM los carga solo en Game Boy Color y devuelve sus
propios tiles al salir. Lo que se ve de verdad lo comprueba el smoke de pantalla
con el núcleo del juego (`godot/pruebas/roms_pantalla_smoke.gd`).
"""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
ROMS = {
    "ryu_flow_98": ROOT / "gbc" / "minijuegos" / "ryu_flow_98",
    "webkeeper_98": ROOT / "gbc" / "minijuegos" / "webkeeper_98",
    "caza_pixeles_98": ROOT / "gbc" / "minijuegos" / "caza_pixeles_98",
}
ARIADNE = ROOT / "docs" / "visuales" / "ariadne"
COMUN = ROOT / "gbc" / "minijuegos" / "comun" / "pantalla_cgb.asm"


def _valores(ruta: Path, directiva: str) -> list[int]:
    valores = []
    for linea in ruta.read_text(encoding="utf-8").splitlines():
        linea = linea.split(";", 1)[0].strip()
        if linea.startswith(directiva + " "):
            valores += [int(v.strip().lstrip("$"), 16) for v in linea[3:].split(",")]
    return valores


def _prefijos():
    for rom, carpeta in ROMS.items():
        yield rom, carpeta / "assets" / "titulo", carpeta / "referencia"
    yield "ariadna_labertinto_98", ARIADNE / "titulo", ARIADNE


class TitulosCGBTest(unittest.TestCase):
    def test_los_datos_caben_en_el_hardware(self):
        for nombre, prefijo, referencia in _prefijos():
            with self.subTest(rom=nombre):
                tiles0 = _valores(Path(f"{prefijo}_tiles0.inc"), "db")
                tiles1 = _valores(Path(f"{prefijo}_tiles1.inc"), "db")
                self.assertEqual(len(tiles0) % 16, 0)
                self.assertEqual(len(tiles1) % 16, 0)
                self.assertLessEqual(len(tiles0) // 16, 256)
                self.assertLessEqual(len(tiles1) // 16, 256)
                tilemap = _valores(Path(f"{prefijo}_tilemap.inc"), "db")
                attrmap = _valores(Path(f"{prefijo}_attrmap.inc"), "db")
                self.assertEqual(len(tilemap), 20 * 18)
                self.assertEqual(len(attrmap), 20 * 18)
                for tile, attr in zip(tilemap, attrmap):
                    total = len(tiles1 if (attr >> 3) & 1 else tiles0) // 16
                    self.assertLess(tile, total)
                    self.assertEqual(attr & 0b10010000, 0, "sin prioridad ni bits reservados")
                paletas = _valores(Path(f"{prefijo}_paletas.inc"), "dw")
                self.assertEqual(len(paletas), 8 * 4)
                self.assertTrue(all(v <= 0x7FFF for v in paletas))
                self.assertTrue(Path(f"{prefijo}_previa.png").exists())
                self.assertTrue((referencia / "PROCEDENCIA.md").exists())
                self.assertTrue((referencia / "lamina.png").exists())

    def test_las_roms_cargan_el_titulo_solo_en_gbc_y_lo_descargan(self):
        comun = COMUN.read_text(encoding="utf-8")
        self.assertIn("EsCGB:", comun)
        self.assertIn("ldh a, [rVBK]\n    cp $FE", comun)
        for rom, carpeta in ROMS.items():
            with self.subTest(rom=rom):
                fuente = (carpeta / "main.asm").read_text(encoding="utf-8")
                self.assertIn('INCLUDE "../comun/pantalla_cgb.asm"', fuente)
                self.assertIn('PANTALLA_CGB TituloCGB, "assets/titulo"', fuente)
                self.assertRegex(fuente, r"call EsCGB\n    jr nz, \.texto\n    ld hl, TituloCGB\n    call CargarPantallaCGB")
                limpiar = fuente.split("LimpiarFondo:", 1)[1].split("\n.loop:", 1)[0]
                for paso in ("call DescargarPantallaCGB", "call CargarTiles", "call ConfigurarPaletas"):
                    self.assertIn(paso, limpiar)

    def test_el_catalogo_usa_los_nombres_de_las_laminas(self):
        catalogo = (ROOT / "godot" / "datos" / "roms_propias.json").read_text(encoding="utf-8")
        for titulo in ("Pixel Exodus", "River of the Dragon", "Kwaku, el guardameta", "Ariadne, el hilo del laberinto"):
            self.assertIn(f'"titulo": "{titulo}"', catalogo)


if __name__ == "__main__":
    unittest.main()
