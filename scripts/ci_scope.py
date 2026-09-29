#!/usr/bin/env python3
"""Clasifica un diff como fast-path de infraestructura o CI completo."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
from typing import Iterable

FAST_PREFIXES = (
    ".github/workflows/agent-",
    ".github/workflows/feedback-deno",
    ".github/workflows/mando-deno",
    "infra/feedback-deno/",
    "infra/mando-deno/",
    "docs/agents/",
    "scripts/agent_",
    "scripts/test_agent_",
)
FAST_EXACT = {
    "docs/agents-autonomos.md",
    "scripts/check_deno_production.py",
    "scripts/test_deno_production_freshness.py",
}


def is_fast_path(path: str) -> bool:
    normalized = path.strip().replace("\\", "/")
    if not normalized:
        return False
    return normalized in FAST_EXACT or normalized.startswith(FAST_PREFIXES)


def classify(paths: Iterable[str]) -> dict[str, object]:
    clean = sorted({path.strip().replace("\\", "/") for path in paths if path.strip()})
    if not clean:
        return {"mode": "full", "files": [], "reason": "diff-vacio"}
    outside = [path for path in clean if not is_fast_path(path)]
    return {
        "mode": "fast" if not outside else "full",
        "files": clean,
        "outside": outside,
        "reason": "solo-infra-agentes" if not outside else "ruta-no-fast",
    }


def changed_paths(base: str, head: str) -> list[str]:
    output = subprocess.check_output(
        ["git", "diff", "--name-only", f"{base}...{head}"],
        text=True,
    )
    return [line for line in output.splitlines() if line.strip()]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", required=True)
    parser.add_argument("--head", default="HEAD")
    parser.add_argument("--github-output", type=Path)
    parser.add_argument("--paths-file", type=Path)
    args = parser.parse_args()

    if args.paths_file:
        paths = args.paths_file.read_text(encoding="utf-8").splitlines()
    else:
        paths = changed_paths(args.base, args.head)

    result = classify(paths)
    print(json.dumps(result, ensure_ascii=False))

    if args.github_output:
        with args.github_output.open("a", encoding="utf-8") as fh:
            fh.write(f"mode={result['mode']}\n")
            fh.write(f"reason={result['reason']}\n")
            fh.write(f"count={len(result['files'])}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
