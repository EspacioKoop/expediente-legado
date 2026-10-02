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


EVIDENCE_PREFIXES = (
    ".github/workflows/evidencia-",
    ".github/workflows/kubasta-visual-gate-",
    ".github/workflows/cata-",
    ".github/workflows/laboratorio-",
    ".github/actions/upload-artifact/",
    "scripts/test_evidencia_",
    "scripts/test_kubasta_visual_gate_",
    "scripts/test_cata_",
    "scripts/test_laboratorio_",
)
EVIDENCE_EXACT = {
    ".github/workflows/benchmark-cc0.yml",
    "scripts/test_benchmark_cc0.py",
    "scripts/test_upload_artifact_wrapper_1888.py",
}


def is_evidence_path(path: str) -> bool:
    normalized = path.strip().replace("\\", "/")
    if not normalized:
        return False
    if normalized in EVIDENCE_EXACT:
        return True
    if not normalized.startswith(EVIDENCE_PREFIXES):
        return False
    if normalized.startswith(".github/workflows/"):
        return normalized.endswith(".yml")
    if normalized.startswith("scripts/"):
        return normalized.endswith(".py")
    return normalized.startswith(".github/actions/upload-artifact/")


def is_fast_path(path: str) -> bool:
    normalized = path.strip().replace("\\", "/")
    if not normalized:
        return False
    return normalized in FAST_EXACT or normalized.startswith(FAST_PREFIXES)


def classify(paths: Iterable[str]) -> dict[str, object]:
    clean = sorted({path.strip().replace("\\", "/") for path in paths if path.strip()})
    if not clean:
        return {"mode": "full", "files": [], "reason": "diff-vacio"}

    outside_fast = [path for path in clean if not is_fast_path(path)]
    if not outside_fast:
        return {
            "mode": "fast",
            "files": clean,
            "outside": [],
            "reason": "solo-infra-agentes",
        }

    outside_evidence = [path for path in clean if not is_evidence_path(path)]
    if not outside_evidence:
        return {
            "mode": "evidence",
            "files": clean,
            "outside": [],
            "reason": "solo-evidencias",
        }

    return {
        "mode": "full",
        "files": clean,
        "outside": outside_evidence,
        "reason": "ruta-no-fast",
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
