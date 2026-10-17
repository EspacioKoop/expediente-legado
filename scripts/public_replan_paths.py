#!/usr/bin/env python3
"""Safely expose only already-public tracked game paths in replan comments.

The agent may create untracked private files. Never echo denied filenames.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys

SAFE_PATH = re.compile(r"^[A-Za-z0-9_./+\-]+$")
MAX_PATHS = 12
MAX_BYTES = 65536


def public_paths(outside: object, tracked: set[str]) -> str | None:
    if not isinstance(outside, list) or not 1 <= len(outside) <= MAX_PATHS:
        return None
    safe = []
    for path in outside:
        if not isinstance(path, str) or not 1 <= len(path) <= 240:
            return None
        if not SAFE_PATH.fullmatch(path) or path.startswith(("/", "./", "-")):
            return None
        if any(segment in {"", ".", ".."} for segment in path.split("/")):
            return None
        if path not in tracked:  # Already tracked by git => publicly visible
            return None
        if path not in safe:
            safe.append(path)
    return ",".join(safe)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--guard", type=Path, required=True)
    parser.add_argument("--repo", type=Path, default=Path("."))
    args = parser.parse_args()
    try:
        if args.guard.stat().st_size > MAX_BYTES:
            raise ValueError("oversized guard")
        data = json.loads(args.guard.read_text(encoding="utf-8"))
        tracked_raw = subprocess.run(
            ["git", "-C", str(args.repo), "ls-files", "--cached", "-z"],
            check=True, capture_output=True, timeout=10,
        ).stdout
        tracked = {
            path.decode("utf-8") for path in tracked_raw.split(b"\0") if path
        }
        result = public_paths(data.get("outside"), tracked)
        if result is not None:
            print(result)
            return 0
    except (OSError, UnicodeError, ValueError, TypeError, subprocess.SubprocessError):
        pass
    print("Replan requiere revisión manual de rutas no públicas.", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
