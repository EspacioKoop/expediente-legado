#!/usr/bin/env python3
"""Renderiza la señalética y el calendario de pared del archivo (#1468).

Tres láminas originales del proyecto, sin texto visible ni material de
terceros: salida de emergencia, extintor y calendario. Solo usa la biblioteca
estándar para que CI pueda regenerarlas sin dependencias y comparar píxel a
píxel con los binarios versionados.

Cada lámina se dibuja a resolución ×SUPER y se reduce por promedio de caja:
es el antialias más simple que sigue siendo exactamente reproducible.
"""
from __future__ import annotations

import argparse
import math
import struct
import zlib
from pathlib import Path

RGBA = tuple[int, int, int, int]
Punto = tuple[float, float]

SUPER = 4
DESTINO = Path(__file__).resolve().parents[1] / "godot/assets/texturas/senaletica_oficina_98"

BLANCO: RGBA = (244, 242, 232, 255)
VERDE: RGBA = (22, 128, 72, 255)
ROJO: RGBA = (196, 34, 40, 255)
PAPEL: RGBA = (232, 226, 206, 255)
TINTA: RGBA = (58, 56, 60, 255)
ANILLA: RGBA = (92, 94, 100, 255)
TRANSPARENTE: RGBA = (0, 0, 0, 0)


class Lienzo:
    """RGBA en coordenadas de la lámina final; dibuja a ×SUPER internamente."""

    def __init__(self, ancho: int, alto: int, fondo: RGBA = TRANSPARENTE) -> None:
        self.ancho = ancho
        self.alto = alto
        self._w = ancho * SUPER
        self._h = alto * SUPER
        self._px = bytearray(bytes(fondo) * (self._w * self._h))

    def _tramo(self, y: int, x0: float, x1: float, color: RGBA) -> None:
        inicio = max(0, math.ceil(x0 - 0.5))
        fin = min(self._w, math.ceil(x1 - 0.5))
        if 0 <= y < self._h and fin > inicio:
            i = (y * self._w + inicio) * 4
            self._px[i : i + (fin - inicio) * 4] = bytes(color) * (fin - inicio)

    def rect(self, x0: float, y0: float, x1: float, y1: float, color: RGBA) -> None:
        self.poligono([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], color)

    def poligono(self, puntos: list[Punto], color: RGBA) -> None:
        p = [(x * SUPER, y * SUPER) for x, y in puntos]
        ys = [y for _, y in p]
        for y in range(max(0, math.floor(min(ys))), min(self._h, math.ceil(max(ys)) + 1)):
            centro = y + 0.5
            cruces = []
            for i, (xa, ya) in enumerate(p):
                xb, yb = p[(i + 1) % len(p)]
                if (ya <= centro < yb) or (yb <= centro < ya):
                    cruces.append(xa + (centro - ya) * (xb - xa) / (yb - ya))
            cruces.sort()
            for a, b in zip(cruces[0::2], cruces[1::2]):
                self._tramo(y, a, b, color)

    def elipse(self, cx: float, cy: float, rx: float, ry: float, color: RGBA) -> None:
        cx, cy, rx, ry = cx * SUPER, cy * SUPER, rx * SUPER, ry * SUPER
        for y in range(max(0, math.floor(cy - ry)), min(self._h, math.ceil(cy + ry) + 1)):
            dy = (y + 0.5 - cy) / ry
            if abs(dy) <= 1.0:
                media = rx * math.sqrt(1.0 - dy * dy)
                self._tramo(y, cx - media, cx + media, color)

    def trazo(self, a: Punto, b: Punto, grosor: float, color: RGBA) -> None:
        """Segmento grueso con extremos redondeados."""
        dx, dy = b[0] - a[0], b[1] - a[1]
        largo = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / largo * grosor / 2, dx / largo * grosor / 2
        self.poligono(
            [(a[0] + nx, a[1] + ny), (b[0] + nx, b[1] + ny), (b[0] - nx, b[1] - ny), (a[0] - nx, a[1] - ny)],
            color,
        )
        for cx, cy in (a, b):
            self.elipse(cx, cy, grosor / 2, grosor / 2, color)

    def pixeles(self) -> bytes:
        """Reduce ×SUPER por promedio de caja con alfa premultiplicado."""
        salida = bytearray(self.ancho * self.alto * 4)
        n = SUPER * SUPER
        for y in range(self.alto):
            for x in range(self.ancho):
                r = g = b = a = 0
                for sy in range(SUPER):
                    i = ((y * SUPER + sy) * self._w + x * SUPER) * 4
                    for _ in range(SUPER):
                        pa = self._px[i + 3]
                        r += self._px[i] * pa
                        g += self._px[i + 1] * pa
                        b += self._px[i + 2] * pa
                        a += pa
                        i += 4
                o = (y * self.ancho + x) * 4
                if a:
                    salida[o : o + 4] = bytes((r // a, g // a, b // a, a // n))
        return bytes(salida)


def _placa(lienzo: Lienzo, fondo: RGBA) -> None:
    """Placa de chapa con cantos redondeados y filete blanco interior."""
    w, h = lienzo.ancho, lienzo.alto
    r = 6
    lienzo.rect(r, 0, w - r, h, fondo)
    lienzo.rect(0, r, w, h - r, fondo)
    for cx, cy in ((r, r), (w - r, r), (r, h - r), (w - r, h - r)):
        lienzo.elipse(cx, cy, r, r, fondo)
    m = 5
    for x0, y0, x1, y1 in ((m, m, w - m, m + 2), (m, h - m - 2, w - m, h - m), (m, m, m + 2, h - m), (w - m - 2, m, w - m, h - m)):
        lienzo.rect(x0, y0, x1, y1, BLANCO)


def salida_emergencia() -> Lienzo:
    """Figura que corre hacia una puerta, con flecha: la convención, no un texto."""
    c = Lienzo(256, 128)
    _placa(c, VERDE)
    # Puerta: marco blanco con hueco verde.
    c.rect(150, 22, 206, 106, BLANCO)
    c.rect(158, 30, 198, 106, VERDE)
    # Figura corriendo, cruzando el umbral.
    c.elipse(142, 34, 9, 9, BLANCO)
    c.trazo((136, 48), (124, 74), 12, BLANCO)
    c.trazo((136, 50), (156, 60), 7, BLANCO)
    c.trazo((136, 50), (116, 50), 7, BLANCO)
    c.trazo((124, 74), (146, 88), 8, BLANCO)
    c.trazo((146, 88), (140, 104), 8, BLANCO)
    c.trazo((124, 74), (110, 92), 8, BLANCO)
    c.trazo((110, 92), (94, 94), 8, BLANCO)
    # Flecha en el sentido de la marcha, detrás de la figura.
    c.rect(24, 58, 70, 70, BLANCO)
    c.poligono([(66, 42), (88, 64), (66, 86)], BLANCO)
    return c


def extintor() -> Lienzo:
    c = Lienzo(128, 160)
    _placa(c, ROJO)
    # Cuerpo del extintor con hombros redondeados.
    c.rect(46, 58, 82, 136, BLANCO)
    c.elipse(64, 58, 18, 12, BLANCO)
    c.elipse(64, 136, 18, 4, BLANCO)
    # Cuello, válvula y maneta.
    c.rect(59, 36, 69, 50, BLANCO)
    c.rect(52, 30, 84, 38, BLANCO)
    c.trazo((70, 32), (90, 24), 5, BLANCO)
    # Manguera que baja por el costado y boquilla.
    c.trazo((56, 34), (34, 44), 5, BLANCO)
    c.trazo((34, 44), (30, 92), 5, BLANCO)
    c.poligono([(25, 92), (35, 92), (37, 106), (23, 106)], BLANCO)
    # Etiqueta del cuerpo: banda roja sin texto.
    c.rect(50, 84, 78, 100, ROJO)
    return c


def calendario() -> Lienzo:
    """Hoja mensual sin mes ni cifras: no afirma una fecha del expediente."""
    c = Lienzo(160, 224)
    c.rect(4, 10, 156, 222, PAPEL)
    # Ilustración genérica del mes: cielo, sierra y campo.
    c.rect(12, 20, 148, 100, (138, 170, 196, 255))
    c.poligono([(12, 78), (46, 48), (70, 66), (104, 38), (148, 72), (148, 100), (12, 100)], (96, 112, 104, 255))
    c.poligono([(12, 88), (60, 76), (110, 84), (148, 80), (148, 100), (12, 100)], (132, 146, 84, 255))
    c.elipse(122, 36, 8, 8, (240, 222, 150, 255))
    # Banda de cabecera donde iría el mes, deliberadamente vacía.
    c.rect(12, 106, 148, 116, ROJO)
    # Rejilla 7×5 de días.
    x0, y0, celda_w, celda_h = 12, 122, 136 / 7, 92 / 5
    for i in range(8):
        x = x0 + i * celda_w
        c.rect(x - 0.5, y0, x + 0.5, y0 + 92, TINTA)
    for j in range(6):
        y = y0 + j * celda_h
        c.rect(x0, y - 0.5, x0 + 136, y + 0.5, TINTA)
    # Una marca pequeña por día en vez de cifras, y los ya pasados tachados.
    for dia in range(30):
        col, fila = (dia + 2) % 7, (dia + 2) // 7
        cx = x0 + col * celda_w + 5
        cy = y0 + fila * celda_h + 5
        if dia >= 17:
            c.rect(cx - 2, cy - 1, cx + 2, cy + 1, TINTA)
        else:
            gx, gy = x0 + col * celda_w, y0 + fila * celda_h
            c.trazo((gx + 4, gy + 4), (gx + celda_w - 4, gy + celda_h - 4), 1.6, ROJO)
            c.trazo((gx + celda_w - 4, gy + 4), (gx + 4, gy + celda_h - 4), 1.6, ROJO)
    # Espiral de anillas.
    for i in range(9):
        c.elipse(20 + i * 15, 12, 3, 6, ANILLA)
    return c


LAMINAS = {
    "salida_emergencia_98.png": salida_emergencia,
    "extintor_98.png": extintor,
    "calendario_pared_98.png": calendario,
}


def _fragmento(tipo: bytes, datos: bytes) -> bytes:
    crc = zlib.crc32(tipo + datos) & 0xFFFFFFFF
    return struct.pack(">I", len(datos)) + tipo + datos + struct.pack(">I", crc)


def png(ancho: int, alto: int, rgba: bytes) -> bytes:
    """PNG RGBA de 8 bits, filtro 0 en todas las filas para decodificarlo sin Pillow."""
    fila = ancho * 4
    bruto = b"".join(b"\x00" + rgba[y * fila : (y + 1) * fila] for y in range(alto))
    cabecera = struct.pack(">IIBBBBB", ancho, alto, 8, 6, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + _fragmento(b"IHDR", cabecera)
        + _fragmento(b"IDAT", zlib.compress(bruto, 9))
        + _fragmento(b"IEND", b"")
    )


def leer_png(datos: bytes) -> tuple[int, int, bytes]:
    """Lee solo el PNG que produce `png()`: RGBA 8 bits sin entrelazado, filtro 0."""
    assert datos[:8] == b"\x89PNG\r\n\x1a\n"
    cursor, idat, ancho, alto = 8, b"", 0, 0
    while cursor < len(datos):
        largo = struct.unpack(">I", datos[cursor : cursor + 4])[0]
        tipo = datos[cursor + 4 : cursor + 8]
        cuerpo = datos[cursor + 8 : cursor + 8 + largo]
        if tipo == b"IHDR":
            ancho, alto = struct.unpack(">II", cuerpo[:8])
            assert cuerpo[8:] == b"\x08\x06\x00\x00\x00", "formato inesperado"
        elif tipo == b"IDAT":
            idat += cuerpo
        cursor += 12 + largo
    bruto = zlib.decompress(idat)
    fila = ancho * 4
    salida = bytearray()
    for y in range(alto):
        inicio = y * (fila + 1)
        assert bruto[inicio] == 0, "solo se admite filtro 0"
        salida += bruto[inicio + 1 : inicio + 1 + fila]
    return ancho, alto, bytes(salida)


def renderizar(nombre: str) -> tuple[int, int, bytes]:
    lienzo = LAMINAS[nombre]()
    return lienzo.ancho, lienzo.alto, lienzo.pixeles()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destino", type=Path, default=DESTINO)
    destino = parser.parse_args().destino
    destino.mkdir(parents=True, exist_ok=True)
    for nombre in LAMINAS:
        ruta = destino / nombre
        ruta.write_bytes(png(*renderizar(nombre)))
        print(ruta)


if __name__ == "__main__":
    main()
