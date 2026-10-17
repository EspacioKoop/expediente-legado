#!/usr/bin/env python3
"""Pruebas para validar_textura_embebida y validar_png de materializar_street_furniture_680.py."""

import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location(
    "materializar_street_furniture_680",
    SCRIPTS / "materializar_street_furniture_680.py",
)
mod = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class TestMaterializarStreetFurniturePng(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir_temp = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    # --- Pruebas de validar_png ---

    def test_validar_png_valido(self):
        png_path = self.dir_temp / "textura.png"
        png_path.write_bytes(b"\x89PNG\r\n\x1a\ncontenido_sintetico")
        # No debe lanzar ninguna excepción
        mod.validar_png(png_path)

    def test_validar_png_truncado_o_invalido(self):
        png_truncado = self.dir_temp / "truncado.png"
        png_truncado.write_bytes(b"\x89PNG")
        with self.assertRaisesRegex(mod.MaterializacionError, "no es un PNG válido"):
            mod.validar_png(png_truncado)

        png_cabecera_incorrecta = self.dir_temp / "incorrecto.png"
        png_cabecera_incorrecta.write_bytes(b"GIF89a_no_es_png")
        with self.assertRaisesRegex(mod.MaterializacionError, "no es un PNG válido"):
            mod.validar_png(png_cabecera_incorrecta)

    def test_validar_png_inexistente(self):
        png_inexistente = self.dir_temp / "no_existe.png"
        with self.assertRaisesRegex(mod.MaterializacionError, "no es un PNG válido"):
            mod.validar_png(png_inexistente)

    # --- Pruebas de validar_textura_embebida ---

    def test_validar_textura_embebida_coincidente(self):
        png_bytes = b"\x89PNG\r\n\x1a\ndatos_de_imagen"
        png_path = self.dir_temp / "textura.png"
        png_path.write_bytes(png_bytes)

        ruta_glb = self.dir_temp / "modelo.glb"
        binario = b"PADDING" + png_bytes + b"EXTRA"
        gltf = {
            "images": [{"bufferView": 0}],
            "bufferViews": [{"byteOffset": 7, "byteLength": len(png_bytes)}],
        }

        # No debe lanzar ninguna excepción
        mod.validar_textura_embebida(ruta_glb, gltf, binario, png_path)

    def test_validar_textura_embebida_no_coincidente(self):
        png_bytes_distintos = b"\x89PNG\r\n\x1a\ndatos_distintos"
        png_path = self.dir_temp / "textura.png"
        png_path.write_bytes(png_bytes_distintos)

        ruta_glb = self.dir_temp / "modelo.glb"
        binario = b"\x89PNG\r\n\x1a\ndatos_originales"
        gltf = {
            "images": [{"bufferView": 0}],
            "bufferViews": [{"byteOffset": 0, "byteLength": len(binario)}],
        }

        with self.assertRaisesRegex(mod.MaterializacionError, "no coincide con ninguna imagen"):
            mod.validar_textura_embebida(ruta_glb, gltf, binario, png_path)

    def test_validar_textura_embebida_bufferview_indice_invalido(self):
        png_path = self.dir_temp / "textura.png"
        png_path.write_bytes(b"\x89PNG\r\n\x1a\n")

        ruta_glb = self.dir_temp / "modelo.glb"
        binario = b"datos"

        # Índice negativo
        gltf_negativo = {
            "images": [{"bufferView": -1}],
            "bufferViews": [{"byteOffset": 0, "byteLength": 5}],
        }
        with self.assertRaisesRegex(mod.MaterializacionError, "bufferView de imagen inválido"):
            mod.validar_textura_embebida(ruta_glb, gltf_negativo, binario, png_path)

        # Índice fuera de rango
        gltf_fuera_rango = {
            "images": [{"bufferView": 5}],
            "bufferViews": [{"byteOffset": 0, "byteLength": 5}],
        }
        with self.assertRaisesRegex(mod.MaterializacionError, "bufferView de imagen inválido"):
            mod.validar_textura_embebida(ruta_glb, gltf_fuera_rango, binario, png_path)

    def test_validar_textura_embebida_bufferview_no_dict(self):
        png_path = self.dir_temp / "textura.png"
        png_path.write_bytes(b"\x89PNG\r\n\x1a\n")

        ruta_glb = self.dir_temp / "modelo.glb"
        binario = b"datos"
        gltf = {
            "images": [{"bufferView": 0}],
            "bufferViews": ["no_un_dict"],
        }
        with self.assertRaisesRegex(mod.MaterializacionError, "bufferView inválido"):
            mod.validar_textura_embebida(ruta_glb, gltf, binario, png_path)

    def test_validar_textura_embebida_truncada(self):
        png_path = self.dir_temp / "textura.png"
        png_path.write_bytes(b"\x89PNG\r\n\x1a\n")

        ruta_glb = self.dir_temp / "modelo.glb"
        binario = b"corto"

        # Largo <= 0
        gltf_largo_cero = {
            "images": [{"bufferView": 0}],
            "bufferViews": [{"byteOffset": 0, "byteLength": 0}],
        }
        with self.assertRaisesRegex(mod.MaterializacionError, "imagen embebida truncada"):
            mod.validar_textura_embebida(ruta_glb, gltf_largo_cero, binario, png_path)

        # Offset + Largo excede el tamaño del binario
        gltf_excede_binario = {
            "images": [{"bufferView": 0}],
            "bufferViews": [{"byteOffset": 3, "byteLength": 10}],
        }
        with self.assertRaisesRegex(mod.MaterializacionError, "imagen embebida truncada"):
            mod.validar_textura_embebida(ruta_glb, gltf_excede_binario, binario, png_path)


if __name__ == "__main__":
    unittest.main()
