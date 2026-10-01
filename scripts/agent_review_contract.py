#!/usr/bin/env python3
"""Contrato mínimo del reviewer diff-only del agent pool."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
from typing import Any

PATTERN = re.compile(
    r"AGENT_REVIEW_BEGIN\s*(?:```(?:json)?\s*)?(\{.*?\})(?:\s*```)?\s*AGENT_REVIEW_END",
    re.IGNORECASE | re.DOTALL,
)


def parse_review(raw: str, nonce: str | None = None) -> dict[str, Any]:
    match = PATTERN.search(raw or "")
    if not match:
        return {"status": "skipped", "verdict": None, "findings": []}
    try:
        data = json.loads(match.group(1))
    except json.JSONDecodeError:
        return {"status": "skipped", "verdict": None, "findings": []}

    # El código de lectura solo está dentro de .agent-review-input.md: si no
    # vuelve, el modelo contestó sin leer el diff y su veredicto no vale (#2038).
    if nonce and str(data.get("input_nonce") or "").strip() != nonce:
        return {"status": "blind", "verdict": None, "findings": []}

    verdict = data.get("verdict")
    findings = data.get("findings", [])
    if verdict not in {"approve", "findings"} or not isinstance(findings, list):
        return {"status": "skipped", "verdict": None, "findings": []}

    clean: list[str] = []
    for item in findings[:5]:
        if not isinstance(item, str):
            return {"status": "skipped", "verdict": None, "findings": []}
        item = " ".join(item.split()).strip()
        if item:
            clean.append(item[:240])

    if verdict == "approve":
        clean = []
    elif not clean:
        return {"status": "skipped", "verdict": None, "findings": []}

    return {"status": "ok", "verdict": verdict, "findings": clean}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--summary-file", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--nonce", default="", help="código de lectura escrito en el input")
    args = parser.parse_args()
    raw = args.summary_file.read_text(encoding="utf-8") if args.summary_file.exists() else ""
    result = parse_review(raw, args.nonce.strip() or None)
    rendered = json.dumps(result, ensure_ascii=False, separators=(",", ":"))
    args.output.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
