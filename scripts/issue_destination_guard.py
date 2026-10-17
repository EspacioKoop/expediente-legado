#!/usr/bin/env python3
"""Límite de publicación: los creadores automáticos solo abren issues del juego.

No es un sanitizador: ante indicios de datos operativos privados se rechaza
toda la operación. No imprimir el texto recibido ni rutas privadas en errores.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys

PUBLIC_REPO = "espaciokoop/expediente-legado"
MAX_TITLE = 200
MAX_BODY = 16_000

# Pistas específicas de operación privada. No bloquear "Hermes" a secas:
# puede ser contenido mitológico legítimo del videojuego.
PRIVATE = (
    re.compile(r"\b(?:infra[-_ ]casa|omniroute|tailscale|wireguard|homelab|home[- ]lab)\b", re.I),
    re.compile(r"\b(?:beelink|locomotora|leviat[aá]n)\b", re.I),
    re.compile(r"\bhermes[-_ ](?:gateway|router|mcp|provider|proveedor|dispatcher|bridge)\b", re.I),
    re.compile(r"\b(?:mistral[-_ ]paid|mistral de pago|quota[-_ ]domain|provider[-_ ]routing)\b", re.I),
    re.compile(r"\b(?:cuotas? de (?:tokens|modelo|modelos|proveedores|IA)|capacidad de proveedores)\b", re.I),
    re.compile(r"(?:\b|_)(?:api[_ -]?key|auth[_ -]?token|password|private[_ -]?key)\s*[:=]", re.I),
    re.compile(r"(?:/home/[A-Za-z0-9._-]+/|/Users/[A-Za-z0-9._-]+/|[A-Z]:\\Users\\)", re.I),
    re.compile(r"\b(?:192\.168|10\.(?:\d{1,3}\.){2}|172\.(?:1[6-9]|2\d|3[01])\.|100\.(?:6[4-9]|[789]\d|1[01]\d|12[0-7])\.)"),
    re.compile(r"\bagent\s*\(\s*[a-z][a-z0-9_-]*\s*\)", re.I),
)
TITLE_PRIVATE = re.compile(r"^(?:P[0-3]\s*[|:–-]\s*)?(?:infra|infraestructura)\s*[:( /-]", re.I)


def permitir_issue(repo: str, titulo: str, cuerpo: str) -> bool:
    if not all(isinstance(x, str) for x in (repo, titulo, cuerpo)):
        return False
    if repo.casefold() != PUBLIC_REPO or not 5 <= len(titulo.strip()) <= MAX_TITLE:
        return False
    if not cuerpo.strip() or len(cuerpo.encode("utf-8")) > MAX_BODY:
        return False
    if TITLE_PRIVATE.search(titulo):
        return False
    combinado = titulo + "\n" + cuerpo
    return not any(patron.search(combinado) for patron in PRIVATE)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--body-file", required=True, type=Path)
    args = parser.parse_args()
    try:
        if args.body_file.is_symlink() or args.body_file.stat().st_size > MAX_BODY * 4:
            raise ValueError("invalid input")
        cuerpo = args.body_file.read_text(encoding="utf-8")
        if permitir_issue(args.repo, args.title, cuerpo):
            return 0
    except (OSError, UnicodeError, ValueError):
        pass
    print("Publicación rechazada: solo tareas del juego sin datos operativos privados.", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
