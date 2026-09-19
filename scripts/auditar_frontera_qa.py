#!/usr/bin/env python3
"""#116: demuestra la frontera debug/** sobre el artefacto exportado."""

from pathlib import Path
import argparse
import sys


MARCADOR = b"qa_export_marker_116"


def contiene_marcador(ruta: Path) -> bool:
    return MARCADOR in ruta.read_bytes().lower()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("modo", choices=("qa", "publico"))
    parser.add_argument("artefactos", nargs="+", type=Path)
    args = parser.parse_args()

    esperado = args.modo == "qa"
    fallos = []
    for artefacto in args.artefactos:
        if not artefacto.is_file():
            fallos.append(f"no existe: {artefacto}")
            continue
        presente = contiene_marcador(artefacto)
        estado = "presente" if presente else "ausente"
        print(f"{artefacto}: marcador QA {estado}")
        if presente != esperado:
            verbo = "contener" if esperado else "excluir"
            fallos.append(f"{artefacto} debería {verbo} el marcador QA")

    if fallos:
        for fallo in fallos:
            print(f"ERROR: {fallo}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
