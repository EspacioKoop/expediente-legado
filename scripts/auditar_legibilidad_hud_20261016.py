#!/usr/bin/env python3
"""Auditor estático offline de legibilidad HUD 1920x1080 (#20261016).

Analiza archivos Godot (.tscn, .tres) para detectar:
1. Tamaños de fuente por debajo del umbral mínimo recomendado para 1920x1080 (default < 14px).
2. Theme overrides declarados en controles HUD y recursos UI (theme_override_*).
3. Opacidad reducida declarada mediante componentes alpha en Color(...) (< min_alpha, default < 1.0).

Nota: Este script realiza análisis estático offline de ficheros de escena/recurso.
No afirma contraste visual final en renderizado ni modifica escenas, cinemáticas o fuentes.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
import sys
from typing import Any

# Regex para cabeceras de nodos y recursos
RE_HEADER_NODE = re.compile(
    r'^\[node\s+name="(?P<name>[^"]+)"(?:\s+type="(?P<type>[^"]+)")?'
)
RE_HEADER_SUB_RESOURCE = re.compile(
    r'^\[sub_resource\s+type="(?P<type>[^"]+)"\s+id="(?P<id>[^"]+)"'
)
RE_HEADER_RESOURCE = re.compile(r"^\[resource\]")

# Regex para propiedades de legibilidad
RE_FONT_SIZE = re.compile(
    r"(?P<prop>(?:theme_override_font_sizes/[a-zA-Z0-9_]+|[a-zA-Z0-9_]*font_size))\s*=\s*(?P<val>\d+)"
)
RE_THEME_OVERRIDE = re.compile(
    r"(?P<prop>theme_override_[a-zA-Z0-9_]+/[a-zA-Z0-9_]+)\s*="
)
RE_COLOR_VAL = re.compile(
    r"(?P<prop>[a-zA-Z0-9_/]+)\s*=\s*Color\s*\(\s*(?P<args>[^)]+)\s*\)"
)


def auditar_archivo(
    ruta: Path,
    min_font_size: int = 14,
    min_alpha: float = 1.0,
) -> list[dict[str, Any]]:
    """Audita un único archivo .tscn o .tres y devuelve la lista de hallazgos."""
    try:
        contenido = ruta.read_text(encoding="utf-8")
    except Exception as exc:
        return [
            {
                "path": str(ruta),
                "linea": 0,
                "nodo": "archivo",
                "tipo_nodo": "desconocido",
                "tipo_hallazgo": "error_lectura",
                "propiedad": "",
                "valor": None,
                "linea_texto": "",
                "detalles": f"No se pudo leer el archivo: {exc}",
            }
        ]

    hallazgos: list[dict[str, Any]] = []
    lineas = contenido.splitlines()

    current_node_name = "global"
    current_node_type = "Resource"

    for idx, raw_line in enumerate(lineas, start=1):
        line = raw_line.strip()

        # Actualizar contexto de sección
        if line.startswith("["):
            m_node = RE_HEADER_NODE.match(line)
            if m_node:
                current_node_name = m_node.group("name")
                current_node_type = m_node.group("type") or "Node"
                continue

            m_sub = RE_HEADER_SUB_RESOURCE.match(line)
            if m_sub:
                current_node_name = f"sub_resource_{m_sub.group('id')}"
                current_node_type = m_sub.group("type")
                continue

            if RE_HEADER_RESOURCE.match(line):
                current_node_name = "resource"
                current_node_type = "Resource"
                continue

        # 1. Detección de font_size
        m_font = RE_FONT_SIZE.search(line)
        if m_font:
            prop = m_font.group("prop")
            val = int(m_font.group("val"))
            if val < min_font_size:
                hallazgos.append(
                    {
                        "path": str(ruta),
                        "linea": idx,
                        "nodo": current_node_name,
                        "tipo_nodo": current_node_type,
                        "tipo_hallazgo": "tamanio_fuente_pequenio",
                        "propiedad": prop,
                        "valor": val,
                        "linea_texto": line,
                        "detalles": (
                            f"Tamaño de fuente ({val}px) inferior al mínimo "
                            f"recomendado ({min_font_size}px) para 1920x1080."
                        ),
                    }
                )

        # 2. Detección de theme_override
        m_theme = RE_THEME_OVERRIDE.search(line)
        if m_theme:
            prop = m_theme.group("prop")
            hallazgos.append(
                {
                    "path": str(ruta),
                    "linea": idx,
                    "nodo": current_node_name,
                    "tipo_nodo": current_node_type,
                    "tipo_hallazgo": "theme_override",
                    "propiedad": prop,
                    "valor": prop,
                    "linea_texto": line,
                    "detalles": f"Theme override declarado en UI/HUD: {prop}",
                }
            )

        # 3. Detección de opacidad declarada (Color con alpha)
        m_color = RE_COLOR_VAL.search(line)
        if m_color:
            prop = m_color.group("prop")
            raw_args = m_color.group("args")
            partes = [p.strip() for p in raw_args.split(",")]
            if len(partes) == 4:
                try:
                    alpha = float(partes[3])
                    if alpha < min_alpha:
                        hallazgos.append(
                            {
                                "path": str(ruta),
                                "linea": idx,
                                "nodo": current_node_name,
                                "tipo_nodo": current_node_type,
                                "tipo_hallazgo": "opacidad_reducida",
                                "propiedad": prop,
                                "valor": alpha,
                                "linea_texto": line,
                                "detalles": (
                                    f"Opacidad declarada (alpha={alpha:.2f}) inferior "
                                    f"al umbral ({min_alpha:.2f})."
                                ),
                            }
                        )
                except ValueError:
                    pass

    return hallazgos


def auditar_ruta(
    target_path: Path,
    min_font_size: int = 14,
    min_alpha: float = 1.0,
) -> dict[str, Any]:
    """Audita un archivo o directorio de forma recursiva."""
    archivos: list[Path] = []
    if target_path.is_file():
        if target_path.suffix in (".tscn", ".tres"):
            archivos.append(target_path)
    elif target_path.is_dir():
        archivos.extend(
            sorted(
                [
                    p
                    for p in target_path.rglob("*")
                    if p.is_file() and p.suffix in (".tscn", ".tres")
                ]
            )
        )

    todos_hallazgos: list[dict[str, Any]] = []
    for fpath in archivos:
        hallazgos = auditar_archivo(
            fpath, min_font_size=min_font_size, min_alpha=min_alpha
        )
        todos_hallazgos.extend(hallazgos)

    return {
        "resolucion_objetivo": "1920x1080",
        "min_font_size": min_font_size,
        "min_alpha": min_alpha,
        "total_archivos": len(archivos),
        "total_hallazgos": len(todos_hallazgos),
        "hallazgos": todos_hallazgos,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Auditor estático offline de legibilidad HUD 1920x1080 (#20261016)"
    )
    parser.add_argument(
        "--path",
        type=Path,
        default=Path("godot"),
        help="Ruta al archivo o directorio a auditar (default: godot)",
    )
    parser.add_argument(
        "--json-out",
        type=Path,
        default=None,
        help="Ruta de destino para el informe JSON",
    )
    parser.add_argument(
        "--min-font-size",
        type=int,
        default=14,
        help="Tamaño mínimo de fuente en px para 1920x1080 (default: 14)",
    )
    parser.add_argument(
        "--min-alpha",
        type=float,
        default=1.0,
        help="Umbral mínimo de opacidad alpha para Color(...) (default: 1.0)",
    )
    parser.add_argument(
        "--fail-on-findings",
        action="store_true",
        help="Devuelve código de salida 2 si hay hallazgos de legibilidad",
    )

    args = parser.parse_args(argv)

    if not args.path.exists():
        print(f"Error: la ruta especificada no existe: {args.path}", file=sys.stderr)
        return 1

    reporte = auditar_ruta(
        args.path,
        min_font_size=args.min_font_size,
        min_alpha=args.min_alpha,
    )

    json_str = json.dumps(reporte, indent=2, ensure_ascii=False)
    print(json_str)

    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(json_str + "\n", encoding="utf-8")

    if args.fail_on_findings and reporte["total_hallazgos"] > 0:
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
