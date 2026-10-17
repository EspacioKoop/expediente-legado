#!/usr/bin/env python3
import struct
import tempfile
import unittest
from dataclasses import FrozenInstanceError
from pathlib import Path

from scripts.preparar_texturas_pbr import (
    Mapa,
    construir_parser,
    dimensiones,
    encontrar_mapa,
)


def crear_png_minimo(path: Path, ancho: int = 100, alto: int = 200) -> None:
    cabecera = (
        b"\x89PNG\r\n\x1a\n"
        + struct.pack(">I", 13)
        + b"IHDR"
        + struct.pack(">II", ancho, alto)
        + b"\x08\x02\x00\x00\x00"
        + b"\x00\x00\x00\x00"
    )
    path.write_bytes(cabecera)


def crear_jpeg_minimo(path: Path, ancho: int = 300, alto: int = 400) -> None:
    sof = (
        b"\xff\xc0"
        + struct.pack(">H", 17)
        + b"\x08"
        + struct.pack(">HH", alto, ancho)
        + b"\x03\x01\x11\x00\x02\x11\x00\x03\x11\x00"
    )
    path.write_bytes(b"\xff\xd8" + sof + b"\xff\xd9")


class TestMapaClass(unittest.TestCase):
    def test_instanciacion_y_atributos(self) -> None:
        path = Path("texturas/albedo.png")
        mapa = Mapa(tipo="albedo", origen=path, ancho=1024, alto=2048, sha256="abc123hash")
        self.assertEqual(mapa.tipo, "albedo")
        self.assertEqual(mapa.origen, path)
        self.assertEqual(mapa.ancho, 1024)
        self.assertEqual(mapa.alto, 2048)
        self.assertEqual(mapa.sha256, "abc123hash")

    def test_inmutabilidad(self) -> None:
        mapa = Mapa(tipo="normal", origen=Path("normal.png"), ancho=512, alto=512, sha256="hash")
        with self.assertRaises(FrozenInstanceError):
            mapa.tipo = "roughness"  # type: ignore[misc]


class TestDimensiones(unittest.TestCase):
    def test_dimensiones_png_valido(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "test.png"
            crear_png_minimo(path, ancho=1920, alto=1080)
            self.assertEqual(dimensiones(path), (1920, 1080))

    def test_dimensiones_jpeg_valido(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path_jpg = Path(tmp) / "test.jpg"
            path_jpeg = Path(tmp) / "test.jpeg"
            crear_jpeg_minimo(path_jpg, ancho=4096, alto=2048)
            crear_jpeg_minimo(path_jpeg, ancho=2048, alto=1024)

            self.assertEqual(dimensiones(path_jpg), (4096, 2048))
            self.assertEqual(dimensiones(path_jpeg), (2048, 1024))

    def test_formato_no_soportado(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "test.txt"
            path.write_text("datos")
            with self.assertRaisesRegex(ValueError, "formato no soportado"):
                dimensiones(path)

    def test_png_invalido_o_corrupto(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "corrupto.png"
            # At least 24 bytes with PNG header but no IHDR chunk
            path.write_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00" * 4 + b"NOIH" + b"\x00" * 8)
            with self.assertRaisesRegex(ValueError, "PNG sin IHDR"):
                dimensiones(path)

            path_bad_header = Path(tmp) / "bad_header.png"
            path_bad_header.write_bytes(b"NO_ES_PNG_DATOS_CORRUPTOS")
            with self.assertRaisesRegex(ValueError, "PNG inválido"):
                dimensiones(path_bad_header)

    def test_jpeg_invalido_o_corrupto(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "corrupto.jpg"
            path.write_bytes(b"\xff\xd8DATOS_SIN_SOF")
            with self.assertRaisesRegex(ValueError, "JPEG sin marcador SOF"):
                dimensiones(path)

            path_bad_header = Path(tmp) / "bad_header.jpg"
            path_bad_header.write_bytes(b"NO_ES_JPEG_DATOS")
            with self.assertRaisesRegex(ValueError, "JPEG inválido"):
                dimensiones(path_bad_header)


class TestEncontrarMapa(unittest.TestCase):
    def test_encontrar_mapa_existente_unico(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            carpeta = Path(tmp)
            p_albedo = carpeta / "albedo.png"
            p_normal = carpeta / "normal.jpg"
            crear_png_minimo(p_albedo)
            crear_jpeg_minimo(p_normal)

            self.assertEqual(encontrar_mapa(carpeta, "albedo"), p_albedo)
            self.assertEqual(encontrar_mapa(carpeta, "normal"), p_normal)

    def test_encontrar_mapa_ausente(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            carpeta = Path(tmp)
            crear_png_minimo(carpeta / "albedo.png")
            with self.assertRaisesRegex(ValueError, "debe existir exactamente un mapa roughness"):
                encontrar_mapa(carpeta, "roughness")

    def test_encontrar_mapa_duplicado(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            carpeta = Path(tmp)
            crear_png_minimo(carpeta / "albedo.png")
            crear_jpeg_minimo(carpeta / "albedo.jpg")
            with self.assertRaisesRegex(ValueError, "debe existir exactamente un mapa albedo"):
                encontrar_mapa(carpeta, "albedo")


class TestConstruirParser(unittest.TestCase):
    def test_parser_valores_por_defecto(self) -> None:
        parser = construir_parser()
        args = parser.parse_args(
            [
                "mi_carpeta",
                "--nombre",
                "marmol_carrara",
                "--autor",
                "Ana",
                "--licencia",
                "CC0",
                "--fuente",
                "https://example.com",
            ]
        )
        self.assertEqual(args.carpeta, Path("mi_carpeta"))
        self.assertEqual(args.nombre, "marmol_carrara")
        self.assertEqual(args.destino_assets, Path("godot/assets"))
        self.assertEqual(args.autor, "Ana")
        self.assertEqual(args.licencia, "CC0")
        self.assertEqual(args.fuente, "https://example.com")
        self.assertFalse(args.sin_compat_textura_procedural)
        self.assertEqual(args.resolucion_minima, 4096)

    def test_parser_valores_personalizados(self) -> None:
        parser = construir_parser()
        args = parser.parse_args(
            [
                "otra_carpeta",
                "--nombre",
                "madera_roble",
                "--destino-assets",
                "mis_assets",
                "--autor",
                "Pedro",
                "--licencia",
                "MIT",
                "--fuente",
                "interna",
                "--sin-compat-textura-procedural",
                "--resolucion-minima",
                "2048",
            ]
        )
        self.assertEqual(args.destino_assets, Path("mis_assets"))
        self.assertTrue(args.sin_compat_textura_procedural)
        self.assertEqual(args.resolucion_minima, 2048)


if __name__ == "__main__":
    unittest.main()
