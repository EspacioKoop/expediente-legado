#!/usr/bin/env python3
"""Auditor estático offline de referencias a escenas, recursos y disparadores de la secuencia de introducción (#395, #20261016).

Analiza archivos del proyecto Godot (.gd, .tscn, .json, .tres) para rastrear:
1. Rutas de recursos 'res://' y cargas dinámicas/estáticas.
2. Transiciones de escena (change_scene_to_file, etc.).
3. Disparadores de secuencias y cinemáticas introductorias.
4. Estado de existencia en disco de cada destino referenciado.

Devuelve informe estructurado en JSON indicando origen, línea, referencia,
destino en disco, si existe o no, y detalles de la incidencia.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any

# Match explicit res:// paths
RE_RES_PATH = re.compile(r'res://[a-zA-Z0-9_\-/.%]+')

# Match preloads, loads, change_scene_to_file
RE_LOAD_PRELOAD = re.compile(
    r'(?P<func>preload|load|change_scene_to_file|change_scene_to_packed)\s*\(\s*["\'](?P<path>[^"\']+)["\']\s*\)'
)

# Match cutscene / intro triggers
RE_TRIGGER = re.compile(
    r'(?P<trigger>iniciar_apertura_creditos|iniciar_montaje_onirico|iniciar_cinematica_creditos|terminar_apertura_creditos|_iniciar_apertura_creditos|_iniciar_montaje_onirico|_iniciar_cinematica_creditos|_terminar_apertura_creditos|reproducir|planos_de|planos)\s*\('
)

# Patterns in filenames/paths related to intro cutscenes
PATRONES_INTRO = ("intro", "inicio", "apertura", "creditos", "epigrafes", "cinematica", "secuencia")


def es_archivo_relacionado_intro(path: Path) -> bool:
    """Comprueba si un archivo pertenece a o está relacionado con la secuencia introductoria."""
    path_str = str(path).lower()
    return any(pat in path_str for pat in PATRONES_INTRO)


def resolver_ruta_res(res_path: str) -> str:
    """Convierte una ruta res:// a la ruta local en el sistema de archivos del repositorio."""
    if res_path.startswith("res://"):
        return "godot/" + res_path[6:]
    return res_path


def auditar_archivo(ruta: Path) -> list[dict[str, Any]]:
    """Audita un único archivo e identifica referencias, cargas y disparadores."""
    try:
        contenido = ruta.read_text(encoding="utf-8")
    except Exception as exc:
        return [
            {
                "origen": str(ruta),
                "linea": 0,
                "origen_linea": "",
                "referencia_raw": "",
                "destino_calculado": "",
                "existe": False,
                "tipo_referencia": "error_lectura",
                "detalles": f"No se pudo leer el archivo: {exc}",
            }
        ]

    hallazgos: list[dict[str, Any]] = []
    lineas = contenido.splitlines()

    for idx, raw_line in enumerate(lineas, start=1):
        line = raw_line.strip()
        if not line or line.startswith("#") or line.startswith("//"):
            continue

        # 1. Cargas explícitas / transiciones
        for m_load in RE_LOAD_PRELOAD.finditer(line):
            func_name = m_load.group("func")
            raw_path = m_load.group("path")
            destino = resolver_ruta_res(raw_path)
            existe = os.path.exists(destino) if not ("%" in destino or "*" in destino) else True

            tipo = "cambio_escena" if "change_scene" in func_name else "carga_recurso"
            hallazgos.append(
                {
                    "origen": str(ruta),
                    "linea": idx,
                    "origen_linea": line,
                    "referencia_raw": raw_path,
                    "destino_calculado": destino,
                    "existe": existe,
                    "tipo_referencia": tipo,
                    "detalles": f"Llamada a {func_name} con referencia a '{raw_path}'",
                }
            )

        # 2. Rutas res:// generales en texto
        for m_res in RE_RES_PATH.finditer(line):
            raw_path = m_res.group(0)
            # Evitar duplicar si ya fue capturado por load/preload en esta misma línea
            if any(h["referencia_raw"] == raw_path and h["linea"] == idx for h in hallazgos):
                continue

            destino = resolver_ruta_res(raw_path)
            is_template = "%" in destino or "*" in destino
            existe = os.path.exists(destino) if not is_template else True

            hallazgos.append(
                {
                    "origen": str(ruta),
                    "linea": idx,
                    "origen_linea": line,
                    "referencia_raw": raw_path,
                    "destino_calculado": destino,
                    "existe": existe,
                    "tipo_referencia": "referencia_res",
                    "detalles": f"Referencia res:// {'plantilla' if is_template else 'directa'}: {raw_path}",
                }
            )

        # 3. Disparadores de secuencia introductoria
        for m_trig in RE_TRIGGER.finditer(line):
            trigger_name = m_trig.group("trigger")
            hallazgos.append(
                {
                    "origen": str(ruta),
                    "linea": idx,
                    "origen_linea": line,
                    "referencia_raw": trigger_name,
                    "destino_calculado": str(ruta),
                    "existe": True,
                    "tipo_referencia": "disparador_secuencia",
                    "detalles": f"Disparador de secuencia o cinemática introductoria: '{trigger_name}'",
                }
            )

    return hallazgos


def auditar_ruta(target_path: Path, solo_intro: bool = True) -> dict[str, Any]:
    """Audita una ruta objetivo (archivo o directorio) filtrando o no por archivos de intro."""
    archivos: list[Path] = []
    if target_path.is_file():
        archivos.append(target_path)
    elif target_path.is_dir():
        for p in sorted(target_path.rglob("*")):
            if p.is_file() and p.suffix in (".gd", ".tscn", ".json", ".tres"):
                if not solo_intro or es_archivo_relacionado_intro(p):
                    archivos.append(p)

    todos_hallazgos: list[dict[str, Any]] = []
    for fpath in archivos:
        hallazgos = auditar_archivo(fpath)
        todos_hallazgos.extend(hallazgos)

    inexistentes = [h for h in todos_hallazgos if not h["existe"]]

    return {
        "vulnerabilidad_o_mision": "#395 / #20261016",
        "descripcion": "Rastreador estático offline de referencias a escenas y recursos de introducción y disparadores conocidos",
        "total_archivos_auditados": len(archivos),
        "total_referencias_encontradas": len(todos_hallazgos),
        "total_referencias_inexistentes": len(inexistentes),
        "archivos_auditados": [str(a) for a in archivos],
        "hallazgos_inexistentes": inexistentes,
        "todos_hallazgos": todos_hallazgos,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Auditor estático offline de referencias e incidencias de la secuencia de introducción (#395, #20261016)"
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
        help="Ruta de destino para exportar el informe JSON",
    )
    parser.add_argument(
        "--todos-los-archivos",
        action="store_true",
        help="Audita todos los archivos Godot sin filtrar exclusivamente por patrones de intro",
    )
    parser.add_argument(
        "--fail-on-missing",
        action="store_true",
        help="Devuelve código de salida 2 si se detecta alguna referencia inexistente",
    )

    args = parser.parse_args(argv)

    if not args.path.exists():
        print(f"Error: la ruta especificada no existe: {args.path}", file=sys.stderr)
        return 1

    reporte = auditar_ruta(args.path, solo_intro=not args.todos_los_archivos)

    json_str = json.dumps(reporte, indent=2, ensure_ascii=False)
    print(json_str)

    if args.json_out:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(json_str + "\n", encoding="utf-8")

    if args.fail_on_missing and reporte["total_referencias_inexistentes"] > 0:
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
