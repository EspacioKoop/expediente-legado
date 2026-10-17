import tempfile
import unittest
from pathlib import Path

from gbc.minijuegos.aquiles_98 import generar_arte_v1 as art


class TestPatronesBg(unittest.TestCase):
    """Pruebas para patrones_bg()."""

    def test_patrones_bg_llaves_esperadas(self):
        patrones = art.patrones_bg()
        llaves_esperadas = {
            "marmol_a",
            "marmol_b",
            "columna",
            "relieve",
            "estandarte",
            "suelo",
            "plataforma",
            "estatua",
        }
        self.assertEqual(set(patrones.keys()), llaves_esperadas)

    def test_patrones_bg_dimensiones_y_limite_colores_gbc(self):
        patrones = art.patrones_bg()
        for nombre, grid in patrones.items():
            with self.subTest(patron=nombre):
                self.assertEqual(len(grid), 8, f"{nombre} debe tener 8 filas")
                for y, fila in enumerate(grid):
                    self.assertEqual(len(fila), 8, f"{nombre} fila {y} debe tener 8 columnas")
                    for x, px in enumerate(fila):
                        self.assertIn(
                            px,
                            (0, 1, 2, 3),
                            f"{nombre} ({x},{y}) px={px} fuera de limite GBC 2bpp [0, 3]",
                        )

    def test_patrones_bg_determinismo(self):
        call1 = art.patrones_bg()
        call2 = art.patrones_bg()
        self.assertEqual(call1, call2)


class TestIconosHud(unittest.TestCase):
    """Pruebas para iconos_hud()."""

    def test_iconos_hud_llaves_esperadas(self):
        iconos = art.iconos_hud()
        llaves_esperadas = {"observar", "reflejo", "talon"}
        self.assertEqual(set(iconos.keys()), llaves_esperadas)

    def test_iconos_hud_dimensiones_y_limite_colores_gbc(self):
        iconos = art.iconos_hud()
        for nombre, grid in iconos.items():
            with self.subTest(icono=nombre):
                self.assertEqual(len(grid), 8, f"{nombre} debe tener 8 filas")
                for y, fila in enumerate(grid):
                    self.assertEqual(len(fila), 8, f"{nombre} fila {y} debe tener 8 columnas")
                    for x, px in enumerate(fila):
                        self.assertIn(
                            px,
                            (0, 1, 2, 3),
                            f"{nombre} ({x},{y}) px={px} fuera de limite GBC 2bpp [0, 3]",
                        )

    def test_iconos_hud_determinismo(self):
        call1 = art.iconos_hud()
        call2 = art.iconos_hud()
        self.assertEqual(call1, call2)


class TestConstruirPack(unittest.TestCase):
    """Pruebas para construir_pack()."""

    def test_construir_pack_estructura_y_presupuesto(self):
        pool, mapas = art.construir_pack()
        self.assertIsInstance(pool, list)
        self.assertIsInstance(mapas, dict)
        estados_esperados = {"idle", "advance", "attack", "block", "vulnerable", "defeat"}
        self.assertEqual(set(mapas.keys()), estados_esperados)
        # Presupuesto max de OBJ tiles en GBC manifest
        self.assertLessEqual(len(pool), 64)

    def test_construir_pack_tiles_formato_8x8_y_colores(self):
        pool, _ = art.construir_pack()
        for idx, tile in enumerate(pool):
            with self.subTest(tile_index=idx):
                self.assertEqual(len(tile), 8)
                for y, fila in enumerate(tile):
                    self.assertEqual(len(fila), 8)
                    for x, px in enumerate(fila):
                        self.assertIn(px, (0, 1, 2, 3))

    def test_construir_pack_mapas_indices_validos(self):
        pool, mapas = art.construir_pack()
        for estado, frames in mapas.items():
            self.assertEqual(len(frames), 2, f"{estado} debe tener 2 frames")
            for frame_idx, mapa in enumerate(frames):
                with self.subTest(estado=estado, frame=frame_idx):
                    self.assertEqual(len(mapa), 12, "Cada frame_px 24x32 debe constar de 12 tiles 8x8")
                    for tile_idx in mapa:
                        self.assertGreaterEqual(tile_idx, 0)
                        self.assertLess(tile_idx, len(pool))

    def test_construir_pack_determinismo(self):
        pool1, mapas1 = art.construir_pack()
        pool2, mapas2 = art.construir_pack()
        self.assertEqual(pool1, pool2)
        self.assertEqual(mapas1, mapas2)


class TestRgbdsTiles(unittest.TestCase):
    """Pruebas para rgbds_tiles()."""

    def test_rgbds_tiles_retorno_y_etiquetas(self):
        salida = art.rgbds_tiles()
        self.assertIsInstance(salida, str)
        self.assertTrue(salida.endswith("\n"))
        self.assertIn("MyrmidonObjTiles::", salida)
        self.assertIn("MyrmidonBgTiles::", salida)
        self.assertIn("MyrmidonHudBase::", salida)
        self.assertIn("MyrmidonHudRevealed::", salida)
        self.assertIn("db $", salida)

    def test_rgbds_tiles_determinismo(self):
        call1 = art.rgbds_tiles()
        call2 = art.rgbds_tiles()
        self.assertEqual(call1, call2)


class TestRgbdsPaletas(unittest.TestCase):
    """Pruebas para rgbds_paletas()."""

    def test_rgbds_paletas_retorno_y_formato_bgr555(self):
        salida = art.rgbds_paletas()
        self.assertIsInstance(salida, str)
        self.assertTrue(salida.endswith("\n"))
        self.assertIn("MyrmidonPal_BG_MARMOL::", salida)
        self.assertIn("MyrmidonPal_OBJ_AQUILES::", salida)
        self.assertIn("dw $", salida)

    def test_rgbds_paletas_determinismo(self):
        call1 = art.rgbds_paletas()
        call2 = art.rgbds_paletas()
        self.assertEqual(call1, call2)


class TestSvgPreview(unittest.TestCase):
    """Pruebas para svg_preview(estado, revelar)."""

    def test_svg_preview_dimensiones_y_etiquetas(self):
        svg_norm = art.svg_preview("idle", False)
        svg_vuln = art.svg_preview("vulnerable", True)
        self.assertTrue(svg_norm.startswith('<svg xmlns="http://www.w3.org/2000/svg"'))
        self.assertIn('width="160"', svg_norm)
        self.assertIn('height="144"', svg_norm)
        self.assertIn("idle", svg_norm)

        self.assertTrue(svg_vuln.startswith('<svg xmlns="http://www.w3.org/2000/svg"'))
        self.assertIn("vulnerable", svg_vuln)

    def test_svg_preview_estado_invalido_lanza_excepcion(self):
        with self.assertRaises(ValueError):
            art.svg_preview("estado_inexistente", False)

    def test_svg_preview_determinismo(self):
        svg1 = art.svg_preview("attack", False)
        svg2 = art.svg_preview("attack", False)
        self.assertEqual(svg1, svg2)


class TestEscribirPreviews(unittest.TestCase):
    """Pruebas para escribir_previews(destino)."""

    def test_escribir_previews_ficheros_escritos(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            destino = Path(tmpdir)
            art.escribir_previews(destino)

            f1 = destino / "myrmidon_v1_preview_normal.svg"
            f2 = destino / "myrmidon_v1_preview_vulnerable.svg"

            self.assertTrue(f1.exists(), "Debe existir myrmidon_v1_preview_normal.svg")
            self.assertTrue(f2.exists(), "Debe existir myrmidon_v1_preview_vulnerable.svg")

            content1 = f1.read_text(encoding="utf-8")
            content2 = f2.read_text(encoding="utf-8")

            self.assertTrue(content1.startswith('<svg xmlns="http://www.w3.org/2000/svg"'))
            self.assertTrue(content2.startswith('<svg xmlns="http://www.w3.org/2000/svg"'))

    def test_escribir_previews_determinismo(self):
        with tempfile.TemporaryDirectory() as tmp1, tempfile.TemporaryDirectory() as tmp2:
            dir1 = Path(tmp1)
            dir2 = Path(tmp2)

            art.escribir_previews(dir1)
            art.escribir_previews(dir2)

            f1_a = (dir1 / "myrmidon_v1_preview_normal.svg").read_text(encoding="utf-8")
            f1_b = (dir2 / "myrmidon_v1_preview_normal.svg").read_text(encoding="utf-8")
            f2_a = (dir1 / "myrmidon_v1_preview_vulnerable.svg").read_text(encoding="utf-8")
            f2_b = (dir2 / "myrmidon_v1_preview_vulnerable.svg").read_text(encoding="utf-8")

            self.assertEqual(f1_a, f1_b)
            self.assertEqual(f2_a, f2_b)


if __name__ == "__main__":
    unittest.main()
