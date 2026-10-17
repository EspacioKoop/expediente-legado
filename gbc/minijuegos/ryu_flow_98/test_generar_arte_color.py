"""Pruebas unitarias para gbc/minijuegos/ryu_flow_98/generar_arte.py (#808).

Verifica las funciones públicas de procesamiento de color, tiles y sprites:
- transferir_color
- a_bgr555
- tile_2bpp
- reducir_sprite
"""

from pathlib import Path
import sys
import unittest

try:
    import numpy as np
    from PIL import Image
    HAS_DEPS = True
except ImportError:
    HAS_DEPS = False

if HAS_DEPS:
    AQUI = Path(__file__).resolve().parent
    if str(AQUI) not in sys.path:
        sys.path.insert(0, str(AQUI))
    import generar_arte


@unittest.skipUnless(HAS_DEPS, "Faltan dependencias (numpy o PIL)")
class TestGenerarArteColor(unittest.TestCase):

    def test_transferir_color(self):
        # Origen con media 10, std ~8.165 por canal
        origen = [[0, 0, 0], [10, 10, 10], [20, 20, 20]]
        # Destino con media 110, std ~8.165 por canal
        destino = [[100, 100, 100], [110, 110, 110], [120, 120, 120]]
        colores = [[10, 10, 10]]

        res = generar_arte.transferir_color(colores, origen, destino)
        self.assertIsInstance(res, np.ndarray)
        np.testing.assert_allclose(res, [[110.0, 110.0, 110.0]], atol=1e-4)

        # Prueba clipping en [0, 255]
        colores_extremos = [[-1000, -1000, -1000], [1000, 1000, 1000]]
        res_extremos = generar_arte.transferir_color(colores_extremos, origen, destino)
        self.assertEqual(res_extremos[0].tolist(), [0.0, 0.0, 0.0])
        self.assertEqual(res_extremos[1].tolist(), [255.0, 255.0, 255.0])

    def test_a_bgr555(self):
        colores = [
            (255, 0, 0),      # R=31, G=0, B=0 -> 31
            (0, 255, 0),      # R=0, G=31, B=0 -> 31 << 5 = 992
            (0, 0, 255),      # R=0, G=0, B=31 -> 31 << 10 = 31744
            (255, 255, 255),  # R=31, G=31, B=31 -> 32767 ($7FFF)
            (0, 0, 0),        # 0
        ]
        res = generar_arte.a_bgr555(colores)
        self.assertEqual(res, [31, 992, 31744, 32767, 0])

    def test_tile_2bpp(self):
        # Fila con patrón alternado de colores 0, 1, 2, 3
        # 0: b0=0, b1=0
        # 1: b0=1, b1=0
        # 2: b0=0, b1=1
        # 3: b0=1, b1=1
        fila = [0, 1, 2, 3, 0, 1, 2, 3]
        # bitplane bajo:  0 1 0 1 0 1 0 1 -> %01010101 = $55
        # bitplane alto:  0 0 1 1 0 0 1 1 -> %00110011 = $33
        filas = [fila] * 8
        res = generar_arte.tile_2bpp(filas)
        esperado_par = "$55, $33"
        esperado_str = "    db " + ", ".join([esperado_par] * 8)
        self.assertEqual(res, esperado_str)

    def test_reducir_sprite_por_ancho_y_por_alto(self):
        # Matriz de índices 20x20
        indices = np.zeros((20, 20), dtype=int)
        # Caja en (2, 2, 10, 10) -> submatriz 8x8
        # Rellenar un bloque 4x4 con color 3
        indices[2:6, 2:6] = 3

        # Reducir a 4x4 (escala = 8 / 4 = 2.0 por ancho)
        res_ancho = generar_arte.reducir_sprite(indices, (2, 2, 10, 10), 4, 4, por_alto=False)
        self.assertEqual(res_ancho.shape, (4, 4))
        self.assertEqual(res_ancho[0, 0], 3)
        self.assertEqual(res_ancho[0, 1], 3)
        self.assertEqual(res_ancho[1, 0], 3)
        self.assertEqual(res_ancho[1, 1], 3)
        self.assertEqual(res_ancho[2, 2], 0)

        # Reducir por_alto=True con alto=4, ancho=4 (escala = 8 / 4 = 2.0)
        res_alto = generar_arte.reducir_sprite(indices, (2, 2, 10, 10), 4, 4, por_alto=True)
        self.assertEqual(res_alto.shape, (4, 4))
        self.assertEqual(res_alto[0, 0], 3)

    def test_reducir_sprite_regla_contorno_3(self):
        # Verificar la regla donde la presencia del contorno (3) >= 30% lo impone
        # Creamos submatriz 10x10. Para recortar a 5x5, escala es 2.0 (bloques 2x2 = 4 píxeles).
        # Si 1 de 4 píxeles es '3', es 25% (<30%). Si 2 de 4 píxeles son '3', es 50% (>=30%).
        indices = np.ones((10, 10), dtype=int)  # Lleno de 1 (moda = 1)
        # En el bloque (0:2, 0:2), poner dos '3' y dos '1' -> 50% de 3.
        indices[0, 0] = 3
        indices[0, 1] = 3

        res = generar_arte.reducir_sprite(indices, (0, 0, 10, 10), 5, 5)
        # En (0,0) debe ganar 3 a pesar de que la moda pueda ser 1 o empatar.
        self.assertEqual(res[0, 0], 3)
        # En otras celdas sin '3', la moda es 1.
        self.assertEqual(res[1, 1], 1)


if __name__ == "__main__":
    unittest.main()
