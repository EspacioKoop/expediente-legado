#!/usr/bin/env python3
"""Pruebas unitarias para sha256_bytes y assets_por_id en preparar_school_classrooms_styloo.py."""

import hashlib
import unittest

from scripts.preparar_school_classrooms_styloo import assets_por_id, sha256_bytes


class TestPrepararSchoolClassroomsIds(unittest.TestCase):
    def test_sha256_bytes_vacio(self) -> None:
        datos = b""
        esperado = hashlib.sha256(datos).hexdigest()
        self.assertEqual(sha256_bytes(datos), esperado)

    def test_sha256_bytes_datos_sinteticos(self) -> None:
        datos = b"School Classrooms Styloo Synthetic Test Data 123"
        esperado = hashlib.sha256(datos).hexdigest()
        self.assertEqual(sha256_bytes(datos), esperado)

    def test_assets_por_id_manifiesto_valido(self) -> None:
        manifiesto = {
            "assets": [
                {"id": "escritorio_01", "bytes": 1024, "sha256": "abc"},
                {"id": "pizarra_01", "bytes": 2048, "sha256": "def"},
            ]
        }
        resultado = assets_por_id(manifiesto)
        self.assertEqual(len(resultado), 2)
        self.assertIn("escritorio_01", resultado)
        self.assertIn("pizarra_01", resultado)
        self.assertEqual(resultado["escritorio_01"]["bytes"], 1024)
        self.assertEqual(resultado["pizarra_01"]["bytes"], 2048)

    def test_assets_por_id_lista_vacia(self) -> None:
        manifiesto = {"assets": []}
        resultado = assets_por_id(manifiesto)
        self.assertEqual(resultado, {})

    def test_assets_por_id_ids_repetidos(self) -> None:
        manifiesto = {
            "assets": [
                {"id": "silla_01", "version": 1},
                {"id": "silla_01", "version": 2},
                {"id": "armario_01", "version": 1},
            ]
        }
        resultado = assets_por_id(manifiesto)
        self.assertEqual(len(resultado), 2)
        self.assertIn("silla_01", resultado)
        self.assertIn("armario_01", resultado)
        self.assertEqual(resultado["silla_01"]["version"], 2)

    def test_assets_por_id_asset_sin_id(self) -> None:
        manifiesto = {
            "assets": [
                {"nombre": "asset_invalido"},
            ]
        }
        with self.assertRaises(KeyError):
            assets_por_id(manifiesto)

    def test_assets_por_id_sin_clave_assets(self) -> None:
        manifiesto = {"fuente": "styloo"}
        with self.assertRaises(KeyError):
            assets_por_id(manifiesto)


if __name__ == "__main__":
    unittest.main()
