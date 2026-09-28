#!/usr/bin/env python3
"""Compara el contrato health esperado por main.ts con un /health desplegado."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
from typing import Any

VERSION_RE = re.compile(r"\bversion:\s*(\d+)\s*,")
FEATURE_RE = re.compile(r"^\s*(agent_[a-z0-9_]+):\s*true\s*,?\s*$", re.MULTILINE)


def expected_contract(source: str) -> dict[str, Any]:
    match = VERSION_RE.search(source)
    if not match:
        raise ValueError("main.ts no declara version en /health")
    features = sorted(set(FEATURE_RE.findall(source)))
    return {
        "version": int(match.group(1)),
        "features": features,
    }


def validate_health(source: str, health: dict[str, Any]) -> list[str]:
    expected = expected_contract(source)
    errors: list[str] = []

    if health.get("ok") is not True:
        errors.append("health.ok != true")
    if health.get("service") != "siga98-feedback-deno":
        errors.append("health.service inesperado")
    if health.get("version") != expected["version"]:
        errors.append(
            f"version desplegada={health.get('version')!r} esperada={expected['version']}"
        )

    for feature in expected["features"]:
        if health.get(feature) is not True:
            errors.append(f"{feature} no está activo en producción")

    if health.get("kv_configured") is not True:
        errors.append("kv_configured != true")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--health-json", type=Path, required=True)
    args = parser.parse_args()

    source = args.source.read_text(encoding="utf-8")
    health = json.loads(args.health_json.read_text(encoding="utf-8"))
    if not isinstance(health, dict):
        raise SystemExit("/health debe devolver un objeto JSON")

    expected = expected_contract(source)
    errors = validate_health(source, health)
    print(
        json.dumps(
            {
                "expected": expected,
                "deployed_version": health.get("version"),
                "errors": errors,
            },
            ensure_ascii=False,
        )
    )
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
