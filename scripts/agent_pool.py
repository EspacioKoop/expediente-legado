#!/usr/bin/env python3
"""Selector determinista para el pool paralelo de agentes.

No reserva rutas ni modifica GitHub. Recibe snapshots JSON de issues y workers
disponibles, y devuelve una matrix acotada para GitHub Actions.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

BLOCKING_LABELS = {"agent:working", "agent:pr-open", "agent:needs-human"}
QUEUE_LABELS = {"agent:auto", "agent:pool", "agent:qwen", "agent:gemini"}
PROVIDER_LABELS = {"agent:qwen": "qwen", "agent:gemini": "gemini"}
MAX_ALLOWED_PARALLEL = 6


def _labels(issue: dict[str, Any]) -> set[str]:
    raw = issue.get("labels", [])
    result: set[str] = set()
    if not isinstance(raw, list):
        return result
    for item in raw:
        if isinstance(item, str):
            result.add(item)
        elif isinstance(item, dict):
            name = item.get("name")
            if isinstance(name, str):
                result.add(name)
    return result


def _worker(item: dict[str, Any]) -> dict[str, str] | None:
    worker_id = item.get("worker")
    provider = item.get("provider")
    if not isinstance(worker_id, str) or not worker_id.strip():
        return None
    if provider not in {"qwen", "gemini"}:
        return None
    return {"worker": worker_id.strip(), "provider": provider}


def _preferred_provider(issue: dict[str, Any]) -> str | None:
    provider = issue.get("preferredProvider") or issue.get("preferred_provider")
    if provider in {"qwen", "gemini"}:
        return str(provider)
    return None


def _sort_key(issue: dict[str, Any]) -> tuple[str, int]:
    created = issue.get("createdAt") or issue.get("created_at") or ""
    try:
        number = int(issue.get("number", 0))
    except (TypeError, ValueError):
        number = 0
    return str(created), number


def eligible_issue(issue: dict[str, Any]) -> tuple[bool, str | None]:
    try:
        number = int(issue.get("number"))
    except (TypeError, ValueError):
        return False, None
    if number <= 0:
        return False, None

    labels = _labels(issue)
    if not labels & QUEUE_LABELS:
        return False, None
    if labels & BLOCKING_LABELS:
        return False, None

    requested = {
        provider
        for label, provider in PROVIDER_LABELS.items()
        if label in labels
    }
    if len(requested) > 1:
        return False, None
    provider = next(iter(requested), None)
    return True, provider


def select_tasks(
    issues: list[dict[str, Any]],
    workers: list[dict[str, Any]],
    *,
    max_parallel: int = MAX_ALLOWED_PARALLEL,
) -> list[dict[str, Any]]:
    limit = max(1, min(int(max_parallel), MAX_ALLOWED_PARALLEL))
    free_workers = [
        normalized for item in workers if (normalized := _worker(item))
    ]
    tasks: list[dict[str, Any]] = []
    eligible: list[tuple[dict[str, Any], str | None]] = []
    for issue in sorted(issues, key=_sort_key):
        ok, requested_provider = eligible_issue(issue)
        if ok:
            eligible.append((issue, requested_provider))

    # Reserva primero la capacidad obligatoria. Así una tarea flexible más antigua
    # no puede consumir el único slot de un proveedor exigido por otra tarea.
    for issue, requested_provider in eligible:
        if requested_provider is None:
            continue
        if len(tasks) >= limit or not free_workers:
            break

        choice_index = next(
            (
                index
                for index, worker in enumerate(free_workers)
                if worker["provider"] == requested_provider
            ),
            None,
        )
        if choice_index is None:
            continue

        worker = free_workers.pop(choice_index)
        tasks.append(
            {
                "issue": int(issue["number"]),
                "provider": worker["provider"],
                "worker": worker["worker"],
            }
        )

    # Las tareas flexibles consumen únicamente la capacidad que queda después de
    # reservar los proveedores explícitos. Kev sigue siendo una preferencia blanda.
    for issue, requested_provider in eligible:
        if requested_provider is not None:
            continue
        if len(tasks) >= limit or not free_workers:
            break

        preferred_provider = _preferred_provider(issue)
        if preferred_provider is not None:
            choice_index = next(
                (
                    index
                    for index, worker in enumerate(free_workers)
                    if worker["provider"] == preferred_provider
                ),
                0,
            )
        else:
            choice_index = 0

        worker = free_workers.pop(choice_index)
        tasks.append(
            {
                "issue": int(issue["number"]),
                "provider": worker["provider"],
                "worker": worker["worker"],
            }
        )

    return tasks


def build_matrix(
    issues: list[dict[str, Any]],
    workers: list[dict[str, Any]],
    *,
    max_parallel: int = MAX_ALLOWED_PARALLEL,
) -> dict[str, Any]:
    return {"include": select_tasks(issues, workers, max_parallel=max_parallel)}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--issues", required=True, type=Path)
    parser.add_argument("--workers", required=True, type=Path)
    parser.add_argument("--max-parallel", type=int, default=MAX_ALLOWED_PARALLEL)
    parser.add_argument("--output", type=Path)
    return parser.parse_args()


def _read_list(path: Path, name: str) -> list[dict[str, Any]]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, list):
        raise SystemExit(f"{name} debe ser una lista JSON")
    return [item for item in raw if isinstance(item, dict)]


def main() -> int:
    args = parse_args()
    issues = _read_list(args.issues, "issues")
    workers = _read_list(args.workers, "workers")
    result = build_matrix(issues, workers, max_parallel=args.max_parallel)
    rendered = json.dumps(result, ensure_ascii=False, separators=(",", ":"))
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
