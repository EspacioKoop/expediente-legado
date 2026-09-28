#!/usr/bin/env python3
"""Selecciona el plan delegado más reciente de una fuente GitHub confiable."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Iterator

BEGIN = "AGENT_PLAN_BEGIN"
END = "AGENT_PLAN_END"
TRUSTED_ASSOCIATIONS = {"OWNER", "MEMBER", "COLLABORATOR"}


def _author_login(source: dict[str, Any]) -> str:
    author = source.get("author") or source.get("user")
    if isinstance(author, dict):
        login = author.get("login")
        return login.strip() if isinstance(login, str) else ""
    if isinstance(author, str):
        return author.strip()
    return ""


def _association(source: dict[str, Any]) -> str:
    raw = source.get("authorAssociation") or source.get("author_association") or ""
    return str(raw).strip().upper()


def _trusted(source: dict[str, Any]) -> bool:
    login = _author_login(source)
    if not login or login.lower().endswith("[bot]"):
        return False
    author = source.get("author") or source.get("user")
    if isinstance(author, dict):
        kind = str(author.get("__typename") or author.get("type") or "").lower()
        if kind == "bot":
            return False
    return _association(source) in TRUSTED_ASSOCIATIONS


def _valid_plan(value: Any) -> dict[str, Any] | None:
    if not isinstance(value, dict):
        return None
    files = value.get("files")
    goal = value.get("goal")
    if not isinstance(files, list) or not all(
        isinstance(item, str) and item.strip() for item in files
    ):
        return None
    if not isinstance(goal, str) or not goal.strip():
        return None
    return {"files": files, "goal": goal.strip()}


def _payloads(body: str) -> Iterator[dict[str, Any]]:
    """Extrae planes con marcadores en líneas propias, fuera de fences Markdown."""
    if not isinstance(body, str) or not body:
        return

    in_fence = False
    fence = ""
    collecting = False
    buffer: list[str] = []

    for raw_line in body.splitlines():
        stripped = raw_line.strip()
        fence_token = ""
        if stripped.startswith("```"):
            fence_token = "```"
        elif stripped.startswith("~~~"):
            fence_token = "~~~"

        if collecting:
            if stripped == END:
                payload = "\n".join(buffer).strip()
                collecting = False
                buffer = []
                try:
                    parsed = json.loads(payload)
                except (json.JSONDecodeError, TypeError):
                    continue
                valid = _valid_plan(parsed)
                if valid is not None:
                    yield valid
                continue
            if fence_token:
                continue
            buffer.append(raw_line)
            continue

        if fence_token:
            if not in_fence:
                in_fence = True
                fence = fence_token
            elif fence_token == fence:
                in_fence = False
                fence = ""
            continue

        if in_fence:
            continue

        if stripped == BEGIN:
            collecting = True
            buffer = []
            continue


def select_delegated_plan(issue: dict[str, Any]) -> dict[str, Any] | None:
    """Devuelve el último plan válido de issue/comentarios de confianza."""
    sources: list[tuple[str, dict[str, Any]]] = [("issue", issue)]
    comments = issue.get("comments", [])
    if isinstance(comments, list):
        sources.extend(
            ("comment", item) for item in comments if isinstance(item, dict)
        )

    selected: dict[str, Any] | None = None
    for source_kind, source in sources:
        if not _trusted(source):
            continue
        body = source.get("body")
        if not isinstance(body, str):
            continue
        for plan in _payloads(body):
            selected = {
                "source": source_kind,
                "author": _author_login(source),
                "plan": plan,
            }
    return selected


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--issue", type=Path, required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    raw = json.loads(args.issue.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise SystemExit("--issue debe ser un objeto JSON")

    selected = select_delegated_plan(raw)
    result = {"found": selected is not None}
    if selected is not None:
        result.update(selected)

    rendered = json.dumps(result, ensure_ascii=False, separators=(",", ":"))
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
