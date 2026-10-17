"""Pruebas para gbc/minijuegos/ryu_flow_98/generar_arte.py.

Cubre las funciones públicas de generación y exportación de arte CGB:
- icono_torii
- celdas_de_agua
- hoja_dragon
- exportar_fotogramas
- sprites_dragon
- escena_juego
- escena_victoria
- paletas_de_nivel
"""

from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

try:
    import numpy as np
    from PIL import Image
    HAS_DEPS = True
except ImportError:
    HAS_DEPS = False

import gbc.minijuegos.ryu_flow_98.generar_arte as ga


@unittest.skipUnless(HAS_DEPS, "requiere numpy y Pillow")
class TestGenerarArteEscenas(unittest.TestCase):

    def test_icono_torii(self):
        hueco_color = (12, 34, 56)
        im = ga.icono_torii(hueco_color)
        self.assertEqual(im.size, (14, 16))
        self.assertEqual(im.mode, "RGB")

        # ICONO_TORII[0] is "TRRRRRRRRRRRRT"
        self.assertEqual(im.getpixel((0, 0)), ga.TINTA)
        self.assertEqual(im.getpixel((1, 0)), ga.ROJO)
        # ICONO_TORII[1] is ".RRRRRRRRRRRR."
        self.assertEqual(im.getpixel((0, 1)), ga.CREMA)
        # ICONO_TORII[5] is "..RRHHHHHHRR.." -> x=4 es 'H'
        self.assertEqual(im.getpixel((4, 5)), hueco_color)

    def test_celdas_de_agua(self):
        # 1. Imagen con píxeles de agua (30, 40, 200)
        img_agua = Image.new("RGB", (160, 120), (30, 40, 200))
        celdas = ga.celdas_de_agua(img_agua)
        self.assertIsInstance(celdas, list)
        self.assertTrue(len(celdas) > 0)
        # Invariante: las celdas de la región montañosa quedan excluidas
        for c in celdas:
            y, x = divmod(c, 20)
            self.assertFalse(y < 2)
            self.assertFalse(y < 3 and x < 17)
            self.assertFalse(y < 5 and 5 <= x <= 12)

        # 2. Imagen negra sin agua -> celdas vacías
        img_negro = Image.new("RGB", (160, 120), (0, 0, 0))
        self.assertEqual(ga.celdas_de_agua(img_negro), [])

        # 3. Imagen roja torii (250, 10, 10) -> excluida por rojizo > 0.05
        img_rojo = Image.new("RGB", (160, 120), (250, 10, 10))
        self.assertEqual(ga.celdas_de_agua(img_rojo), [])

    def test_hoja_dragon(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            sheet_path = Path(tmpdir) / "dragon_sprites.png"
            arr = np.full((300, 300, 3), ga.PALETA_HOJA_DRAGON[0], dtype=np.uint8)
            y_starts = [10, 60, 110, 160, 210]
            for row_idx, count in enumerate(ga.FILAS_HOJA_DRAGON):
                y0 = y_starts[row_idx]
                for c in range(count):
                    x0 = 10 + c * 40
                    arr[y0:y0 + 15, x0:x0 + 15] = ga.PALETA_HOJA_DRAGON[1]
            Image.fromarray(arr).save(sheet_path)

            with patch.object(ga, "HOJA_DRAGON", sheet_path):
                indices, filas = ga.hoja_dragon()
                self.assertEqual(indices.shape, (300, 300))
                # Invariante de índices de paleta: rango [0, 3]
                self.assertTrue(np.all((indices >= 0) & (indices <= 3)))
                # Invariante de filas de sprites: len(FILAS_HOJA_DRAGON)
                self.assertEqual(len(filas), len(ga.FILAS_HOJA_DRAGON))
                for row_idx, boxes in enumerate(filas):
                    self.assertEqual(len(boxes), ga.FILAS_HOJA_DRAGON[row_idx])
                    # Invariante de caja de sprite: dentro de los límites de la hoja
                    for x0, y0, x1, y1 in boxes:
                        self.assertTrue(0 <= x0 < x1 <= 300)
                        self.assertTrue(0 <= y0 < y1 <= 300)

    def test_exportar_fotogramas(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            assets_dir = Path(tmpdir)
            f1 = np.zeros((16, 16), int)
            f1[0:8, 0:8] = 1
            f2 = np.zeros((16, 16), int)
            f2[0:8, 0:8] = 1
            f2[8:16, 8:16] = 2

            with patch.object(ga, "ASSETS", assets_dir):
                n_unicos, max_entradas = ga.exportar_fotogramas([f1, f2], "test", "EtiquetaTest")
                self.assertEqual(n_unicos, 2)
                self.assertEqual(max_entradas, 2)

                tiles_file = assets_dir / "dragon_test_tiles.inc"
                fotogramas_file = assets_dir / "dragon_test_fotogramas.inc"
                self.assertTrue(tiles_file.exists())
                self.assertTrue(fotogramas_file.exists())

                tiles_content = tiles_file.read_text(encoding="utf-8")
                self.assertIn("; 2 tiles de sprite de test", tiles_content)

                foto_content = fotogramas_file.read_text(encoding="utf-8")
                self.assertIn("EtiquetaTest0:", foto_content)
                self.assertIn("EtiquetaTest1:", foto_content)

    def test_sprites_dragon(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            sheet_path = tmp_path / "dragon_sprites.png"
            lamina_path = tmp_path / "lamina.png"
            assets_path = tmp_path / "assets"
            assets_path.mkdir()

            arr = np.full((300, 300, 3), ga.PALETA_HOJA_DRAGON[0], dtype=np.uint8)
            y_starts = [10, 60, 110, 160, 210]
            for row_idx, count in enumerate(ga.FILAS_HOJA_DRAGON):
                y0 = y_starts[row_idx]
                for c in range(count):
                    x0 = 10 + c * 40
                    arr[y0:y0 + 15, x0:x0 + 15] = ga.PALETA_HOJA_DRAGON[1]
            Image.fromarray(arr).save(sheet_path)

            Image.new("RGB", (1400, 1100), (120, 140, 160)).save(lamina_path)

            with patch.object(ga, "HOJA_DRAGON", sheet_path), \
                 patch.object(ga, "LAMINA", lamina_path), \
                 patch.object(ga, "ASSETS", assets_path):
                n_cabeza, n_rugido = ga.sprites_dragon()
                self.assertGreater(n_cabeza, 0)
                self.assertGreater(n_rugido, 0)

                for filename in [
                    "dragon_cabeza_tiles.inc",
                    "dragon_cabeza_fotogramas.inc",
                    "dragon_rugido_tiles.inc",
                    "dragon_rugido_fotogramas.inc",
                    "dragon_paletas.inc",
                    "dragon_constantes.inc",
                    "dragon_previa.png",
                ]:
                    self.assertTrue((assets_path / filename).exists(), f"Falta {filename}")

                paletas_text = (assets_path / "dragon_paletas.inc").read_text(encoding="utf-8")
                dw_lines = [l for l in paletas_text.splitlines() if "dw" in l]
                self.assertEqual(len(dw_lines), 3)

                const_text = (assets_path / "dragon_constantes.inc").read_text(encoding="utf-8")
                self.assertIn(f"DEF DRAGON_TILES_CABEZA EQU {n_cabeza}", const_text)

    def test_escena_juego(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            lamina_path = Path(tmpdir) / "lamina.png"
            Image.new("RGB", (1400, 1100), (100, 150, 200)).save(lamina_path)

            with patch.object(ga, "LAMINA", lamina_path):
                base, variantes = ga.escena_juego()
                self.assertEqual(base.size, (160, 144))
                self.assertEqual(base.mode, "RGB")
                self.assertIsInstance(variantes, dict)

                expected_keys = {
                    "Abierta1", "Abierta2", "Abierta3",
                    "Media1", "Media2", "Media3",
                    "Correcta1", "Correcta2", "Correcta3",
                    "Dialogo1", "Dialogo2", "Dialogo3",
                }
                self.assertEqual(set(variantes.keys()), expected_keys)
                for var_img in variantes.values():
                    self.assertEqual(var_img.size, (160, 144))
                    self.assertEqual(var_img.mode, "RGB")

    def test_escena_victoria(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            lamina_path = Path(tmpdir) / "lamina.png"
            Image.new("RGB", (1400, 1100), (100, 150, 200)).save(lamina_path)

            with patch.object(ga, "LAMINA", lamina_path):
                im = ga.escena_victoria()
                self.assertEqual(im.size, (160, 144))
                self.assertEqual(im.mode, "RGB")

    def test_paletas_de_nivel(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            lamina_path = tmp_path / "lamina.png"
            assets_path = tmp_path / "assets"
            assets_path.mkdir()

            Image.new("RGB", (1400, 1100), (100, 150, 200)).save(lamina_path)
            (assets_path / "juego_paletas.inc").write_text(
                "    dw $7FFF, $0000, $03E0, $001F ; paleta 0\n"
                "    dw $7FFF, $03E0, $001F, $0000 ; paleta 1\n"
                "    dw $7FFF, $1234, $2345, $3456 ; paleta 2\n"
                "    dw $7FFF, $4567, $5678, $6789 ; paleta 3\n",
                encoding="utf-8",
            )
            Image.new("RGB", (160, 144), (100, 100, 100)).save(assets_path / "juego_previa.png")

            with patch.object(ga, "LAMINA", lamina_path), \
                 patch.object(ga, "ASSETS", assets_path):
                ga.paletas_de_nivel()

                for fname in [
                    "juego_paletas_amanecer.inc",
                    "juego_paletas_noche.inc",
                    "juego_previa_amanecer.png",
                    "juego_previa_noche.png",
                    "juego_agua.inc",
                ]:
                    self.assertTrue((assets_path / fname).exists(), f"Falta {fname}")

                # Invariante: 4 paletas en amanecer y noche
                for fname in ["juego_paletas_amanecer.inc", "juego_paletas_noche.inc"]:
                    content = (assets_path / fname).read_text(encoding="utf-8")
                    lines = [l for l in content.splitlines() if "dw" in l]
                    self.assertEqual(len(lines), 4)
                    # Paletas HUD 0 y 1 fijas
                    self.assertIn("$7FFF, $0000, $03E0, $001F", lines[0])
                    self.assertIn("$7FFF, $03E0, $001F, $0000", lines[1])

                agua_content = (assets_path / "juego_agua.inc").read_text(encoding="utf-8")
                agua_dw = [l for l in agua_content.splitlines() if "dw" in l]
                self.assertEqual(len(agua_dw), 9)


if __name__ == "__main__":
    unittest.main()
