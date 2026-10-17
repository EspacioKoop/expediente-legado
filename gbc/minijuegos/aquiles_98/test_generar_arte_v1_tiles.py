#!/usr/bin/env python3
"""Pruebas unitarias para las funciones de manipulacion de tiles y paletas en generar_arte_v1.py."""

import unittest
from gbc.minijuegos.aquiles_98.generar_arte_v1 import (
    rect,
    tile_desde,
    tile_bytes,
    bgr555,
    lienzo,
    TILE,
)


class TestGenerarArteV1Tiles(unittest.TestCase):
    def test_rect_en_limites(self):
        """Verifica el dibujado de un rectangulo dentro de los limites de la imagen."""
        img = lienzo(10, 10, valor=0)
        rect(img, 2, 3, 4, 3, 2)

        # Comprobar que los pixeles dentro del rectangulo valen 2
        for y in range(3, 6):
            for x in range(2, 6):
                self.assertEqual(img[y][x], 2, f"Fallo en x={x}, y={y}")

        # Comprobar que los pixeles fuera siguen en 0
        self.assertEqual(img[2][2], 0)
        self.assertEqual(img[6][2], 0)
        self.assertEqual(img[3][1], 0)
        self.assertEqual(img[3][6], 0)

    def test_rect_recorte_fuera_de_limites(self):
        """Verifica que rect recorta correctamente cuando x/y o dimensiones sobrepasan el lienzo."""
        img = lienzo(5, 5, valor=0)
        # Rectangulo parcialmente fuera por la izquierda/arriba
        rect(img, -2, -2, 4, 4, 1)
        self.assertEqual(img[0][0], 1)
        self.assertEqual(img[0][1], 1)
        self.assertEqual(img[1][0], 1)
        self.assertEqual(img[1][1], 1)
        self.assertEqual(img[2][0], 0)

        # Rectangulo parcialmente fuera por la derecha/abajo
        rect(img, 3, 3, 5, 5, 3)
        self.assertEqual(img[3][3], 3)
        self.assertEqual(img[4][4], 3)
        self.assertEqual(img[2][3], 0)

    def test_rect_dimensiones_cero_o_negativas(self):
        """Verifica que dimensiones cero o negativas no alteran el lienzo."""
        img = lienzo(5, 5, valor=0)
        rect(img, 1, 1, 0, 3, 2)
        rect(img, 1, 1, 3, -1, 2)
        for fila in img:
            for px in fila:
                self.assertEqual(px, 0)

    def test_tile_desde(self):
        """Verifica la extraccion de un tile 8x8 desde coordenadas tx, ty en un lienzo."""
        w, h = 24, 16
        img = lienzo(w, h, valor=0)
        # Llenar la region correspondiente a tx=1, ty=0 (x: 8..15, y: 0..7) con patron conocido
        for y in range(TILE):
            for x in range(TILE):
                img[y][8 + x] = (x + y) % 4

        tile = tile_desde(img, 1, 0)
        self.assertEqual(len(tile), TILE)
        for y in range(TILE):
            self.assertEqual(len(tile[y]), TILE)
            for x in range(TILE):
                self.assertEqual(tile[y][x], (x + y) % 4)

        # Probar tile en tx=2, ty=1 (x: 16..23, y: 8..15)
        tile_vacio = tile_desde(img, 2, 1)
        self.assertEqual(tile_vacio, tuple(tuple(0 for _ in range(8)) for _ in range(8)))

    def test_tile_bytes_produccion_2bpp(self):
        """Verifica que tile_bytes produce exactamente 16 bytes en formato 2bpp."""
        # 1. Tile con todos los pixeles en 0
        tile_cero = tuple(tuple(0 for _ in range(8)) for _ in range(8))
        bytes_cero = tile_bytes(tile_cero)
        self.assertEqual(len(bytes_cero), 16)
        self.assertEqual(bytes_cero, [0] * 16)

        # 2. Tile con todos los pixeles en color 1 (bit bajo 1, bit alto 0)
        tile_col1 = tuple(tuple(1 for _ in range(8)) for _ in range(8))
        bytes_col1 = tile_bytes(tile_col1)
        self.assertEqual(bytes_col1, [0xFF, 0x00] * 8)

        # 3. Tile con todos los pixeles en color 2 (bit bajo 0, bit alto 1)
        tile_col2 = tuple(tuple(2 for _ in range(8)) for _ in range(8))
        bytes_col2 = tile_bytes(tile_col2)
        self.assertEqual(bytes_col2, [0x00, 0xFF] * 8)

        # 4. Tile con todos los pixeles en color 3 (bit bajo 1, bit alto 1)
        tile_col3 = tuple(tuple(3 for _ in range(8)) for _ in range(8))
        bytes_col3 = tile_bytes(tile_col3)
        self.assertEqual(bytes_col3, [0xFF, 0xFF] * 8)

        # 5. Fila especifica con patron mixto en la primera fila: px 0 = 3, px 7 = 1
        tile_mixto = [[3, 0, 0, 0, 0, 0, 0, 1]] + [[0] * 8 for _ in range(7)]
        bytes_mixtos = tile_bytes(tile_mixto)
        # Para [3, 0, 0, 0, 0, 0, 0, 1]:
        # bit 7: px=3 => lo=1, hi=1
        # bit 0: px=1 => lo=1, hi=0
        # lo = 0b10000001 = 0x81 (129)
        # hi = 0b10000000 = 0x80 (128)
        self.assertEqual(bytes_mixtos[0], 0x81)
        self.assertEqual(bytes_mixtos[1], 0x80)

    def test_bgr555_colores_claves(self):
        """Verifica la conversion de hex_color a valor entero BGR555 de 15 bits."""
        # #000000 -> 0
        self.assertEqual(bgr555("#000000"), 0)
        self.assertEqual(bgr555("000000"), 0)

        # #FFFFFF -> R=31, G=31, B=31 -> 0x7FFF (32767)
        self.assertEqual(bgr555("#FFFFFF"), 0x7FFF)

        # Primario Rojo #FF0000 -> R=31, G=0, B=0 -> 31 (0x001F)
        self.assertEqual(bgr555("#FF0000"), 31)

        # Primario Verde #00FF00 -> R=0, G=31, B=0 -> 31<<5 = 992 (0x03E0)
        self.assertEqual(bgr555("#00FF00"), 992)

        # Primario Azul #0000FF -> R=0, G=0, B=31 -> 31<<10 = 31744 (0x7C00)
        self.assertEqual(bgr555("#0000FF"), 31744)


if __name__ == "__main__":
    unittest.main()
