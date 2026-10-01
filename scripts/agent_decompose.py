#!/usr/bin/env python3
"""Valida la salida contractual del planner de descomposición."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
from typing import Any

PATTERN = re.compile(
    r"AGENT_DECOMPOSE_BEGIN\s*(?:```(?:json)?\s*)?(\{.*?\})(?:\s*```)?\s*AGENT_DECOMPOSE_END",
    re.IGNORECASE | re.DOTALL,
)

REASON_MAX = 400


def _recortar(texto: str, limite: int) -> str:
    # El reason solo acaba en un comentario: un diagnóstico largo vale más
    # recortado que descartado por el mensaje genérico de fallo (#2068).
    if len(texto) <= limite:
        return texto
    corte = texto[: limite - 1].rsplit(" ", 1)[0].rstrip(" ,.;:")
    return corte + "…"


def _safe_path(value: Any) -> str:
    if not isinstance(value, str):
        raise ValueError("ruta no string")
    path = value.strip().replace("\\", "/")
    if (
        not path
        or path.startswith("/")
        or ".." in path.split("/")
        or any(char in path for char in "*?[]")
        or path.startswith(".github/")
        or path.startswith(".agent-")
    ):
        raise ValueError(f"ruta insegura: {path}")
    return path


def parse_decomposition(raw: str) -> dict[str, Any]:
    match = PATTERN.search(raw or "")
    if not match:
        raise ValueError("salida sin AGENT_DECOMPOSE_BEGIN/END")
    try:
        data = json.loads(match.group(1))
    except json.JSONDecodeError as exc:
        raise ValueError("JSON de descomposición inválido") from exc

    fits = data.get("fits_single_cut")
    if not isinstance(fits, bool):
        raise ValueError("fits_single_cut debe ser booleano")

    needs_human = data.get("needs_human", False)
    if not isinstance(needs_human, bool):
        raise ValueError("needs_human debe ser booleano")
    reason = " ".join(str(data.get("reason", "")).split()).strip()

    raw_tasks = data.get("subtasks", [])
    if not isinstance(raw_tasks, list):
        raise ValueError("subtasks debe ser lista")

    if needs_human:
        if fits or raw_tasks:
            raise ValueError("needs_human no puede combinarse con corte o subtareas")
        if len(reason) < 10:
            raise ValueError("reason humano fuera de límites")
        return {
            "schema": 1,
            "fits_single_cut": False,
            "needs_human": True,
            "reason": _recortar(reason, REASON_MAX),
            "subtasks": [],
        }

    if fits:
        if len(raw_tasks) != 1:
            raise ValueError("un corte directo debe declarar exactamente una subtarea")
    elif not 2 <= len(raw_tasks) <= 6:
        raise ValueError("una descomposición debe tener entre 2 y 6 subtareas")

    clean: list[dict[str, Any]] = []
    titles: set[str] = set()
    for index, task in enumerate(raw_tasks):
        if not isinstance(task, dict):
            raise ValueError("subtarea inválida")
        title = " ".join(str(task.get("title", "")).split()).strip()
        goal = " ".join(str(task.get("goal", "")).split()).strip()
        if not 5 <= len(title) <= 100:
            raise ValueError("título fuera de límites")
        if not 10 <= len(goal) <= 400:
            raise ValueError("goal fuera de límites")
        if title.casefold() in titles:
            raise ValueError("títulos duplicados")
        titles.add(title.casefold())

        raw_files = task.get("files", [])
        if not isinstance(raw_files, list) or len(raw_files) != 1:
            raise ValueError("files debe contener exactamente 1 ruta")
        files = list(dict.fromkeys(_safe_path(item) for item in raw_files))

        raw_deps = task.get("depends_on", [])
        if not isinstance(raw_deps, list):
            raise ValueError("depends_on debe ser lista")
        deps: list[int] = []
        for dep in raw_deps:
            if not isinstance(dep, int) or isinstance(dep, bool):
                raise ValueError("dependencia inválida")
            if dep < 0 or dep >= index:
                raise ValueError("dependencia debe apuntar a una subtarea anterior")
            if dep not in deps:
                deps.append(dep)

        # Si dos cortes comparten ruta, el posterior debe depender explícitamente
        # del anterior para que nunca se ejecuten en paralelo.
        file_set = set(files)
        for previous_index, previous in enumerate(clean):
            if file_set.intersection(previous["files"]) and previous_index not in deps:
                raise ValueError(
                    "subtareas con rutas solapadas requieren dependencia explícita"
                )

        clean.append(
            {
                "title": title,
                "goal": goal,
                "files": files,
                "depends_on": deps,
            }
        )

    return {
        "schema": 1,
        "fits_single_cut": fits,
        "needs_human": False,
        "reason": "",
        "subtasks": clean,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--summary-file", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = parse_decomposition(args.summary_file.read_text(encoding="utf-8"))
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
