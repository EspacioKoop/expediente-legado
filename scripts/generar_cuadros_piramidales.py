#!/usr/bin/env python3
"""Renderiza tres láminas piramidales originales y reproducibles para #195."""
from __future__ import annotations

import argparse
import json
import math
import random
import struct
import zlib
from pathlib import Path

RGB = tuple[int, int, int]


def _color(valor: str) -> RGB:
    valor = valor.lstrip("#")
    return tuple(int(valor[i : i + 2], 16) for i in (0, 2, 4))


class Lienzo:
    def __init__(self, ancho: int, alto: int, fondo: RGB) -> None:
        self.ancho = ancho
        self.alto = alto
        self.pixeles = bytearray(fondo * (ancho * alto))

    def punto(self, x: int, y: int, color: RGB) -> None:
        if 0 <= x < self.ancho and 0 <= y < self.alto:
            indice = (y * self.ancho + x) * 3
            self.pixeles[indice : indice + 3] = bytes(color)

    def rectangulo(self, x0: float, y0: float, x1: float, y1: float, color: RGB) -> None:
        inicio_x = max(0, int(x0))
        inicio_y = max(0, int(y0))
        fin_x = min(self.ancho, int(x1))
        fin_y = min(self.alto, int(y1))
        if fin_x <= inicio_x or fin_y <= inicio_y:
            return
        fila = bytes(color) * (fin_x - inicio_x)
        for y in range(inicio_y, fin_y):
            indice = (y * self.ancho + inicio_x) * 3
            self.pixeles[indice : indice + len(fila)] = fila

    def elipse(self, cx: float, cy: float, rx: float, ry: float, color: RGB) -> None:
        inicio_y = max(0, int(cy - ry))
        fin_y = min(self.alto, int(cy + ry) + 1)
        for y in range(inicio_y, fin_y):
            dy = (y - cy) / max(ry, 1e-9)
            tramo = rx * math.sqrt(max(0.0, 1.0 - dy * dy))
            self.rectangulo(cx - tramo, y, cx + tramo + 1, y + 1, color)

    def poligono(self, puntos: list[tuple[float, float]], color: RGB) -> None:
        ys = [punto[1] for punto in puntos]
        inicio_y = max(0, math.floor(min(ys)))
        fin_y = min(self.alto - 1, math.ceil(max(ys)))
        for y in range(inicio_y, fin_y + 1):
            barrido = y + 0.5
            cruces: list[float] = []
            for indice, (x1, y1) in enumerate(puntos):
                x2, y2 = puntos[(indice + 1) % len(puntos)]
                if (y1 <= barrido < y2) or (y2 <= barrido < y1):
                    factor = (barrido - y1) / (y2 - y1)
                    cruces.append(x1 + factor * (x2 - x1))
            cruces.sort()
            for x0, x1 in zip(cruces[0::2], cruces[1::2]):
                self.rectangulo(math.ceil(x0), y, math.floor(x1) + 1, y + 1, color)

    def linea(
        self,
        x0: float,
        y0: float,
        x1: float,
        y1: float,
        color: RGB,
        grosor: int = 1,
    ) -> None:
        dx = x1 - x0
        dy = y1 - y0
        pasos = max(abs(dx), abs(dy), 1)
        radio = max(0, grosor // 2)
        for paso in range(int(pasos) + 1):
            factor = paso / pasos
            x = round(x0 + dx * factor)
            y = round(y0 + dy * factor)
            self.rectangulo(
                x - radio,
                y - radio,
                x + radio + 1,
                y + radio + 1,
                color,
            )


def _grano(
    lienzo: Lienzo,
    rng: random.Random,
    paleta: list[RGB],
    cantidad: int = 3500,
) -> None:
    for _ in range(cantidad):
        x = rng.randrange(lienzo.ancho)
        y = rng.randrange(lienzo.alto)
        if rng.random() >= 0.75:
            continue
        color = paleta[rng.randrange(len(paleta))]
        indice = (y * lienzo.ancho + x) * 3
        anterior = tuple(lienzo.pixeles[indice + canal] for canal in range(3))
        alfa = 0.10 + rng.random() * 0.08
        mezclado = tuple(
            round(anterior[canal] * (1.0 - alfa) + color[canal] * alfa)
            for canal in range(3)
        )
        lienzo.punto(x, y, mezclado)


def _horizonte(lienzo: Lienzo, paleta: dict[str, RGB]) -> None:
    ancho = lienzo.ancho
    alto = lienzo.alto
    lienzo.rectangulo(6, int(alto * 0.58), ancho - 6, alto - 6, paleta["arena"])
    lienzo.elipse(int(ancho * 0.78), int(alto * 0.24), 24, 24, paleta["acento"])
    piramides = [
        ([(35, 150), (94, 70), (153, 150)], paleta["sombra"]),
        ([(110, 155), (174, 83), (238, 155)], paleta["tinta"]),
        ([(205, 157), (252, 103), (301, 157)], paleta["sombra"]),
    ]
    for puntos, color in piramides:
        lienzo.poligono(puntos, color)
    lienzo.poligono([(94, 70), (94, 150), (153, 150)], paleta["arena_clara"])
    lienzo.poligono([(174, 83), (174, 155), (238, 155)], paleta["arena_clara"])
    lienzo.poligono([(252, 103), (252, 157), (301, 157)], paleta["arena_clara"])
    for y in range(168, 210, 10):
        lienzo.linea(18, y, ancho - 18, y, paleta["linea"])


def _seccion(lienzo: Lienzo, paleta: dict[str, RGB]) -> None:
    ancho = lienzo.ancho
    alto = lienzo.alto
    for x in range(26, ancho - 20, 24):
        lienzo.linea(x, 20, x, alto - 20, paleta["linea"])
    for y in range(22, alto - 18, 22):
        lienzo.linea(20, y, ancho - 20, y, paleta["linea"])
    lienzo.poligono([(54, 181), (160, 43), (266, 181)], paleta["tinta"])
    lienzo.poligono([(160, 43), (160, 181), (266, 181)], paleta["sombra"])
    for desplazamiento in (24, 44, 64):
        y = 181 - desplazamiento
        mitad = (181 - y) * 106 / (181 - 43)
        lienzo.linea(160 - mitad, y, 160 + mitad, y, paleta["acento"], 2)
    lienzo.elipse(160, 111, 10, 10, paleta["papel"])
    lienzo.linea(40, 198, 280, 198, paleta["acento"], 2)
    lienzo.linea(74, 192, 74, 205, paleta["acento"], 2)
    lienzo.linea(246, 192, 246, 205, paleta["acento"], 2)


def _constelacion(
    lienzo: Lienzo,
    paleta: dict[str, RGB],
    rng: random.Random,
) -> None:
    ancho = lienzo.ancho
    alto = lienzo.alto
    lienzo.rectangulo(6, 6, ancho - 6, alto - 6, paleta["noche"])
    for _ in range(80):
        x = rng.randrange(18, ancho - 18)
        y = rng.randrange(15, int(alto * 0.62))
        color = rng.choice((paleta["estrella"], paleta["linea"], paleta["papel"]))
        lado = 1 if rng.random() < 0.8 else 2
        lienzo.rectangulo(x, y, x + lado, y + lado, color)
    lienzo.poligono([(45, 187), (160, 54), (275, 187)], paleta["sombra"])
    lienzo.poligono([(160, 54), (160, 187), (275, 187)], paleta["tinta"])
    triangulo = [(92, 72), (160, 28), (229, 76), (92, 72)]
    for origen, destino in zip(triangulo, triangulo[1:]):
        lienzo.linea(*origen, *destino, paleta["acento"])
    for x, y in triangulo[:-1]:
        lienzo.elipse(x, y, 3, 3, paleta["estrella"])
    for y in range(194, 214, 5):
        lienzo.linea(22, y, ancho - 22, y, paleta["linea"])


MOTIVOS = {
    "horizonte": _horizonte,
    "seccion": _seccion,
}


def _zlib_sin_compresion(datos: bytes) -> bytes:
    """Codifica DEFLATE en bloques almacenados para obtener bytes reproducibles."""
    salida = bytearray(b"\x78\x01")
    cursor = 0
    while cursor < len(datos):
        bloque = datos[cursor : cursor + 65535]
        cursor += len(bloque)
        final = 1 if cursor >= len(datos) else 0
        salida.append(final)
        longitud = len(bloque)
        salida.extend(struct.pack("<HH", longitud, 0xFFFF - longitud))
        salida.extend(bloque)
    salida.extend(struct.pack(">I", zlib.adler32(datos) & 0xFFFFFFFF))
    return bytes(salida)


def _fragmento_png(tipo: bytes, datos: bytes) -> bytes:
    crc = zlib.crc32(tipo + datos) & 0xFFFFFFFF
    return struct.pack(">I", len(datos)) + tipo + datos + struct.pack(">I", crc)


def _png(lienzo: Lienzo) -> bytes:
    bruto = bytearray()
    salto = lienzo.ancho * 3
    for y in range(lienzo.alto):
        bruto.append(0)
        bruto.extend(lienzo.pixeles[y * salto : (y + 1) * salto])
    cabecera = struct.pack(">IIBBBBB", lienzo.ancho, lienzo.alto, 8, 2, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + _fragmento_png(b"IHDR", cabecera)
        + _fragmento_png(b"IDAT", _zlib_sin_compresion(bytes(bruto)))
        + _fragmento_png(b"IEND", b"")
    )


def renderizar_especificacion(configuracion: dict) -> bytes:
    ancho = int(configuracion["ancho"])
    alto = int(configuracion["alto"])
    rng = random.Random(int(configuracion["semilla"]))
    paleta = {
        nombre: _color(valor)
        for nombre, valor in configuracion["paleta"].items()
    }
    lienzo = Lienzo(ancho, alto, paleta["papel"])
    lienzo.rectangulo(0, 0, ancho, 6, paleta["tinta"])
    lienzo.rectangulo(0, alto - 6, ancho, alto, paleta["tinta"])
    lienzo.rectangulo(0, 0, 6, alto, paleta["tinta"])
    lienzo.rectangulo(ancho - 6, 0, ancho, alto, paleta["tinta"])

    motivo = configuracion["motivo"]
    if motivo == "constelacion":
        _constelacion(lienzo, paleta, rng)
    else:
        MOTIVOS[motivo](lienzo, paleta)
    _grano(
        lienzo,
        rng,
        [paleta["tinta"], paleta["linea"], paleta.get("arena", paleta["papel"])],
    )
    return _png(lienzo)


def cargar_especificaciones(origen: Path) -> list[dict]:
    return [
        json.loads(ruta.read_text(encoding="utf-8"))
        for ruta in sorted(origen.glob("*.json"))
    ]


def renderizar(origen: Path, destino: Path) -> list[Path]:
    destino.mkdir(parents=True, exist_ok=True)
    salidas: list[Path] = []
    for configuracion in cargar_especificaciones(origen):
        ruta = destino / configuracion["salida"]
        ruta.write_bytes(renderizar_especificacion(configuracion))
        salidas.append(ruta)
    return salidas


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--origen",
        type=Path,
        default=Path("referencia/arte/cuadros_piramidales"),
    )
    parser.add_argument(
        "--destino",
        type=Path,
        default=Path("build/cuadros_piramidales"),
    )
    argumentos = parser.parse_args()
    for ruta in renderizar(argumentos.origen, argumentos.destino):
        print(ruta)


if __name__ == "__main__":
    main()
