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

BLOCKING_LABELS = {"agent:working", "agent:pr-open", "agent:needs-human", "agent:decompose"}
QUEUE_LABELS = {"agent:auto", "agent:pool", "agent:qwen", "agent:gemini"}
PROVIDER_LABELS = {"agent:qwen": "qwen", "agent:gemini": "gemini"}
MAX_ALLOWED_PARALLEL = 6
MIN_TELEMETRY_SAMPLES = 3
WORKER_FAILURE_RE = re.compile(
    r"^AGENT_POOL_WORKER_FAILURE\s+worker=([A-Za-z0-9._-]+)\b"
)
BACKEND_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{0,31}$")


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


def _worker(item: dict[str, Any]) -> dict[str, Any] | None:
    worker_id = item.get("worker")
    provider = item.get("provider")
    healthy = item.get("healthy", True)
    raw_backend = item.get("backend", provider)
    backend = raw_backend.strip().lower() if isinstance(raw_backend, str) else str(provider)
    if not BACKEND_RE.fullmatch(backend):
        backend = "custom"
    if not isinstance(worker_id, str) or not worker_id.strip():
        return None
    if provider not in {"qwen", "gemini"}:
        return None
    if healthy is False:
        return None
    raw_score = item.get("score", 50.0)
    try:
        score = float(raw_score)
    except (TypeError, ValueError):
        score = 50.0
    if isinstance(raw_score, bool):
        score = 50.0
    score = max(0.0, min(100.0, score))

    raw_samples = item.get("telemetry_samples", 0)
    try:
        telemetry_samples = int(raw_samples)
    except (TypeError, ValueError):
        telemetry_samples = 0
    if isinstance(raw_samples, bool) or telemetry_samples < 0:
        telemetry_samples = 0

    def optional_pct(key: str) -> float | None:
        raw = item.get(key)
        if raw is None or isinstance(raw, bool):
            return None
        try:
            value = float(raw)
        except (TypeError, ValueError):
            return None
        return max(0.0, min(100.0, value))

    # #1871: la telemetria B2B solo modula el orden dentro del mismo tier y
    # proveedor. Tres muestras evitan castigar un slot por una salida aislada.
    # Los campos ausentes son fail-open y no añaden penalizacion.
    routing_score = score
    if telemetry_samples >= MIN_TELEMETRY_SAMPLES:
        contract_valid = optional_pct("contract_valid_rate_pct")
        handoff_loss = optional_pct("handoff_loss_proxy_pct")
        rework_rate = optional_pct("rework_rate_pct")
        penalty = 0.0
        if contract_valid is not None:
            penalty += (100.0 - contract_valid) * 0.15
        if handoff_loss is not None:
            penalty += handoff_loss * 0.10
        if rework_rate is not None:
            penalty += rework_rate * 0.05
        routing_score = max(0.0, min(100.0, score - penalty))

    # Tier (#1685): 1 = preferente. Un tier mayor solo recibe trabajo cuando los
    # anteriores no tienen hueco; sirve para dejar backends flojos de reserva.
    raw_tier = item.get("tier", 1)
    try:
        tier = int(raw_tier)
    except (TypeError, ValueError):
        tier = 1
    if isinstance(raw_tier, bool) or tier < 1:
        tier = 1
    raw_max_task_bytes = item.get("max_task_bytes", 0)
    try:
        max_task_bytes = int(raw_max_task_bytes)
    except (TypeError, ValueError):
        max_task_bytes = 0
    if isinstance(raw_max_task_bytes, bool) or max_task_bytes < 0:
        max_task_bytes = 0
    return {
        "worker": worker_id.strip(),
        "provider": provider,
        "backend": backend,
        "score": score,
        "routing_score": routing_score,
        "telemetry_samples": telemetry_samples,
        "tier": tier,
        "max_task_bytes": max_task_bytes,
    }


def _preferred_provider(issue: dict[str, Any]) -> str | None:
    provider = issue.get("preferredProvider") or issue.get("preferred_provider")
    if provider in {"qwen", "gemini"}:
        return str(provider)
    return None


def _planned_files(issue: dict[str, Any]) -> set[str]:
    raw = issue.get("plannedFiles") or issue.get("planned_files") or []
    if not isinstance(raw, list):
        return set()
    files: set[str] = set()
    for item in raw:
        if not isinstance(item, str):
            continue
        path = item.strip().replace("\\", "/")
        if path and not path.startswith("/") and ".." not in path.split("/"):
            # Los alias relativos no deben permitir dos CLAIMs de la misma ruta.
            normalized = "/".join(part for part in path.split("/") if part not in {"", "."})
            if normalized:
                files.add(normalized)
    return files


def _estimated_task_bytes(issue: dict[str, Any]) -> int:
    """Huella aproximada que el executor tendrá que meter en contexto.

    El dispatcher añade el tamaño de los ficheros del plan. El cuerpo del issue
    también viaja en el TaskPacket, así que se suma aquí. Datos ausentes o
    inválidos son 0 para conservar el comportamiento fail-open histórico.
    """

    raw = issue.get("plannedBytes") or issue.get("planned_bytes") or 0
    try:
        planned = int(raw)
    except (TypeError, ValueError):
        planned = 0
    if isinstance(raw, bool) or planned < 0:
        planned = 0
    body = issue.get("body")
    body_bytes = len(body.encode("utf-8")) if isinstance(body, str) else 0
    return planned + body_bytes


def _worker_fits_issue(worker: dict[str, Any], issue: dict[str, Any]) -> bool:
    limit = int(worker.get("max_task_bytes", 0) or 0)
    return limit <= 0 or _estimated_task_bytes(issue) <= limit


def _paths_overlap(issue: dict[str, Any], selected_paths: set[str]) -> bool:
    planned = _planned_files(issue)
    # Un plan puede reservar un directorio entero. Compara límites de componente
    # en ambos sentidos, sin bloquear hermanos como chip y chip_extra.
    return any(
        path == selected
        or path.startswith(selected + "/")
        or selected.startswith(path + "/")
        for path in planned
        for selected in selected_paths
    )


def _remember_paths(issue: dict[str, Any], selected_paths: set[str]) -> None:
    selected_paths.update(_planned_files(issue))


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


def _usable_indices(
    workers: list[dict[str, Any]],
    issue: dict[str, Any],
) -> list[int]:
    avoided = _avoid_workers(issue)
    return [
        index
        for index, worker in enumerate(workers)
        if worker["worker"] not in avoided and _worker_fits_issue(worker, issue)
    ]


def _best_index(
    workers: list[dict[str, Any]],
    indices: list[int],
    *,
    provider: str | None = None,
) -> int | None:
    candidates = [
        index
        for index in indices
        if provider is None or workers[index]["provider"] == provider
    ]
    if not candidates:
        return None
    # Primero el tier más bajo y el mejor score histórico. En empate se usa el
    # worker con presupuesto explícito más ajustado: aprovecha backends rápidos
    # con cuota/contexto limitado sin gastar capacidad amplia en tareas pequeñas.
    def key(index: int) -> tuple[float, ...]:
        worker = workers[index]
        cap = int(worker.get("max_task_bytes", 0) or 0)
        return (
            -int(worker.get("tier", 1)),
            float(worker.get("routing_score", worker.get("score", 50.0))),
            1.0 if cap > 0 else 0.0,
            float(-cap if cap > 0 else 0),
            float(-index),
        )

    return max(candidates, key=key)


def select_tasks(
    issues: list[dict[str, Any]],
    workers: list[dict[str, Any]],
    *,
    max_parallel: int = MAX_ALLOWED_PARALLEL,
) -> list[dict[str, Any]]:
    limit = max(0, min(int(max_parallel), MAX_ALLOWED_PARALLEL))
    if limit == 0:
        return []
    free_workers = [
        normalized for item in workers if (normalized := _worker(item))
    ]
    tasks: list[dict[str, Any]] = []
    selected_paths: set[str] = set()
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
        if _paths_overlap(issue, selected_paths):
            continue

        usable = _usable_indices(free_workers, issue)
        choice_index = _best_index(
            free_workers,
            usable,
            provider=requested_provider,
        )
        if choice_index is None:
            continue

        worker = free_workers.pop(choice_index)
        tasks.append(
            {
                "issue": int(issue["number"]),
                "provider": worker["provider"],
                "backend": worker["backend"],
                "worker": worker["worker"],
            }
        )
        _remember_paths(issue, selected_paths)

    # Las tareas flexibles consumen únicamente la capacidad que queda después de
    # reservar los providers explícitos. Kev sigue siendo una preferencia blanda.
    for issue, requested_provider in eligible:
        if requested_provider is not None:
            continue
        if len(tasks) >= limit or not free_workers:
            break
        if _paths_overlap(issue, selected_paths):
            continue

        usable = _usable_indices(free_workers, issue)
        if not usable:
            continue

        preferred_provider = _preferred_provider(issue)
        if preferred_provider is not None:
            choice_index = _best_index(
                free_workers,
                usable,
                provider=preferred_provider,
            )
            if choice_index is None:
                choice_index = _best_index(free_workers, usable)
        else:
            choice_index = _best_index(free_workers, usable)
        if choice_index is None:
            continue

        worker = free_workers.pop(choice_index)
        tasks.append(
            {
                "issue": int(issue["number"]),
                "provider": worker["provider"],
                "backend": worker["backend"],
                "worker": worker["worker"],
            }
        )
        _remember_paths(issue, selected_paths)

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
