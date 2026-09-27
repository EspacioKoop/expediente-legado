#!/usr/bin/env python3
"""Genera la señalética propia de oficina para #1468.

Los SVG son deliberadamente no semánticos: pictogramas y rejilla, sin texto,
fechas, nombres ni datos de expedientes. El script es la fuente reproducible.
"""

from __future__ import annotations

import argparse
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot" / "arte" / "oficina_1468"

ARCHIVOS = {
    "salida_emergencia.svg": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"320\" height=\"160\" viewBox=\"0 0 320 160\">\n  <rect width=\"320\" height=\"160\" rx=\"12\" fill=\"#16784a\"/>\n  <rect x=\"218\" y=\"28\" width=\"58\" height=\"104\" rx=\"3\" fill=\"none\" stroke=\"#f3f4e8\" stroke-width=\"10\"/>\n  <circle cx=\"118\" cy=\"49\" r=\"13\" fill=\"#f3f4e8\"/>\n  <path d=\"M111 65 L139 74 L157 98\" fill=\"none\" stroke=\"#f3f4e8\" stroke-width=\"11\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>\n  <path d=\"M126 72 L104 94 L83 92\" fill=\"none\" stroke=\"#f3f4e8\" stroke-width=\"11\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>\n  <path d=\"M139 76 L126 111 L101 132\" fill=\"none\" stroke=\"#f3f4e8\" stroke-width=\"11\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>\n  <path d=\"M128 109 L158 127\" fill=\"none\" stroke=\"#f3f4e8\" stroke-width=\"11\" stroke-linecap=\"round\"/>\n  <path d=\"M53 80 H94 M53 80 L72 61 M53 80 L72 99\" fill=\"none\" stroke=\"#f3f4e8\" stroke-width=\"10\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>\n</svg>\n",
    "extintor.svg": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"240\" height=\"300\" viewBox=\"0 0 240 300\">\n  <rect width=\"240\" height=\"300\" rx=\"12\" fill=\"#a52f2f\"/>\n  <rect x=\"79\" y=\"95\" width=\"82\" height=\"132\" rx=\"25\" fill=\"#f5eee4\"/>\n  <rect x=\"99\" y=\"69\" width=\"42\" height=\"32\" rx=\"5\" fill=\"#f5eee4\"/>\n  <path d=\"M120 68 V47 H155\" fill=\"none\" stroke=\"#f5eee4\" stroke-width=\"10\" stroke-linecap=\"round\"/>\n  <path d=\"M157 47 C190 51 194 84 179 114 C168 136 182 160 195 170\" fill=\"none\" stroke=\"#f5eee4\" stroke-width=\"9\" stroke-linecap=\"round\"/>\n  <path d=\"M191 163 L207 182\" fill=\"none\" stroke=\"#f5eee4\" stroke-width=\"11\" stroke-linecap=\"round\"/>\n  <path d=\"M103 113 H137 M103 139 H137 M103 165 H137\" fill=\"none\" stroke=\"#a52f2f\" stroke-width=\"9\" stroke-linecap=\"round\"/>\n  <rect x=\"67\" y=\"226\" width=\"106\" height=\"18\" rx=\"5\" fill=\"#f5eee4\"/>\n</svg>\n",
    "calendario.svg": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"360\" height=\"480\" viewBox=\"0 0 360 480\">\n  <rect x=\"10\" y=\"10\" width=\"340\" height=\"460\" rx=\"8\" fill=\"#e8e1cf\" stroke=\"#5b5b55\" stroke-width=\"8\"/>\n  <rect x=\"10\" y=\"10\" width=\"340\" height=\"76\" rx=\"8\" fill=\"#b8b19e\"/>\n  <path d=\"M62 18 V52 M118 18 V52 M174 18 V52 M230 18 V52 M286 18 V52\" stroke=\"#40403d\" stroke-width=\"9\" stroke-linecap=\"round\"/>\n  <path d=\"M35 112 H325 M35 166 H325 M35 220 H325 M35 274 H325 M35 328 H325 M35 382 H325 M35 436 H325\" stroke=\"#858172\" stroke-width=\"4\"/>\n  <path d=\"M76 112 V436 M117 112 V436 M158 112 V436 M199 112 V436 M240 112 V436 M281 112 V436\" stroke=\"#858172\" stroke-width=\"4\"/>\n  <path d=\"M86 182 L107 204 M107 182 L86 204\" stroke=\"#93453d\" stroke-width=\"7\" stroke-linecap=\"round\"/>\n  <path d=\"M210 290 L232 314 M232 290 L210 314\" stroke=\"#93453d\" stroke-width=\"7\" stroke-linecap=\"round\"/>\n  <path d=\"M45 400 L66 422 M66 400 L45 422\" stroke=\"#93453d\" stroke-width=\"7\" stroke-linecap=\"round\"/>\n</svg>\n",
}


def generar(destino: Path = OUT) -> None:
    destino.mkdir(parents=True, exist_ok=True)
    for nombre, contenido in ARCHIVOS.items():
        (destino / nombre).write_text(contenido, encoding="utf-8")


def comprobar(destino: Path = OUT) -> bool:
    for nombre, contenido in ARCHIVOS.items():
        ruta = destino / nombre
        if not ruta.is_file() or ruta.read_text(encoding="utf-8") != contenido:
            return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="falla si los SVG versionados no coinciden con la receta",
    )
    args = parser.parse_args()
    if args.check:
        return 0 if comprobar() else 1
    generar()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
