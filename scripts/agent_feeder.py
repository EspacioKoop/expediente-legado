#!/usr/bin/env python3
"""Selecciona de forma conservadora un issue para alimentar la pool.

No modifica GitHub. Recibe snapshots JSON de issues y PRs abiertos y devuelve
como máximo un candidato que debe pasar primero por agent:decompose.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
from typing import Any

BLOCKING_LABELS = {
    "estado:validacion-humana",
    "prioridad:P0",
    "agent:no-auto",
}
BLOCKING_PREFIXES = ("agent:",)
BLOCKING_TITLE_PREFIXES = ("playtest:", "épica:", "epica:")
BLOCKING_TITLE_FRAGMENTS = (
    "reservas entre agentes",
    "registro único de reservas",
    "registro unico de reservas",
)
PR_REF_RE = re.compile(
    r"(?im)\b(?:refs?|fix(?:es|ed)?|clos(?:es|ed)?|resolv(?:es|ed)?)\s+#(\d+)\b"
)


def _labels(issue: dict[str, Any]) -> set[str]:
    result: set[str] = set()
    for raw in issue.get("labels", []):
        if isinstance(raw, str):
            result.add(raw)
        elif isinstance(raw, dict) and isinstance(raw.get("name"), str):
            result.add(raw["name"])
    return result


def _parse_time(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def referenced_issues(prs: list[dict[str, Any]]) -> set[int]:
    refs: set[int] = set()
    for pr in prs:
        body = pr.get("body")
        if not isinstance(body, str):
            continue
        refs.update(int(match.group(1)) for match in PR_REF_RE.finditer(body))
    return refs


def eligible(
    issue: dict[str, Any],
    *,
    open_pr_refs: set[int],
    now: datetime,
    min_age_minutes: int,
) -> tuple[bool, str]:
    try:
        number = int(issue.get("number", 0))
    except (TypeError, ValueError):
        return False, "numero-invalido"
    if number <= 0:
        return False, "numero-invalido"
    if number in open_pr_refs:
        return False, "pr-abierto"

    labels = _labels(issue)
    if labels & BLOCKING_LABELS:
        return False, "label-bloqueante"
    if any(label.startswith(BLOCKING_PREFIXES) for label in labels):
        return False, "estado-agente"

    title = str(issue.get("title") or "").strip()
    lower = title.lower()
    if not title:
        return False, "sin-titulo"
    if lower.startswith(BLOCKING_TITLE_PREFIXES):
        return False, "tipo-humano"
    if any(fragment in lower for fragment in BLOCKING_TITLE_FRAGMENTS):
        return False, "meta-reservas"

    body = str(issue.get("body") or "").strip()
    if len(body) < 80:
        return False, "sin-contexto"

    updated = _parse_time(issue.get("updatedAt") or issue.get("updated_at"))
    if updated is not None:
        age = (now - updated.astimezone(timezone.utc)).total_seconds() / 60
        if age < min_age_minutes:
            return False, "activo-reciente"

    return True, "ok"


def score(issue: dict[str, Any]) -> tuple[int, str, int]:
    labels = _labels(issue)
    title = str(issue.get("title") or "")
    points = 0

    if "bug" in labels:
        points += 40
    if "prioridad:P3" in labels:
        points += 25
    elif "prioridad:P2" in labels:
        points += 15
    elif "prioridad:P1" in labels:
        points += 5

    lowered = title.lower()
    if lowered.startswith("infra(") or lowered.startswith("infra:"):
        points += 30
    if lowered.startswith("test(") or lowered.startswith("test:"):
        points += 25
    if "area:accesibilidad" in labels:
        points += 5

    created = str(issue.get("createdAt") or issue.get("created_at") or "")
    try:
        number = int(issue.get("number", 0))
    except (TypeError, ValueError):
        number = 0
    return (-points, created, number)


def select_candidate(
    issues: list[dict[str, Any]],
    prs: list[dict[str, Any]],
    *,
    now: datetime,
    min_age_minutes: int = 90,
) -> dict[str, Any]:
    refs = referenced_issues(prs)
    eligible_items: list[dict[str, Any]] = []
    rejected: dict[str, int] = {}

    for issue in issues:
        ok, reason = eligible(
            issue,
            open_pr_refs=refs,
            now=now,
            min_age_minutes=min_age_minutes,
        )
        if ok:
            eligible_items.append(issue)
        else:
            rejected[reason] = rejected.get(reason, 0) + 1

    eligible_items.sort(key=score)
    selected = eligible_items[0] if eligible_items else None
    return {
        "selected": (
            {
                "number": int(selected["number"]),
                "title": str(selected.get("title") or ""),
                "score": -score(selected)[0],
            }
            if selected
            else None
        ),
        "eligible": len(eligible_items),
        "rejected": rejected,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--issues", required=True, type=Path)
    parser.add_argument("--prs", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--now")
    parser.add_argument("--min-age-minutes", type=int, default=90)
    args = parser.parse_args()

    issues = json.loads(args.issues.read_text(encoding="utf-8"))
    prs = json.loads(args.prs.read_text(encoding="utf-8"))
    if not isinstance(issues, list) or not isinstance(prs, list):
        raise SystemExit("issues/prs deben ser arrays JSON")

    now = (
        datetime.fromisoformat(args.now.replace("Z", "+00:00"))
        if args.now
        else datetime.now(timezone.utc)
    )
    result = select_candidate(
        issues,
        prs,
        now=now.astimezone(timezone.utc),
        min_age_minutes=max(0, args.min_age_minutes),
    )
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
