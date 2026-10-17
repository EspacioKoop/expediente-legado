#!/usr/bin/env python3
"""Pruebas unitarias para las funciones de preparar_cata_ambientes.py (#119)."""

from __future__ import annotations

import hashlib
import math
import tempfile
import unittest
from pathlib import Path

from scripts.preparar_cata_ambientes import (
    ficha_revision,
    metricas,
    repetir,
    sha256,
)


class TestPrepararCataAmbientesMetricas(unittest.TestCase):
    """Pruebas para las funciones públicas de preparar_cata_ambientes.py."""

    # --- Pruebas para repetir ---

    def test_repetir_valido(self) -> None:
        muestras = [0.1, -0.2, 0.5]
        resultado = repetir(muestras, 2)
        self.assertEqual(resultado, [0.1, -0.2, 0.5, 0.1, -0.2, 0.5])
        self.assertEqual(len(resultado), len(muestras) * 2)

        resultado_3 = repetir(muestras, 3)
        self.assertEqual(resultado_3, [0.1, -0.2, 0.5] * 3)

    def test_repetir_repeticiones_invalidas(self) -> None:
        muestras = [0.1, 0.2]
        for rep in [1, 0, -1, -5]:
            with self.subTest(repeticiones=rep):
                with self.assertRaises(ValueError) as ctx:
                    repetir(muestras, rep)
                self.assertIn("al menos dos repeticiones", str(ctx.exception))

    # --- Pruebas para metricas ---

    def test_metricas_silencio(self) -> None:
        silencio = [0.0] * 100
        res = metricas(silencio)
        self.assertEqual(res["pico"], 0.0)
        self.assertEqual(res["rms"], 0.0)
        self.assertEqual(res["rms_dbfs"], -120.0)
        self.assertEqual(res["media_dc"], 0.0)
        self.assertEqual(res["salto_loop"], 0.0)
        self.assertEqual(res["salto_loop_db_rel_pico"], -120.0)
        self.assertEqual(res["salto_pendiente"], 0.0)

    def test_metricas_seno(self) -> None:
        seno = [math.sin(2 * math.pi * i / 8) for i in range(8)]
        res = metricas(seno)
        self.assertEqual(res["pico"], 1.0)
        self.assertAlmostEqual(res["rms"], 0.70710678, places=6)
        self.assertAlmostEqual(res["rms_dbfs"], -3.01, places=2)
        self.assertAlmostEqual(res["media_dc"], 0.0, places=6)
        self.assertIn("salto_loop", res)
        self.assertIn("salto_loop_db_rel_pico", res)
        self.assertIn("salto_pendiente", res)

    def test_metricas_saturada(self) -> None:
        saturado = [1.0 if i % 2 == 0 else -1.0 for i in range(10)]
        res = metricas(saturado)
        self.assertEqual(res["pico"], 1.0)
        self.assertEqual(res["rms"], 1.0)
        self.assertEqual(res["rms_dbfs"], 0.0)
        self.assertEqual(res["media_dc"], 0.0)
        self.assertEqual(res["salto_loop"], 2.0)
        self.assertEqual(res["salto_pendiente"], 0.0)

    def test_metricas_insuficientes_muestras(self) -> None:
        for muestras in [[], [0.5]]:
            with self.subTest(muestras=muestras):
                with self.assertRaises(ValueError) as ctx:
                    metricas(muestras)
                self.assertIn("se necesitan al menos dos muestras", str(ctx.exception))

    # --- Pruebas para sha256 ---

    def test_sha256_fichero_pequeno(self) -> None:
        contenido = b"Prueba de cata de ambientes 1998"
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            tmp.write(contenido)
            tmp_path = Path(tmp.name)
        try:
            esperado = hashlib.sha256(contenido).hexdigest()
            self.assertEqual(sha256(tmp_path), esperado)
        finally:
            tmp_path.unlink(missing_ok=True)

    def test_sha256_fichero_vacio(self) -> None:
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            tmp_path = Path(tmp.name)
        try:
            esperado = hashlib.sha256(b"").hexdigest()
            self.assertEqual(sha256(tmp_path), esperado)
        finally:
            tmp_path.unlink(missing_ok=True)

    def test_sha256_fichero_multibloque(self) -> None:
        # Fichero mayor a 1MB (1024 * 1024 bytes) para probar la lectura en bloques.
        bloque = b"X" * (1024 * 500)
        contenido = bloque * 3  # ~1.5 MB
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            tmp.write(contenido)
            tmp_path = Path(tmp.name)
        try:
            esperado = hashlib.sha256(contenido).hexdigest()
            self.assertEqual(sha256(tmp_path), esperado)
        finally:
            tmp_path.unlink(missing_ok=True)

    # --- Pruebas para ficha_revision ---

    def test_ficha_revision_fuentes_multiples(self) -> None:
        fuentes = [
            {"id": "fluorescente"},
            {"id": "teclado_oficina"},
            {"id": "calle_noche"},
            {"id": "sueno"},
        ]
        doc = ficha_revision(fuentes)
        self.assertIn("# Cata humana de ambientes — #119", doc)
        self.assertIn("| Fuente | Identidad | Loop | Fatiga | Enmascara efectos/diálogo | Decisión | Notas |", doc)
        for fuente in fuentes:
            self.assertIn(f"| {fuente['id']} | ☐ | ☐ | ☐ | ☐ | ☐ promover / ☐ iterar / ☐ descartar | |", doc)
        self.assertIn("## Criterio mínimo", doc)

    def test_ficha_revision_sin_fuentes(self) -> None:
        doc = ficha_revision([])
        self.assertIn("# Cata humana de ambientes — #119", doc)
        self.assertIn("| Fuente | Identidad | Loop | Fatiga | Enmascara efectos/diálogo | Decisión | Notas |", doc)
        self.assertIn("## Criterio mínimo", doc)


if __name__ == "__main__":
    unittest.main()
