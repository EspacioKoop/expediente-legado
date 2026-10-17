"""Pruebas unitarias para las funciones de color y paletas en gbc_imagen_a_tiles.py."""

import unittest

try:
    import numpy as np
    import PIL
    HAS_DEPS = True
except ImportError:
    HAS_DEPS = False

if HAS_DEPS:
    from scripts.gbc_imagen_a_tiles import (
        a555,
        de555,
        error_tile,
        ordenar_paleta,
        a_luma_croma,
    )


@unittest.skipUnless(HAS_DEPS, "Requiere numpy y Pillow")
class TestGbcImagenATilesColor(unittest.TestCase):

    def test_a555_conversion(self):
        """Prueba la conversión de RGB de 8 bits a RGB555 de 5 bits."""
        rgb = [0, 128, 255]
        res = a555(rgb)
        np.testing.assert_array_equal(res, [0, 16, 31])

        # Prueba limites/recorte (clip)
        rgb_out = [-10, 300, 100]
        res_out = a555(rgb_out)
        np.testing.assert_array_equal(res_out, [0, 31, 12])

    def test_de555_conversion(self):
        """Prueba la conversión de RGB555 de 5 bits a RGB de 8 bits."""
        c = [0, 16, 31]
        res = de555(c)
        # (c << 3) | (c >> 2)
        # 0 -> 0
        # 16 -> 128 | 4 = 132
        # 31 -> 248 | 7 = 255
        np.testing.assert_array_equal(res, [0, 132, 255])

    def test_a555_de555_ida_y_vuelta_extremos(self):
        """Prueba de ida y vuelta a555/de555 para negro, blanco y colores primarios."""
        extremos = {
            "negro": [0, 0, 0],
            "blanco": [255, 255, 255],
            "rojo": [255, 0, 0],
            "verde": [0, 255, 0],
            "azul": [0, 0, 255],
        }
        for nombre, rgb in extremos.items():
            with self.subTest(color=nombre):
                c555 = a555(rgb)
                rgb_recuperado = de555(c555)
                np.testing.assert_array_equal(rgb_recuperado, rgb)

    def test_error_tile(self):
        """Prueba la distancia cuadrática mínima y los índices devueltos por error_tile."""
        # Un tile con 2 píxeles RGB
        tile = np.array([[0, 0, 0], [31, 31, 31]], dtype=np.float64)
        # Paleta con 4 colores
        paleta = np.array([
            [0, 0, 0],      # Exacto para pixel 0
            [31, 31, 31],   # Exacto para pixel 1
            [15, 15, 15],
            [31, 0, 0],
        ], dtype=np.float64)

        err_total, indices = error_tile(tile, paleta)
        self.assertEqual(err_total, 0.0)
        np.testing.assert_array_equal(indices, [0, 1])

        # Tile con error no nulo
        tile_con_error = np.array([[2, 0, 0]], dtype=np.float64)
        err_total_2, indices_2 = error_tile(tile_con_error, paleta)
        self.assertEqual(err_total_2, 4.0)  # (2-0)^2 = 4
        np.testing.assert_array_equal(indices_2, [0])

    def test_ordenar_paleta(self):
        """Prueba que ordenar_paleta ordene los colores por luminancia descendente."""
        # Paleta desordenada: [negro, blanco, gris_oscuro, gris_claro]
        paleta = np.array([
            [0, 0, 0],
            [31, 31, 31],
            [10, 10, 10],
            [20, 20, 20],
        ])
        paleta_ordenada = ordenar_paleta(paleta)
        esperado = np.array([
            [31, 31, 31],  # Más claro primero
            [20, 20, 20],
            [10, 10, 10],
            [0, 0, 0],     # Más oscuro al final
        ])
        np.testing.assert_array_equal(paleta_ordenada, esperado)

    def test_a_luma_croma(self):
        """Prueba la matriz RGB -> YCbCr con escalado de peso_croma."""
        m_base = a_luma_croma(1.0)
        self.assertEqual(m_base.shape, (3, 3))
        # Fila 0 es luminancia Y = [0.299, 0.587, 0.114]
        np.testing.assert_allclose(m_base[0], [0.299, 0.587, 0.114])

        m_doble = a_luma_croma(2.0)
        # Fila 0 se mantiene igual
        np.testing.assert_allclose(m_doble[0], m_base[0])
        # Filas 1 y 2 se multiplican por 2.0
        np.testing.assert_allclose(m_doble[1], m_base[1] * 2.0)
        np.testing.assert_allclose(m_doble[2], m_base[2] * 2.0)


if __name__ == "__main__":
    unittest.main()
