#!/usr/bin/env python3
"""Calcula capacidad efectiva del agent pool según carga de GitHub Actions."""

from __future__ import annotations

import argparse
import json

MAX_ALLOWED_PARALLEL = 6


def effective_capacity(
    requested: int,
    *,
    queued: int,
    in_progress: int,
    budget: int,
) -> int:
    """Devuelve cuántos workers nuevos caben sin superar el presupuesto."""
    requested = max(0, min(int(requested), MAX_ALLOWED_PARALLEL))
    queued = max(0, int(queued))
    in_progress = max(0, int(in_progress))
    budget = max(0, int(budget))
    available = max(0, budget - queued - in_progress)
    return min(requested, available)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--requested", type=int, required=True)
    parser.add_argument("--queued", type=int, required=True)
    parser.add_argument("--in-progress", type=int, required=True)
    parser.add_argument("--budget", type=int, required=True)
    args = parser.parse_args()

    capacity = effective_capacity(
        args.requested,
        queued=args.queued,
        in_progress=args.in_progress,
        budget=args.budget,
    )
    print(
        json.dumps(
            {
                "requested": max(0, min(args.requested, MAX_ALLOWED_PARALLEL)),
                "queued": max(0, args.queued),
                "in_progress": max(0, args.in_progress),
                "budget": max(0, args.budget),
                "capacity": capacity,
            },
            separators=(",", ":"),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
