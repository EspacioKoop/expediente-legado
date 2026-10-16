#!/usr/bin/env python3
"""Resuelve el límite del worker con los labels del issue verificados por GitHub.

Solo opt-in explícito habilita tres rutas; el valor predeterminado es una ruta.
"""

from __future__ import annotations
import argparse
import json
from pathlib import Path

PILOT_LABEL = "agent:multi-file"
SINGLE_FILE_LIMIT = 1
PILOT_FILE_LIMIT = 3


def resolve_limit(issue: object) -> int:
    if not isinstance(issue, dict):
        raise ValueError("issue JSON debe ser un objeto")
    labels = issue.get("labels", [])
    if not isinstance(labels, list):
        return SINGLE_FILE_LIMIT
    for entry in labels:
        name = entry.get("name") if isinstance(entry, dict) else entry
        if name == PILOT_LABEL:
            return PILOT_FILE_LIMIT
    return SINGLE_FILE_LIMIT


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--issue-json", type=Path, required=True)
    args = parser.parse_args(argv)
    issue = json.loads(args.issue_json.read_text(encoding="utf-8"))
    print(resolve_limit(issue))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
