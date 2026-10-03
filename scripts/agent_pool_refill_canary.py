#!/usr/bin/env python3
"""Verifica evidencia exportada de un canario de refill del agent pool.

Entrada: JSON con runs del dispatcher y jobs de worker ya normalizados. No llama
a GitHub ni cambia configuración; sirve para adjuntar una prueba reproducible al
issue operativo #2243.
"""

from __future__ import annotations

import argparse
from datetime import datetime
import json
from pathlib import Path
from typing import Any


def _dt(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value.strip():
        return None
    text = value.strip().replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(text)
    except ValueError:
        return None


def _worker(job: dict[str, Any]) -> str:
    explicit = job.get("worker")
    if isinstance(explicit, str) and explicit.strip():
        return explicit.strip()
    name = job.get("name")
    if not isinstance(name, str):
        return ""
    # Matrix job histórico: "run (qwen / worker) / worker".
    marker = " / worker"
    if not name.endswith(marker):
        return ""
    prefix = name[: -len(marker)]
    if "(" not in prefix or ")" not in prefix:
        return ""
    inside = prefix.rsplit("(", 1)[1].rsplit(")", 1)[0]
    parts = [part.strip() for part in inside.split("/")]
    return parts[-1] if parts else ""


def evaluar(data: dict[str, Any]) -> dict[str, Any]:
    jobs = [item for item in data.get("jobs", []) if isinstance(item, dict)]
    base_run = str(data.get("base_run", "")).strip()
    refill_run = str(data.get("refill_run", "")).strip()
    errors: list[str] = []

    base_jobs = [j for j in jobs if str(j.get("run_id", "")) == base_run]
    refill_jobs = [j for j in jobs if str(j.get("run_id", "")) == refill_run]
    if not base_run or not base_jobs:
        errors.append("base_run sin jobs")
    if not refill_run or not refill_jobs:
        errors.append("refill_run sin jobs")

    base_finished = [_dt(j.get("completed_at")) for j in base_jobs]
    base_finished = [item for item in base_finished if item is not None]
    refill_started = [_dt(j.get("started_at")) for j in refill_jobs]
    refill_started = [item for item in refill_started if item is not None]
    if not base_finished:
        errors.append("faltan completed_at de la tanda base")
    if not refill_started:
        errors.append("faltan started_at del refill")

    refill_antes_fin = False
    if base_finished and refill_started:
        refill_antes_fin = min(refill_started) < max(base_finished)
        if not refill_antes_fin:
            errors.append("el refill no arrancó antes de acabar la tanda base")

    intervals: dict[str, list[tuple[datetime, datetime, str]]] = {}
    for job in jobs:
        worker = _worker(job)
        start = _dt(job.get("started_at"))
        end = _dt(job.get("completed_at"))
        if not worker or start is None or end is None:
            continue
        intervals.setdefault(worker, []).append((start, end, str(job.get("run_id", ""))))

    overlaps: list[dict[str, str]] = []
    for worker, spans in intervals.items():
        spans.sort(key=lambda item: item[0])
        for previous, current in zip(spans, spans[1:]):
            if current[0] < previous[1]:
                overlaps.append({
                    "worker": worker,
                    "run_a": previous[2],
                    "run_b": current[2],
                })
    if overlaps:
        errors.append("hay workers ejecutándose simultáneamente en dos jobs")

    base_workers = {_worker(j) for j in base_jobs if _worker(j)}
    refill_workers = {_worker(j) for j in refill_jobs if _worker(j)}
    if not refill_workers:
        errors.append("el refill no contiene worker identificable")

    return {
        "ok": not errors,
        "refill_antes_fin_tanda": refill_antes_fin,
        "base_workers": sorted(base_workers),
        "refill_workers": sorted(refill_workers),
        "worker_overlaps": overlaps,
        "errors": errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    raw = json.loads(args.input.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise SystemExit("input debe ser un objeto JSON")
    result = evaluar(raw)
    rendered = json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True)
    if args.output:
        args.output.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
