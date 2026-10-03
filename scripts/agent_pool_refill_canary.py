#!/usr/bin/env python3
"""Verifica evidencia exportada de un canario de refill del agent pool.

Entrada: JSON con runs del dispatcher y jobs de worker ya normalizados. No llama
a GitHub ni cambia configuración; sirve para adjuntar una prueba reproducible al
issue operativo #2243. Todos los jobs deben tener identidad y un intervalo
completo con zona horaria. Este informe prueba tiempos y reutilización de slots;
release, rutas, backpressure y rollback requieren su propia evidencia operativa.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
from typing import Any


def _dt(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value.strip():
        return None
    text = value.strip().replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(text)
        if parsed.tzinfo is None:
            return None
        return parsed.astimezone(timezone.utc)
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


def _run_id(value: Any) -> str:
    if isinstance(value, str):
        return value.strip()
    return str(value) if type(value) is int and value > 0 else ""


def evaluar(data: dict[str, Any]) -> dict[str, Any]:
    errors: list[str] = []
    raw_jobs = data.get("jobs", [])
    if not isinstance(raw_jobs, list):
        errors.append("jobs debe ser una lista")
        raw_jobs = []
    jobs = [item for item in raw_jobs if isinstance(item, dict)]
    if len(jobs) != len(raw_jobs):
        errors.append("jobs contiene entradas que no son objetos")
    base_run = _run_id(data.get("base_run"))
    refill_run = _run_id(data.get("refill_run"))
    if base_run and base_run == refill_run:
        errors.append("base_run y refill_run deben ser distintos")

    base_jobs = [j for j in jobs if _run_id(j.get("run_id")) == base_run]
    refill_jobs = [j for j in jobs if _run_id(j.get("run_id")) == refill_run]
    if not base_run or not base_jobs:
        errors.append("base_run sin jobs")
    if not refill_run or not refill_jobs:
        errors.append("refill_run sin jobs")

    # Una fila incompleta nunca se descarta silenciosamente: podría ser
    # precisamente el job que demuestra una doble ocupación del slot.
    records: list[tuple[str, datetime, datetime, str]] = []
    for index, job in enumerate(jobs):
        worker = _worker(job)
        run_id = _run_id(job.get("run_id"))
        start = _dt(job.get("started_at"))
        end = _dt(job.get("completed_at"))
        if not worker or not run_id:
            errors.append(f"job[{index}] sin identidad de worker/run")
        if start is None or end is None:
            errors.append(f"job[{index}] sin intervalo completo con zona horaria")
        elif end < start:
            errors.append(f"job[{index}] tiene intervalo invertido")
        if worker and run_id and start is not None and end is not None and end >= start:
            records.append((worker, start, end, run_id))

    base_records = [r for r in records if r[3] == base_run]
    refill_records = [r for r in records if r[3] == refill_run]
    base_finished = [r[2] for r in base_records]
    refill_started = [r[1] for r in refill_records]
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
    for worker, start, end, run_id in records:
        if end > start:
            intervals.setdefault(worker, []).append((start, end, run_id))

    overlaps: list[dict[str, str]] = []
    for worker, spans in intervals.items():
        spans.sort(key=lambda item: item[0])
        active: list[tuple[datetime, datetime, str]] = []
        for current in spans:
            active = [previous for previous in active if previous[1] > current[0]]
            for previous in active:
                overlaps.append({
                    "worker": worker,
                    "run_a": previous[2],
                    "run_b": current[2],
                })
            active.append(current)
    if overlaps:
        errors.append("hay workers ejecutándose simultáneamente en dos jobs")

    base_workers = {_worker(j) for j in base_jobs if _worker(j)}
    refill_workers = {_worker(j) for j in refill_jobs if _worker(j)}
    if not refill_workers:
        errors.append("el refill no contiene worker identificable")

    witnesses: list[dict[str, Any]] = []
    for worker, start, _, _ in refill_records:
        released = [r[2] for r in base_records if r[0] == worker and r[2] <= start]
        busy = sorted({r[0] for r in base_records if r[0] != worker and r[1] <= start < r[2]})
        if not released:
            errors.append(f"refill en {worker} sin finalización previa del mismo slot en base_run")
        if not busy:
            errors.append(f"refill en {worker} sin otro worker base ejecutando en ese instante")
        if released and busy:
            witnesses.append({
                "worker": worker,
                "base_completed_at": max(released).isoformat(),
                "refill_started_at": start.isoformat(),
                "base_workers_en_curso": busy,
            })

    return {
        "ok": not errors,
        "refill_antes_fin_tanda": refill_antes_fin,
        "base_workers": sorted(base_workers),
        "refill_workers": sorted(refill_workers),
        "worker_overlaps": overlaps,
        "refill_witnesses": witnesses,
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
