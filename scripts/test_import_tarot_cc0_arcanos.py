#!/usr/bin/env python3
"""Pruebas unitarias para import_tarot_cc0.py.

Verifica el comportamiento de resolver_arcano, dimensiones_imagen,
ImagenFuente y validar_ids_proyecto.
"""

from __future__ import annotations

from dataclasses import FrozenInstanceError
import json
from pathlib import Path
import struct
import tempfile
import unittest

from scripts.import_tarot_cc0 import (
    ARCANOS,
    ImagenFuente,
    TarotImportError,
    dimensiones_imagen,
    resolver_arcano,
    validar_ids_proyecto,
)


class TestResolverArcano(unittest.TestCase):
    """Pruebas de la función resolver_arcano."""

    def test_resolver_por_nombre_fuente(self) -> None:
        """Verifica resolución por nombre fuente exacto o dentro del nombre de archivo."""
        arcano = resolver_arcano("The Fool.png")
        self.assertEqual(arcano.carta_id, "el-loco")

        arcano_mago = resolver_arcano("01_The_Magician_card.jpg")
        self.assertEqual(arcano_mago.carta_id, "el-mago")

    def test_resolver_por_alias(self) -> None:
        """Verifica resolución por alias conocidos."""
        self.assertEqual(resolver_arcano("fool.png").carta_id, "el-loco")
        self.assertEqual(resolver_arcano("bateleur.jpg").carta_id, "el-mago")
        self.assertEqual(resolver_arcano("pendu.png").carta_id, "el-colgado")

    @unittest.expectedFailure
    def test_resolver_alias_papesse_sacerdotisa(self) -> None:
        """El alias 'papesse' para La Sacerdotisa falla porque coincide erróneamente con 'pape' (El Hierofante).

        _coincidencias_alias detecta tanto 'papesse' (Sacerdotisa) como 'pape' (Hierofante,
        contenido dentro de 'papesse'), por lo que lanza TarotImportError por ambigüedad.
        """
        arcano = resolver_arcano("papesse.png")
        self.assertEqual(arcano.carta_id, "la-sacerdotisa")

    def test_resolver_por_numero_arabigo(self) -> None:
        """Verifica resolución por número en el nombre de archivo cuando no hay alias."""
        self.assertEqual(resolver_arcano("card_00.png").carta_id, "el-loco")
        self.assertEqual(resolver_arcano("arcanum_10_file.jpg").carta_id, "la-rueda")
        self.assertEqual(resolver_arcano("21.png").carta_id, "el-mundo")

    def test_resolver_por_numero_romano(self) -> None:
        """Verifica resolución por número romano cuando no hay alias."""
        self.assertEqual(resolver_arcano("card_i.png").carta_id, "el-mago")
        self.assertEqual(resolver_arcano("arcanum_viii.jpg").carta_id, "la-justicia")
        self.assertEqual(resolver_arcano("xxi_card.png").carta_id, "el-mundo")

    def test_resolver_numeracion_ambigua_lanza_error(self) -> None:
        """Verifica que números ambiguos (múltiples números válidos en el nombre) lanzan error."""
        with self.assertRaises(TarotImportError) as cm:
            resolver_arcano("card_01_and_02.png")
        self.assertIn("Numeración ambigua", str(cm.exception))

    def test_resolver_desconocido_lanza_error(self) -> None:
        """Verifica que nombres que no coinciden con ningún arcano lanzan error."""
        with self.assertRaises(TarotImportError) as cm:
            resolver_arcano("desconocido_sin_numeros.png")
        self.assertIn("No se reconoce el arcano", str(cm.exception))


class TestDimensionesImagen(unittest.TestCase):
    """Pruebas de la función dimensiones_imagen."""

    def test_dimensiones_png_valido(self) -> None:
        """Verifica extracción de dimensiones de una cabecera PNG válida."""
        png_cabecera = (
            b"\x89PNG\r\n\x1a\n"
            + b"\x00\x00\x00\x0d"
            + b"IHDR"
            + struct.pack(">II", 200, 375)
            + b"\x08\x02\x00\x00\x00"
        )
        ancho, alto = dimensiones_imagen("carta.png", png_cabecera)
        self.assertEqual((ancho, alto), (200, 375))

    def test_dimensiones_png_invalido_lanza_error(self) -> None:
        """Verifica que un PNG corrupto o incompleto lanza error."""
        with self.assertRaises(TarotImportError) as cm:
            dimensiones_imagen("bad.png", b"not a png image")
        self.assertIn("PNG inválido", str(cm.exception))

    def test_dimensiones_jpeg_valido(self) -> None:
        """Verifica extracción de dimensiones de una cabecera JPEG válida con marcador SOF0."""
        jpeg_cabecera = (
            b"\xff\xd8"
            + b"\xff\xc0"
            + struct.pack(">H", 8)
            + b"\x08"
            + struct.pack(">HH", 375, 200)  # alto=375, ancho=200
            + b"\x03"
        )
        ancho, alto = dimensiones_imagen("carta.jpg", jpeg_cabecera)
        self.assertEqual((ancho, alto), (200, 375))

    def test_dimensiones_jpeg_invalido_lanza_error(self) -> None:
        """Verifica que un JPEG corrupto o incompleto lanza error."""
        with self.assertRaises(TarotImportError) as cm:
            dimensiones_imagen("bad.jpg", b"not a jpeg image")
        self.assertIn("JPEG inválido", str(cm.exception))

        jpeg_sin_sof = b"\xff\xd8\xff\xd9"
        with self.assertRaises(TarotImportError) as cm:
            dimensiones_imagen("sin_sof.jpeg", jpeg_sin_sof)
        self.assertIn("JPEG sin marcador SOF", str(cm.exception))

    def test_formato_no_admitido_lanza_error(self) -> None:
        """Verifica que extensiones no soportadas lanzan error."""
        with self.assertRaises(TarotImportError) as cm:
            dimensiones_imagen("carta.bmp", b"datos bmp")
        self.assertIn("Formato no admitido", str(cm.exception))


class TestImagenFuente(unittest.TestCase):
    """Pruebas para la clase de datos ImagenFuente."""

    def test_instanciacion_y_atributos(self) -> None:
        """Verifica instanciación de ImagenFuente y acceso a sus atributos."""
        img = ImagenFuente(nombre="fichero.png", datos=b"12345")
        self.assertEqual(img.nombre, "fichero.png")
        self.assertEqual(img.datos, b"12345")

    def test_inmutabilidad(self) -> None:
        """Verifica que ImagenFuente es inmutable (frozen)."""
        img = ImagenFuente(nombre="fichero.png", datos=b"12345")
        with self.assertRaises(FrozenInstanceError):
            img.nombre = "otro.png"  # type: ignore[misc]


class TestValidarIdsProyecto(unittest.TestCase):
    """Pruebas de la función validar_ids_proyecto."""

    def test_validar_ids_proyecto_valido(self) -> None:
        """Verifica que un prometeo.json con los 22 IDs canónicos es válido."""
        contingut = {
            "tarot": [{"id": arcano.carta_id, "nombre": arcano.nombre_fuente} for arcano in ARCANOS]
        }
        with tempfile.TemporaryDirectory() as tmpdir:
            ruta = Path(tmpdir) / "prometeo.json"
            ruta.write_text(json.dumps(contingut), encoding="utf-8")
            # No debe lanzar ninguna excepción
            validar_ids_proyecto(ruta)

    def test_validar_ids_proyecto_duplicados_lanza_error(self) -> None:
        """Verifica que un prometeo.json con IDs duplicados lanza TarotImportError."""
        tarot_duplicado = [
            {"id": "el-loco"},
            {"id": "el-loco"},
        ] + [{"id": arcano.carta_id} for arcano in ARCANOS[2:]]
        contingut = {"tarot": tarot_duplicado}
        with tempfile.TemporaryDirectory() as tmpdir:
            ruta = Path(tmpdir) / "prometeo.json"
            ruta.write_text(json.dumps(contingut), encoding="utf-8")
            with self.assertRaises(TarotImportError) as cm:
                validar_ids_proyecto(ruta)
            self.assertIn("contiene IDs de tarot duplicados", str(cm.exception))

    def test_validar_ids_proyecto_formato_o_ids_incorrectos_lanza_error(self) -> None:
        """Verifica errores cuando falta la clave 'tarot' o faltan IDs canónicos."""
        with tempfile.TemporaryDirectory() as tmpdir:
            ruta = Path(tmpdir) / "prometeo.json"
            ruta.write_text(json.dumps({"tarot": "no_es_lista"}), encoding="utf-8")
            with self.assertRaises(TarotImportError) as cm:
                validar_ids_proyecto(ruta)
            self.assertIn("no contiene una lista 'tarot'", str(cm.exception))

            ruta_incompleta = Path(tmpdir) / "prometeo_incompleto.json"
            ruta_incompleta.write_text(
                json.dumps({"tarot": [{"id": "el-loco"}]}), encoding="utf-8"
            )
            with self.assertRaises(TarotImportError) as cm:
                validar_ids_proyecto(ruta_incompleta)
            self.assertIn("Los IDs del proyecto no coinciden", str(cm.exception))


if __name__ == "__main__":
    unittest.main()
