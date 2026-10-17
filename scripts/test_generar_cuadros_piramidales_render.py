#!/usr/bin/env python3
"""Pruebas unitarias para Lienzo y renderizar_especificacion en generar_cuadros_piramidales.py."""

import struct
import unittest

from scripts.generar_cuadros_piramidales import Lienzo, renderizar_especificacion


class TestLienzo(unittest.TestCase):
    def test_inicializacion(self) -> None:
        ancho, alto = 10, 5
        fondo = (255, 200, 100)
        lienzo = Lienzo(ancho, alto, fondo)

        self.assertEqual(lienzo.ancho, ancho)
        self.assertEqual(lienzo.alto, alto)
        self.assertEqual(len(lienzo.pixeles), ancho * alto * 3)
        # Verificar que el primer y último píxel tienen el color de fondo
        self.assertEqual(tuple(lienzo.pixeles[:3]), fondo)
        self.assertEqual(tuple(lienzo.pixeles[-3:]), fondo)

    def test_punto_dentro_y_fuera_de_limites(self) -> None:
        lienzo = Lienzo(5, 5, (0, 0, 0))
        color = (255, 255, 255)

        # Punto dentro de límites
        lienzo.punto(2, 3, color)
        idx = (3 * 5 + 2) * 3
        self.assertEqual(tuple(lienzo.pixeles[idx : idx + 3]), color)

        # Puntos fuera de límites (no deben modificar nada ni lanzar excepción)
        pixeles_antes = bytes(lienzo.pixeles)
        lienzo.punto(-1, 0, color)
        lienzo.punto(5, 0, color)
        lienzo.punto(0, -1, color)
        lienzo.punto(0, 5, color)
        self.assertEqual(bytes(lienzo.pixeles), pixeles_antes)

    def test_rectangulo(self) -> None:
        lienzo = Lienzo(10, 10, (0, 0, 0))
        color = (100, 150, 200)

        lienzo.rectangulo(2.0, 2.0, 5.0, 5.0, color)

        # Verificar que un píxel dentro del rectángulo fue modificado
        idx_dentro = (3 * 10 + 3) * 3
        self.assertEqual(tuple(lienzo.pixeles[idx_dentro : idx_dentro + 3]), color)

        # Verificar que un píxel fuera del rectángulo no fue modificado
        idx_fuera = (1 * 10 + 1) * 3
        self.assertEqual(tuple(lienzo.pixeles[idx_fuera : idx_fuera + 3]), (0, 0, 0))

    def test_rectangulo_invalid_o_colapso(self) -> None:
        lienzo = Lienzo(10, 10, (0, 0, 0))
        pixeles_antes = bytes(lienzo.pixeles)

        # x1 <= x0 o y1 <= y0 no debe dibujar nada
        lienzo.rectangulo(5, 5, 5, 8, (255, 0, 0))
        lienzo.rectangulo(5, 5, 8, 5, (255, 0, 0))
        lienzo.rectangulo(8, 8, 2, 2, (255, 0, 0))

        self.assertEqual(bytes(lienzo.pixeles), pixeles_antes)

    def test_elipse(self) -> None:
        lienzo = Lienzo(20, 20, (0, 0, 0))
        color = (255, 0, 0)
        lienzo.elipse(10, 10, 5, 5, color)

        # Centro de la elipse
        idx_centro = (10 * 20 + 10) * 3
        self.assertEqual(tuple(lienzo.pixeles[idx_centro : idx_centro + 3]), color)

        # Esquina lejana fuera de la elipse
        idx_esquina = (0 * 20 + 0) * 3
        self.assertEqual(tuple(lienzo.pixeles[idx_esquina : idx_esquina + 3]), (0, 0, 0))

    def test_poligono(self) -> None:
        lienzo = Lienzo(20, 20, (0, 0, 0))
        color = (0, 255, 0)
        triangulo = [(5.0, 5.0), (15.0, 5.0), (10.0, 15.0)]
        lienzo.poligono(triangulo, color)

        # Interior del triángulo
        idx_interior = (8 * 20 + 10) * 3
        self.assertEqual(tuple(lienzo.pixeles[idx_interior : idx_interior + 3]), color)

        # Fuera del triángulo
        idx_fuera = (2 * 20 + 2) * 3
        self.assertEqual(tuple(lienzo.pixeles[idx_fuera : idx_fuera + 3]), (0, 0, 0))

    def test_linea(self) -> None:
        lienzo = Lienzo(20, 20, (0, 0, 0))
        color = (0, 0, 255)

        lienzo.linea(2, 2, 18, 2, color, grosor=1)

        idx_linea = (2 * 20 + 10) * 3
        self.assertEqual(tuple(lienzo.pixeles[idx_linea : idx_linea + 3]), color)

        idx_fuera = (10 * 20 + 10) * 3
        self.assertEqual(tuple(lienzo.pixeles[idx_fuera : idx_fuera + 3]), (0, 0, 0))


class TestRenderizarEspecificacion(unittest.TestCase):
    def setUp(self) -> None:
        self.paleta_base = {
            "papel": "#D9C8A4",
            "tinta": "#3A302A",
            "sombra": "#6C5340",
            "arena": "#B99B69",
            "arena_clara": "#D5B883",
            "acento": "#A44B38",
            "linea": "#8C7658",
            "noche": "#101020",
            "estrella": "#FFFFFF",
        }

    def test_estructura_png_y_dimensiones(self) -> None:
        ancho, alto = 64, 48
        config = {
            "ancho": ancho,
            "alto": alto,
            "semilla": 12345,
            "motivo": "horizonte",
            "paleta": self.paleta_base,
        }

        salida_png = renderizar_especificacion(config)

        # Firma PNG: \x89PNG\r\n\x1a\n
        self.assertTrue(salida_png.startswith(b"\x89PNG\r\n\x1a\n"))

        # Desempaquetar IHDR
        # Firma (8 bytes) + Longitud chunk IHDR (4 bytes) + Tipo chunk 'IHDR' (4 bytes)
        ihdr_len = struct.unpack(">I", salida_png[8:12])[0]
        self.assertEqual(ihdr_len, 13)
        self.assertEqual(salida_png[12:16], b"IHDR")

        w, h, profundidad, tipo_color, _, _, _ = struct.unpack(
            ">IIBBBBB", salida_png[16:29]
        )
        self.assertEqual(w, ancho)
        self.assertEqual(h, alto)
        self.assertEqual(profundidad, 8)
        self.assertEqual(tipo_color, 2)  # Color Truecolor (RGB)

    def test_determinismo(self) -> None:
        config = {
            "ancho": 80,
            "alto": 60,
            "semilla": 999,
            "motivo": "seccion",
            "paleta": self.paleta_base,
        }

        render_1 = renderizar_especificacion(config)
        render_2 = renderizar_especificacion(config)

        self.assertEqual(render_1, render_2)

    def test_motivos_soportados(self) -> None:
        motivos = ["horizonte", "seccion", "constelacion"]
        for motivo in motivos:
            with self.subTest(motivo=motivo):
                config = {
                    "ancho": 50,
                    "alto": 50,
                    "semilla": 42,
                    "motivo": motivo,
                    "paleta": self.paleta_base,
                }
                salida = renderizar_especificacion(config)
                self.assertTrue(salida.startswith(b"\x89PNG\r\n\x1a\n"))


if __name__ == "__main__":
    unittest.main()
