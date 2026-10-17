"""Pruebas unitarias para las funciones públicas de scripts/gbc_imagen_a_tiles.py:
kmeans, paletas_por_tile y ajustar.
"""

import unittest

try:
    import numpy as np
    from PIL import Image
    from scripts.gbc_imagen_a_tiles import ajustar, kmeans, paletas_por_tile

    HAS_DEPS = True
except ImportError:
    HAS_DEPS = False


@unittest.skipUnless(HAS_DEPS, "requiere numpy y Pillow")
class TestGbcImagenATilesPaletas(unittest.TestCase):
    """Pruebas para kmeans, paletas_por_tile y ajustar de gbc_imagen_a_tiles.py."""

    def test_kmeans_determinismo_semilla(self):
        """Verifica que kmeans con semilla fija produce resultados deterministas."""
        puntos = np.array([
            [0.0, 0.0],
            [1.0, 1.0],
            [10.0, 10.0],
            [11.0, 11.0],
            [50.0, 50.0],
        ])
        c1 = kmeans(puntos, k=2, semilla=42)
        c2 = kmeans(puntos, k=2, semilla=42)
        np.testing.assert_array_equal(c1, c2)

    def test_kmeans_forma_salida(self):
        """Verifica que la forma de los centros devueltos sea (k, dim)."""
        puntos = np.random.default_rng(0).random((20, 3))
        centros = kmeans(puntos, k=4, semilla=7)
        self.assertEqual(centros.shape, (4, 3))

    def test_kmeans_pocos_puntos_unicos(self):
        """Verifica el comportamiento cuando hay menos puntos únicos que k."""
        puntos = np.array([
            [1.0, 2.0, 3.0],
            [1.0, 2.0, 3.0],
            [4.0, 5.0, 6.0],
        ])
        centros = kmeans(puntos, k=4)
        self.assertEqual(centros.shape, (4, 3))

    def test_kmeans_con_pesos(self):
        """Verifica la ejecución de kmeans cuando se proporcionan pesos."""
        puntos = np.array([
            [0.0, 0.0],
            [0.1, 0.1],
            [10.0, 10.0],
            [10.1, 10.1],
        ])
        pesos = np.array([10.0, 10.0, 1.0, 1.0])
        centros = kmeans(puntos, k=2, pesos=pesos, semilla=1)
        self.assertEqual(centros.shape, (2, 2))

    def test_kmeans_convergencia(self):
        """Verifica que los centros convergen hacia los clusters sintéticos."""
        cluster_a = np.array([[0.0, 0.0], [0.1, 0.1], [0.2, -0.1]])
        cluster_b = np.array([[100.0, 100.0], [100.1, 99.9], [99.8, 100.2]])
        puntos = np.vstack([cluster_a, cluster_b])
        centros = kmeans(puntos, k=2, semilla=0)

        # Ordenar centros por su norma para comparación
        normas = np.linalg.norm(centros, axis=1)
        idx_a, idx_b = np.argsort(normas)

        np.testing.assert_allclose(centros[idx_a], [0.1, 0.0], atol=0.5)
        np.testing.assert_allclose(centros[idx_b], [100.0, 100.0], atol=0.5)

    def test_paletas_por_tile_forma_y_limites(self):
        """Verifica que paletas_por_tile no devuelva más de 8 paletas de 4 colores recortadas."""
        rng = np.random.default_rng(123)
        # 16 tiles, cada uno de 64 píxeles con 3 canales RGB (rango 0..31)
        tiles = [rng.uniform(0, 31, (64, 3)) for _ in range(16)]

        paletas, grupo = paletas_por_tile(tiles, n_paletas=8, iteraciones=3)

        self.assertEqual(paletas.shape, (8, 4, 3))
        self.assertEqual(grupo.shape, (16,))
        self.assertEqual(paletas.dtype, np.int32)
        self.assertTrue(np.all(paletas >= 0))
        self.assertTrue(np.all(paletas <= 31))
        self.assertTrue(np.all(grupo >= 0))
        self.assertTrue(np.all(grupo < 8))

    def test_paletas_por_tile_sin_recortar(self):
        """Verifica el retorno sin recortar (recortar=False)."""
        rng = np.random.default_rng(456)
        tiles = [rng.uniform(-10, 40, (64, 3)) for _ in range(10)]

        paletas, grupo = paletas_por_tile(tiles, n_paletas=8, iteraciones=2, recortar=False)

        self.assertEqual(paletas.shape, (8, 4, 3))
        self.assertEqual(grupo.shape, (10,))
        self.assertTrue(np.issubdtype(paletas.dtype, np.floating))

    def test_paletas_por_tile_fijas_y_solo_fijas(self):
        """Verifica el respeto a paletas fijas y la restricción solo_fijas."""
        rng = np.random.default_rng(789)
        tiles = [rng.uniform(0, 31, (64, 3)) for _ in range(12)]

        # 2 paletas fijas de 4 colores RGB555 cada una
        fijas = np.array([
            [[0, 0, 0], [10, 0, 0], [20, 0, 0], [30, 0, 0]],
            [[0, 0, 0], [0, 10, 0], [0, 20, 0], [0, 30, 0]],
        ], dtype=np.float64)

        # Los primeros 4 tiles deben usar solo paletas fijas
        solo_fijas = [True] * 4 + [False] * 8

        paletas, grupo = paletas_por_tile(
            tiles, n_paletas=8, iteraciones=2, fijas=fijas, solo_fijas=solo_fijas
        )

        # Las dos primeras paletas coinciden con las fijas
        np.testing.assert_allclose(paletas[:2], fijas)

        # Los tiles marcados solo_fijas deben tener asignado un grupo < 2
        for g in grupo[:4]:
            self.assertIn(g, (0, 1))

    def test_paletas_por_tile_reservadas(self):
        """Verifica la asignación de paletas reservadas a tiles específicos."""
        rng = np.random.default_rng(101)
        tiles = [rng.uniform(0, 31, (64, 3)) for _ in range(10)]

        reservadas = [-1] * 10
        reservadas[3] = 5  # Tile index 3 reservado para paleta 5

        paletas, grupo = paletas_por_tile(
            tiles, n_paletas=8, iteraciones=2, reservadas=reservadas
        )

        self.assertEqual(grupo[3], 5)

    def test_ajustar_dimension_salida(self):
        """Verifica que ajustar reduzca/recorte cualquier imagen a 160x144."""
        im_ancha = Image.new("RGB", (300, 200), color=(255, 0, 0))
        out_ancha = ajustar(im_ancha)
        self.assertEqual(out_ancha.size, (160, 144))

        im_alta = Image.new("RGB", (200, 300), color=(0, 255, 0))
        out_alta = ajustar(im_alta)
        self.assertEqual(out_alta.size, (160, 144))

    def test_ajustar_recorte_horizontal_ancla(self):
        """Verifica que ancla_x desplace la ventana de recorte horizontal."""
        # Crear imagen de 320x144: mitad izquierda azul, mitad derecha roja
        im = Image.new("RGB", (320, 144))
        for x in range(320):
            for y in range(144):
                if x < 160:
                    im.putpixel((x, y), (0, 0, 255))
                else:
                    im.putpixel((x, y), (255, 0, 0))

        # ancla_x=0.0 debe recortar la parte izquierda (predominante azul)
        out_izq = ajustar(im, ancla_x=0.0)
        px_izq = np.array(out_izq)
        self.assertGreater(px_izq[:, :, 2].mean(), px_izq[:, :, 0].mean())

        # ancla_x=1.0 debe recortar la parte derecha (predominante roja)
        out_der = ajustar(im, ancla_x=1.0)
        px_der = np.array(out_der)
        self.assertGreater(px_der[:, :, 0].mean(), px_der[:, :, 2].mean())

    def test_ajustar_recorte_vertical_ancla(self):
        """Verifica que ancla_y desplace la ventana de recorte vertical."""
        # Crear imagen de 160x288: mitad superior azul, mitad inferior roja
        im = Image.new("RGB", (160, 288))
        for x in range(160):
            for y in range(288):
                if y < 144:
                    im.putpixel((x, y), (0, 0, 255))
                else:
                    im.putpixel((x, y), (255, 0, 0))

        # ancla_y=0.0 debe recortar la parte superior (predominante azul)
        out_sup = ajustar(im, ancla_y=0.0)
        px_sup = np.array(out_sup)
        self.assertGreater(px_sup[:, :, 2].mean(), px_sup[:, :, 0].mean())

        # ancla_y=1.0 debe recortar la parte inferior (predominante roja)
        out_inf = ajustar(im, ancla_y=1.0)
        px_inf = np.array(out_inf)
        self.assertGreater(px_inf[:, :, 0].mean(), px_inf[:, :, 2].mean())


if __name__ == "__main__":
    unittest.main()
