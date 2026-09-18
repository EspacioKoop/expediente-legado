#!/usr/bin/env python3
"""Regresión del paquete de cata auditiva de #119."""

from __future__ import annotations

import importlib.util
import math
import unittest
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
CATA = RAIZ / "scripts" / "preparar_cata_ambientes.py"


def cargar_cata():
    spec = importlib.util.spec_from_file_location("cata_ambientes", CATA)
    assert spec is not None and spec.loader is not None
    modulo = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modulo)
    return modulo


class CataAmbientesOriginalesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cata = cargar_cata()
        cls.generador = cls.cata.cargar_generador()
        cls.especificaciones = cls.cata.cargar_especificaciones(
            cls.cata.ORIGEN_PREDETERMINADO
        )

    def test_cubre_las_cuatro_fuentes_en_orden_de_recorrido(self):
        self.assertEqual(
            self.cata.ORDEN,
            ("fluorescente", "teclado_oficina", "calle_noche", "sueno"),
        )
        self.assertTrue(set(self.cata.ORDEN).issubset(self.especificaciones))

    def test_repeticion_conserva_el_loop_sin_crossfade_oculto(self):
        muestras = [0.1, -0.2, 0.3]
        self.assertEqual(
            self.cata.repetir(muestras, 3),
            [0.1, -0.2, 0.3, 0.1, -0.2, 0.3, 0.1, -0.2, 0.3],
        )
        with self.assertRaises(ValueError):
            self.cata.repetir(muestras, 1)

    def test_metricas_son_finitas_para_todas_las_fuentes(self):
        for identificador in self.cata.ORDEN:
            with self.subTest(identificador=identificador):
                _, cfg = self.especificaciones[identificador]
                muestras = self.generador.SINTESIS[cfg["tipo"]](cfg)
                valores = self.cata.metricas(muestras)
                self.assertGreater(valores["pico"], 0.0)
                self.assertGreater(valores["rms"], 0.0)
                self.assertLessEqual(valores["pico"], 1.0)
                self.assertLess(abs(valores["media_dc"]), 0.1)
                self.assertTrue(all(math.isfinite(v) for v in valores.values()))

    def test_metricas_son_deterministas(self):
        _, cfg = self.especificaciones["fluorescente"]
        a = self.generador.SINTESIS[cfg["tipo"]](cfg)
        b = self.generador.SINTESIS[cfg["tipo"]](cfg)
        self.assertEqual(self.cata.metricas(a), self.cata.metricas(b))

    def test_ficha_no_confunde_ci_con_validacion_humana(self):
        fuentes = [{"id": identificador} for identificador in self.cata.ORDEN]
        ficha = self.cata.ficha_revision(fuentes)
        self.assertIn("no sustituyen la escucha humana", ficha)
        self.assertIn("promover / ☐ iterar / ☐ descartar", ficha)
        for identificador in self.cata.ORDEN:
            self.assertIn(identificador, ficha)


if __name__ == "__main__":
    unittest.main()
