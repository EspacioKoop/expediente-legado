#!/usr/bin/env python3
"""Selector determinista para el pool paralelo de agentes.

No reserva rutas ni modifica GitHub. Recibe snapshots JSON de issues y workers
disponibles, y devuelve una matrix acotada para GitHub Actions.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
from typing import Any

BLOCKING_LABELS = {"agent:working", "agent:pr-open", "agent:needs-human"}
QUEUE_LABELS = {"agent:auto", "agent:pool", "agent:qwen", "agent:gemini"}
PROVIDER_LABELS = {"agent:qwen": "qwen", "agent:gemini": "gemini"}
MAX_ALLOWED_PARALLEL = 6
WORKER_FAILURE_RE = re.compile(
    r"^AGENT_POOL_WORKER_FAILURE\s+worker=([A-Za-z0-9._-]+)\b"
)


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


def _comment_bodies(issue: dict[str, Any]) -> list[str]:
    raw = issue.get("comments", [])
    if not isinstance(raw, list):
        return []
    bodies: list[str] = []
    for item in raw:
        if isinstance(item, str):
            bodies.append(item)
        elif isinstance(item, dict) and isinstance(item.get("body"), str):
            bodies.append(item["body"])
    return bodies


def _avoid_workers(issue: dict[str, Any]) -> set[str]:
    avoided: set[str] = set()
    direct = issue.get("avoidWorkers") or issue.get("avoid_workers") or []
    if isinstance(direct, list):
        avoided.update(
            item.strip()
            for item in direct
            if isinstance(item, str) and item.strip()
        )

    for body in _comment_bodies(issue):
        for line in body.splitlines():
            line = line.strip()
            if line.startswith("AGENT_POOL_RETRY_RESET"):
                avoided.clear()
                continue
            match = WORKER_FAILURE_RE.match(line)
            if match:
                avoided.add(match.group(1))
    return avoided


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


def _ordered_eligible(
    issues: list[dict[str, Any]],
) -> list[tuple[dict[str, Any], str | None]]:
    candidates: list[tuple[dict[str, Any], str | None]] = []
    for issue in sorted(issues, key=_sort_key):
        ok, requested_provider = eligible_issue(issue)
        if ok:
            candidates.append((issue, requested_provider))

    # Reserva primero la capacidad exigida por labels explícitos. Dentro de
    # cada grupo se conserva el orden determinista histórico.
    candidates.sort(
        key=lambda item: (
            item[1] is None,
            _sort_key(item[0]),
        )
    )
    return candidates


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

    for issue, requested_provider in _ordered_eligible(issues):
        if not free_workers:
            break

        avoided = _avoid_workers(issue)
        usable_indices = [
            index
            for index, worker in enumerate(free_workers)
            if worker["worker"] not in avoided
        ]
        if not usable_indices:
            continue

        preferred_provider = requested_provider or _preferred_provider(issue)
        if requested_provider is not None:
            choice_index = next(
                (
                    index
                    for index in usable_indices
                    if free_workers[index]["provider"] == requested_provider
                ),
                None,
            )
            if choice_index is None:
                continue
        elif preferred_provider is not None:
            choice_index = next(
                (
                    index
                    for index in usable_indices
                    if free_workers[index]["provider"] == preferred_provider
                ),
                usable_indices[0],
            )
        else:
            choice_index = usable_indices[0]

        worker = free_workers.pop(choice_index)
        tasks.append(
            {
                "issue": int(issue["number"]),
                "provider": worker["provider"],
                "worker": worker["worker"],
            }
        )
        if len(tasks) >= limit:
            break

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
