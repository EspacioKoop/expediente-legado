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
from godot_pruebas import comprobar_contrato  # noqa: E402

ORIGEN = RAIZ / "referencia" / "arte" / "cuadros_piramidales"
CONSUMIDOR = RAIZ / "godot" / "guion" / "cuadros_oficina.gd"
TEXTURAS = RAIZ / "godot" / "assets" / "texturas"
PROCEDENCIA = RAIZ / "godot" / "assets" / "procedencia.json"
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

    def test_runtime_usa_exactamente_el_render_catalogado(self) -> None:
        # El PNG versionado por LFS es la salida del generador sin retoques: si
        # alguien lo reexporta desde un editor, el hash deja de coincidir.
        for item in self.especificaciones():
            ruta = TEXTURAS / item["salida"]
            datos = ruta.read_bytes()
            self.assertFalse(
                datos.startswith(b"version https://git-lfs"),
                f"{ruta.name} es un puntero LFS sin objeto; falta git lfs pull",
            )
            self.assertEqual(item["sha256"], hashlib.sha256(datos).hexdigest())

    def test_procedencia_registra_cada_lamina_con_su_receta(self) -> None:
        fichas = {
            ficha["ruta"]: ficha
            for ficha in json.loads(PROCEDENCIA.read_text(encoding="utf-8"))["assets"]
        }
        for item in self.especificaciones():
            ficha = fichas.get(f"texturas/{item['salida']}")
            self.assertIsNotNone(ficha, item["salida"])
            self.assertEqual(item["sha256"], ficha["sha256"])
            self.assertEqual(item["licencia"], ficha["licencia"])
            self.assertEqual(item["autor"], ficha["autor"])
            self.assertEqual("generado_por_script", ficha["origen"])
            self.assertTrue((RAIZ / ficha["receta"]).is_file(), ficha["receta"])
            self.assertTrue((RAIZ / ficha["generador"]).is_file(), ficha["generador"])

    def test_marcos_de_la_oficina_montan_las_laminas(self) -> None:
        comprobar_contrato(
            self,
            "pruebas/pruebas_cuadros_oficina_195.gd",
            "18 pasadas, 0 fallos",
        )

    def test_salidas_son_distintas(self) -> None:
        hashes = {
            item["sha256"]
            for item in self.especificaciones()
        }
        self.assertEqual(3, len(hashes))


if __name__ == "__main__":
    unittest.main()
