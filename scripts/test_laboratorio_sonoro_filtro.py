#!/usr/bin/env python3
"""Pruebas unitarias para limitar16 y filtrar_fuente de laboratorio_sonoro_1475.py."""

from __future__ import annotations

import unittest

from scripts.laboratorio_sonoro_1475 import filtrar_fuente, limitar16


class TestLimitar16(unittest.TestCase):
    """Pruebas para la función limitar16."""

    def test_dentro_de_rango(self) -> None:
        """Verifica que valores dentro de [-32768, 32767] permanecen inalterados."""
        self.assertEqual(limitar16(0), 0)
        self.assertEqual(limitar16(15000), 15000)
        self.assertEqual(limitar16(-15000), -15000)

    def test_limites_exactos(self) -> None:
        """Verifica el comportamiento en los bordes exactos de 16 bits firmado."""
        self.assertEqual(limitar16(32767), 32767)
        self.assertEqual(limitar16(-32768), -32768)

    def test_fuera_de_rango_positivo(self) -> None:
        """Verifica la saturación superior a 32767 para valores por encima del máximo."""
        self.assertEqual(limitar16(32768), 32767)
        self.assertEqual(limitar16(100000), 32767)

    def test_fuera_de_rango_negativo(self) -> None:
        """Verifica la saturación inferior a -32768 para valores por debajo del mínimo."""
        self.assertEqual(limitar16(-32769), -32768)
        self.assertEqual(limitar16(-100000), -32768)


class TestFiltrarFuente(unittest.TestCase):
    """Pruebas para la función filtrar_fuente."""

    def test_conserva_longitud(self) -> None:
        """Verifica que filtrar_fuente devuelve una lista del mismo tamaño que la entrada."""
        self.assertEqual(len(filtrar_fuente([], bucle=True)), 0)
        self.assertEqual(len(filtrar_fuente([], bucle=False)), 0)

        muestra_corta = [0.5, -0.5, 0.25]
        self.assertEqual(len(filtrar_fuente(muestra_corta, bucle=True)), len(muestra_corta))
        self.assertEqual(len(filtrar_fuente(muestra_corta, bucle=False)), len(muestra_corta))

        muestra_larga = [0.1 * (i % 10) for i in range(256)]
        self.assertEqual(len(filtrar_fuente(muestra_larga, bucle=True)), len(muestra_larga))
        self.assertEqual(len(filtrar_fuente(muestra_larga, bucle=False)), len(muestra_larga))

    def test_atenuacion_senial_alterna_nyquist(self) -> None:
        """Verifica la atenuación de una señal alterna en frecuencia de Nyquist (alto brillo)."""
        nyquist = [1.0 if i % 2 == 0 else -1.0 for i in range(100)]

        filtrada_bucle = filtrar_fuente(nyquist, bucle=True)
        filtrada_nobucle = filtrar_fuente(nyquist, bucle=False)

        max_bucle = max(abs(x) for x in filtrada_bucle)
        max_nobucle = max(abs(x) for x in filtrada_nobucle)

        # La señal de entrada tiene amplitud 1.0; la señal filtrada a Nyquist debe quedar fuertemente atenuada.
        self.assertLess(max_bucle, 0.05)
        self.assertLess(max_nobucle, 0.2)

    def test_respeto_modo_bucle(self) -> None:
        """Verifica la diferencia en los bordes entre el modo bucle (circular) y sin bucle (zero padding)."""
        dc = [1.0] * 100

        filtrada_bucle = filtrar_fuente(dc, bucle=True)
        filtrada_nobucle = filtrar_fuente(dc, bucle=False)

        # Con bucle=True, al envolver circularmente, una señal constante no pierde energía en los extremos.
        for x in filtrada_bucle:
            self.assertAlmostEqual(x, 1.0, places=5)

        # Con bucle=False, el rellenado con ceros (zero-padding) reduce la amplitud en los extremos.
        self.assertLess(filtrada_nobucle[0], 0.9)
        self.assertAlmostEqual(filtrada_nobucle[50], 1.0, places=5)


if __name__ == "__main__":
    unittest.main()
