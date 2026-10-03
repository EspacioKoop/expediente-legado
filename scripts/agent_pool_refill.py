#!/usr/bin/env python3
"""Selección conservadora para refill con tandas anteriores aún activas (#2239).

El llamador obtiene worker-status para todos los slots configurados y las dos
consultas de Actions. No debe usar este contrato como reserva: acquire conserva
la exclusión atómica frente a snapshots concurrentes. Tampoco dispara workflows.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

try:
    from scripts.agent_pool import MAX_ALLOWED_PARALLEL, _paths_overlap, _planned_files, build_matrix
    from scripts.agent_pool_backpressure import effective_capacity
except ModuleNotFoundError:  # ejecución directa desde la raíz del checkout
    from agent_pool import MAX_ALLOWED_PARALLEL, _paths_overlap, _planned_files, build_matrix
    from agent_pool_backpressure import effective_capacity


def build_refill_matrix(
    issues: list[dict[str, Any]],
    workers: list[dict[str, Any]],
    worker_status: Any,
    *,
    requested: int,
    queued: int | None,
    in_progress: int | None,
    budget: int,
    refill_worker: str = "",
) -> dict[str, Any]:
    """Descuenta ocupación global y bloqueos antes de asignar un slot libre.

    Un refill concurrente falla cerrado cuando falta una lectura fiable. El
    drain histórico puede volver a intentarlo al acabar la tanda original.
    """
    empty = {"include": [], "capacity": 0, "reason": "control_unavailable"}
    if not isinstance(worker_status, dict) or worker_status.get("ok") is not True:
        return empty
    leases = worker_status.get("leases")
    if not isinstance(leases, list):
        return empty
    occupied = {worker["worker"] for worker in workers
                if worker.get("occupied") is True and isinstance(worker.get("worker"), str)}
    leased_issues: set[int] = set()
    locked_paths: set[str] = set()
    for lease in leases:
        if not isinstance(lease, dict):
            return empty
        worker = lease.get("worker")
        issue = lease.get("issue")
        files = lease.get("files", [])  # leases anteriores a los locks de rutas
        if (not isinstance(worker, str) or not worker.strip()
                or type(issue) is not int or issue <= 0
                or not isinstance(files, list)
                or any(not isinstance(path, str) for path in files)):
            return empty
        if any(not _planned_files({"plannedFiles": [path]}) for path in files):
            return empty
        occupied.add(worker)
        leased_issues.add(issue)
        locked_paths.update(_planned_files({"plannedFiles": files}))

    if (type(queued) is not int or queued < 0
            or type(in_progress) is not int or in_progress < 0):
        return {**empty, "reason": "actions_unavailable"}
    limit = max(0, min(int(requested), MAX_ALLOWED_PARALLEL))
    remaining = max(0, limit - len(occupied))
    capacity = effective_capacity(
        remaining, queued=queued, in_progress=in_progress, budget=budget,
    )
    available = [
        {**worker, "occupied": worker.get("occupied") is True or worker.get("worker") in occupied}
        for worker in workers
        if not refill_worker or worker.get("worker") == refill_worker
    ]
    candidates = [
        issue for issue in issues
        if issue.get("number") not in leased_issues and not _paths_overlap(issue, locked_paths)
    ]
    matrix = build_matrix(candidates, available, max_parallel=capacity)
    return {
        **matrix,
        "capacity": capacity,
        "reason": "selected" if matrix["include"] else "no_capacity_or_work",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("issues", "workers", "worker-status"):
        parser.add_argument(f"--{name}", required=True, type=Path)
    parser.add_argument("--requested", required=True, type=int)
    parser.add_argument("--queued", type=int)
    parser.add_argument("--in-progress", type=int)
    parser.add_argument("--budget", required=True, type=int)
    parser.add_argument("--refill-worker", default="")
    args = parser.parse_args()
    issues = json.loads(args.issues.read_text(encoding="utf-8"))
    workers = json.loads(args.workers.read_text(encoding="utf-8"))
    try:
        status = json.loads(args.worker_status.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        status = None
    result = build_refill_matrix(
        issues, workers, status, requested=args.requested,
        queued=args.queued, in_progress=args.in_progress, budget=args.budget,
        refill_worker=args.refill_worker,
    )
    print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
