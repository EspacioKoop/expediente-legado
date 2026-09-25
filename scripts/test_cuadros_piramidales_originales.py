#!/usr/bin/env python3
"""Regresión de las fuentes originales de cuadros piramidales de #195."""
from __future__ import annotations

import hashlib
import json
import struct
import sys
import tempfile
import unittest
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
SCRIPTS = RAIZ / "scripts"
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

import generar_cuadros_piramidales as generador  # noqa: E402

ORIGEN = RAIZ / "referencia" / "arte" / "cuadros_piramidales"
CONSUMIDOR = RAIZ / "godot" / "guion" / "cuadros_oficina.gd"
NOMBRES = {
    "cuadro-piramide-01.png",
    "cuadro-piramide-02.png",
    "cuadro-piramide-03.png",
}


class CuadrosPiramidalesOriginalesTest(unittest.TestCase):
    def especificaciones(self) -> list[dict]:
        return [
            json.loads(ruta.read_text(encoding="utf-8"))
            for ruta in sorted(ORIGEN.glob("*.json"))
        ]

    def test_hay_tres_laminas_cc0_independientes(self) -> None:
        especificaciones = self.especificaciones()
        self.assertEqual(3, len(especificaciones))
        self.assertEqual(NOMBRES, {item["salida"] for item in especificaciones})
        self.assertEqual(3, len({item["semilla"] for item in especificaciones}))
        self.assertEqual(3, len({item["motivo"] for item in especificaciones}))
        for item in especificaciones:
            self.assertEqual("CC0-1.0", item["licencia"])
            self.assertEqual("Expediente Legado", item["autor"])
            self.assertEqual("docs/assets/cuadros-piramidales-originales.md", item["fuente"])
            self.assertRegex(item["sha256"], r"^[0-9a-f]{64}$")

    def test_render_es_reproducible_y_coincide_con_hash_catalogado(self) -> None:
        with tempfile.TemporaryDirectory(prefix="siga98-cuadros-") as temporal:
            destino = Path(temporal)
            salidas = generador.renderizar(ORIGEN, destino)
            self.assertEqual(NOMBRES, {ruta.name for ruta in salidas})
            por_nombre = {item["salida"]: item for item in self.especificaciones()}
            for ruta in salidas:
                datos = ruta.read_bytes()
                esperado = por_nombre[ruta.name]
                self.assertEqual(esperado["sha256"], hashlib.sha256(datos).hexdigest())
                self.assertTrue(datos.startswith(b"\x89PNG\r\n\x1a\n"))
                ancho, alto = struct.unpack(">II", datos[16:24])
                self.assertEqual((320, 224), (ancho, alto))

    def test_nombres_coinciden_con_el_consumidor_runtime(self) -> None:
        codigo = CONSUMIDOR.read_text(encoding="utf-8")
        for nombre in NOMBRES:
            self.assertIn(f'"textura": "{nombre}"', codigo)

    def test_salidas_son_distintas(self) -> None:
        hashes = {
            item["sha256"]
            for item in self.especificaciones()
        }
        self.assertEqual(3, len(hashes))


if __name__ == "__main__":
    unittest.main()
