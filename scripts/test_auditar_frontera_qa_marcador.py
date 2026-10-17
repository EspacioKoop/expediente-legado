#!/usr/bin/env python3
"""Pruebas unitarias para contiene_marcador en scripts/auditar_frontera_qa.py."""

from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

from scripts.auditar_frontera_qa import contiene_marcador


class TestContieneMarcador(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self.tmp_dir.name)

    def tearDown(self) -> None:
        self.tmp_dir.cleanup()

    def test_fichero_texto_con_marcador(self) -> None:
        archivo = self.tmp_path / "con_marcador.txt"
        archivo.write_bytes(b"linea 1\nqa_export_marker_116\nlinea 3")
        self.assertTrue(contiene_marcador(archivo))

    def test_fichero_texto_con_marcador_mayusculas(self) -> None:
        archivo = self.tmp_path / "marcador_mayusculas.txt"
        archivo.write_bytes(b"QA_EXPORT_MARKER_116")
        self.assertTrue(contiene_marcador(archivo))

    def test_fichero_texto_sin_marcador(self) -> None:
        archivo = self.tmp_path / "sin_marcador.txt"
        archivo.write_bytes(b"contenido normal de texto sin el marcador qa")
        self.assertFalse(contiene_marcador(archivo))

    def test_fichero_vacio(self) -> None:
        archivo = self.tmp_path / "vacio.txt"
        archivo.write_bytes(b"")
        self.assertFalse(contiene_marcador(archivo))

    def test_fichero_binario_con_marcador(self) -> None:
        archivo = self.tmp_path / "binario_con.bin"
        contenido = bytes(range(256)) + b"qa_export_marker_116" + bytes(range(256))
        archivo.write_bytes(contenido)
        self.assertTrue(contiene_marcador(archivo))

    def test_fichero_binario_sin_marcador(self) -> None:
        archivo = self.tmp_path / "binario_sin.bin"
        contenido = bytes(range(256))
        archivo.write_bytes(contenido)
        self.assertFalse(contiene_marcador(archivo))

    def test_fichero_inexistente_lanza_exception(self) -> None:
        archivo = self.tmp_path / "no_existe.txt"
        with self.assertRaises(FileNotFoundError):
            contiene_marcador(archivo)


if __name__ == "__main__":
    unittest.main()
