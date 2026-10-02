#!/usr/bin/env python3
"""Calcula un score histórico pequeño para slots del agent pool."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
from typing import Any

JOB_RE = re.compile(
    r"^run \(\d+,\s*(?P<provider>qwen|gemini),\s*"
    r"(?:(?P<backend>[A-Za-z0-9._-]+),\s*)?"
    r"(?P<worker>[A-Za-z0-9._-]+)\) / worker$"
)
OUTCOME_VALUE = {
    "success": 1.0,
    "failure": -1.0,
    "cancelled": -0.5,
    "timed_out": -1.0,
    "startup_failure": -1.0,
    "action_required": -0.75,
}


def score_jobs(jobs: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    per_worker: dict[str, list[float]] = {}
    providers: dict[str, str] = {}

    for job in jobs:
        if not isinstance(job, dict):
            continue
        name = job.get("name")
        conclusion = str(job.get("conclusion") or "").lower()
        if not isinstance(name, str) or conclusion not in OUTCOME_VALUE:
            continue
        match = JOB_RE.match(name)
        if not match:
            continue

        if conclusion == "success":
            steps = job.get("steps", [])
            publish = next(
                (
                    step
                    for step in steps
                    if isinstance(step, dict)
                    and step.get("name") == "Publicar PR draft y lanzar CI canonica"
                ),
                None,
            )
            # Un job puede acabar success tras salir temprano en el guard. Eso no
            # demuestra que el worker haya completado una tarea y no debe premiarlo.
            if not publish or publish.get("conclusion") != "success":
                continue

        worker = match.group("worker")
        providers[worker] = match.group("provider")
        per_worker.setdefault(worker, []).append(OUTCOME_VALUE[conclusion])

    result: dict[str, dict[str, Any]] = {}
    for worker, values in per_worker.items():
        # La lista llega en orden de runs recientes a antiguos. Cada muestra pesa
        # un 15% menos que la anterior para que una recuperación reciente importe.
        numerator = 0.0
        denominator = 0.0
        for index, value in enumerate(values[:20]):
            weight = 0.85 ** index
            numerator += value * weight
            denominator += weight
        mean = numerator / denominator if denominator else 0.0
        score = max(0.0, min(100.0, 50.0 + 40.0 * mean))
        result[worker] = {
            "provider": providers[worker],
            "score": round(score, 2),
            "samples": min(len(values), 20),
        }
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--jobs", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    data = json.loads(args.jobs.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise SystemExit("--jobs debe ser una lista JSON")
    result = score_jobs([item for item in data if isinstance(item, dict)])
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
