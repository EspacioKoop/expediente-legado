#!/usr/bin/env python3
"""Configura Sentry en project.godot durante el empaquetado de una alpha.

No guarda credenciales en el repositorio: el fichero se modifica únicamente en
el checkout efímero del build (o explícitamente en local).
"""

from __future__ import annotations

import argparse
from pathlib import Path
from urllib.parse import urlsplit


CLAVES = (
    "options/auto_init",
    "options/dsn",
    "options/release",
    "options/environment",
    "options/dist",
    "options/tracing/traces_sample_rate",
)


def _literal(valor: str) -> str:
    return '"' + valor.replace("\\", "\\\\").replace('"', '\\"') + '"'


def _validar_dsn(dsn: str) -> None:
    partes = urlsplit(dsn)
    if partes.scheme != "https" or not partes.netloc:
        raise ValueError("SENTRY_DSN debe ser una URL HTTPS válida")


def configurar_proyecto(
    texto: str,
    *,
    dsn: str,
    release: str,
    environment: str,
    dist: str,
) -> str:
    _validar_dsn(dsn)
    if not release.strip():
        raise ValueError("release no puede estar vacío")
    if not environment.strip():
        raise ValueError("environment no puede estar vacío")

    valores = {
        "options/auto_init": "true",
        "options/dsn": _literal(dsn.strip()),
        "options/release": _literal(release.strip()),
        "options/environment": _literal(environment.strip()),
        "options/dist": _literal(dist.strip()),
        # El primer corte captura errores/crashes; performance queda apagado
        # hasta medir el coste y decidir una tasa explícita.
        "options/tracing/traces_sample_rate": "0.0",
    }

    lineas = texto.splitlines()
    inicio = None
    fin = len(lineas)
    for indice, linea in enumerate(lineas):
        if linea.strip() == "[sentry]":
            inicio = indice
            for siguiente in range(indice + 1, len(lineas)):
                if lineas[siguiente].startswith("[") and lineas[siguiente].endswith("]"):
                    fin = siguiente
                    break
            break

    if inicio is None:
        if lineas and lineas[-1].strip():
            lineas.append("")
        lineas.extend(["[sentry]", ""])
        inicio = len(lineas) - 2
        fin = len(lineas)

    bloque = lineas[inicio + 1 : fin]
    conservadas = [
        linea
        for linea in bloque
        if not any(linea.startswith(clave + "=") for clave in CLAVES)
    ]
    while conservadas and not conservadas[-1].strip():
        conservadas.pop()

    nuevas = [f"{clave}={valores[clave]}" for clave in CLAVES]
    reemplazo = conservadas + ([""] if conservadas else []) + nuevas
    lineas[inicio + 1 : fin] = reemplazo
    return "\n".join(lineas).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--dsn", required=True)
    parser.add_argument("--release", required=True)
    parser.add_argument("--environment", default="alpha")
    parser.add_argument("--dist", default="")
    args = parser.parse_args()

    original = args.project.read_text(encoding="utf-8")
    configurado = configurar_proyecto(
        original,
        dsn=args.dsn,
        release=args.release,
        environment=args.environment,
        dist=args.dist,
    )
    args.project.write_text(configurado, encoding="utf-8")
    print(
        f"Sentry activado para {args.environment}: "
        f"release={args.release} dist={args.dist or '-'}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
