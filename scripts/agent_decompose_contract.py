#!/usr/bin/env python3
"""Contrato puro para la descomposición acotada de issues del agent pool."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
from typing import Any

MAX_SUBTASKS = 4
MAX_FILES = 12
KEY_RE = re.compile(r"^[a-z][a-z0-9_-]{0,31}$")
GLOB_RE = re.compile(r"[*?\[\]{}]")


class ContractError(ValueError):
    """Salida del planner que no cumple el contrato de descomposición."""


def _text(value: Any, *, field: str, max_length: int) -> str:
    if not isinstance(value, str):
        raise ContractError(f"{field} debe ser texto")
    normalized = value.strip()
    if not normalized:
        raise ContractError(f"{field} no puede estar vacío")
    if len(normalized) > max_length:
        raise ContractError(f"{field} supera {max_length} caracteres")
    return normalized


def _files(value: Any, *, field: str) -> list[str]:
    if not isinstance(value, list) or not value:
        raise ContractError(f"{field} debe ser una lista no vacía")
    if len(value) > MAX_FILES:
        raise ContractError(f"{field} supera {MAX_FILES} rutas")

    result: list[str] = []
    seen: set[str] = set()
    for raw in value:
        if not isinstance(raw, str) or not raw.strip():
            raise ContractError(f"{field} contiene una ruta inválida")
        path = raw.strip()
        if raw != path or "\\" in path or path.startswith("/") or path.endswith("/"):
            raise ContractError(f"{field} contiene una ruta no concreta: {raw!r}")
        parts = path.split("/")
        if any(part in {"", ".", ".."} for part in parts) or GLOB_RE.search(path):
            raise ContractError(f"{field} contiene una ruta no concreta: {path}")
        if path in seen:
            raise ContractError(f"{field} contiene rutas duplicadas: {path}")
        seen.add(path)
        result.append(path)
    return result


def _dependencies(value: Any, *, field: str) -> list[str]:
    if value is None:
        return []
    if not isinstance(value, list):
        raise ContractError(f"{field} debe ser una lista")
    result: list[str] = []
    seen: set[str] = set()
    for raw in value:
        if not isinstance(raw, str) or not KEY_RE.fullmatch(raw):
            raise ContractError(f"{field} contiene una clave inválida")
        if raw in seen:
            raise ContractError(f"{field} contiene dependencias duplicadas")
        seen.add(raw)
        result.append(raw)
    return result


def _assert_acyclic(tasks: list[dict[str, Any]]) -> None:
    graph = {task["key"]: task["depends_on"] for task in tasks}
    state: dict[str, int] = {}

    def visit(key: str) -> None:
        marker = state.get(key, 0)
        if marker == 1:
            raise ContractError("depends_on contiene un ciclo")
        if marker == 2:
            return
        state[key] = 1
        for dependency in graph[key]:
            visit(dependency)
        state[key] = 2

    for key in graph:
        visit(key)


def validate_contract(raw: Any) -> dict[str, Any]:
    """Valida y normaliza la salida JSON del planner de descomposición."""
    if not isinstance(raw, dict):
        raise ContractError("la salida debe ser un objeto JSON")

    allowed_top = {"decision", "reason", "subtasks"}
    extras = set(raw) - allowed_top
    if extras:
        raise ContractError(f"campos superiores no permitidos: {sorted(extras)}")

    decision = raw.get("decision")
    if decision not in {"keep", "decompose"}:
        raise ContractError("decision debe ser keep o decompose")
    reason = _text(raw.get("reason"), field="reason", max_length=600)

    subtasks = raw.get("subtasks", [])
    if not isinstance(subtasks, list):
        raise ContractError("subtasks debe ser una lista")

    if decision == "keep":
        if subtasks:
            raise ContractError("keep no puede incluir subtareas")
        return {"decision": "keep", "reason": reason, "subtasks": []}

    if not 2 <= len(subtasks) <= MAX_SUBTASKS:
        raise ContractError("decompose requiere entre 2 y 4 subtareas")

    normalized: list[dict[str, Any]] = []
    keys: set[str] = set()
    owners_by_file: dict[str, str] = {}

    for index, item in enumerate(subtasks):
        field = f"subtasks[{index}]"
        if not isinstance(item, dict):
            raise ContractError(f"{field} debe ser un objeto")
        allowed = {"key", "title", "goal", "files", "depends_on"}
        extras = set(item) - allowed
        if extras:
            raise ContractError(f"{field} contiene campos no permitidos: {sorted(extras)}")

        key = item.get("key")
        if not isinstance(key, str) or not KEY_RE.fullmatch(key):
            raise ContractError(f"{field}.key no cumple el formato")
        if key in keys:
            raise ContractError(f"clave de subtarea duplicada: {key}")
        keys.add(key)

        files = _files(item.get("files"), field=f"{field}.files")
        for path in files:
            previous = owners_by_file.get(path)
            if previous is not None:
                raise ContractError(
                    f"ruta compartida entre subtareas {previous} y {key}: {path}"
                )
            owners_by_file[path] = key

        normalized.append(
            {
                "key": key,
                "title": _text(item.get("title"), field=f"{field}.title", max_length=120),
                "goal": _text(item.get("goal"), field=f"{field}.goal", max_length=1200),
                "files": files,
                "depends_on": _dependencies(
                    item.get("depends_on"), field=f"{field}.depends_on"
                ),
            }
        )

    for task in normalized:
        unknown = set(task["depends_on"]) - keys
        if unknown:
            raise ContractError(
                f"{task['key']} depende de claves desconocidas: {sorted(unknown)}"
            )
        if task["key"] in task["depends_on"]:
            raise ContractError(f"{task['key']} no puede depender de sí misma")

    _assert_acyclic(normalized)

    return {
        "decision": "decompose",
        "reason": reason,
        "subtasks": [
            {**task, "ready": not task["depends_on"]}
            for task in normalized
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    try:
        raw = json.loads(args.input.read_text(encoding="utf-8"))
        result = validate_contract(raw)
    except (json.JSONDecodeError, ContractError) as exc:
        raise SystemExit(f"contrato inválido: {exc}") from exc

    rendered = json.dumps(result, ensure_ascii=False, separators=(",", ":"))
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
