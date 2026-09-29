#!/usr/bin/env python3
"""Materializa contexto de issue usando solo fuentes GitHub de confianza."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

TRUSTED_ASSOCIATIONS = {"OWNER", "MEMBER", "COLLABORATOR"}
TRUSTED_BOTS = {"github-actions[bot]"}


def _login(source: dict[str, Any]) -> str:
    author = source.get("user") or source.get("author")
    if isinstance(author, dict):
        value = author.get("login")
        return value.strip() if isinstance(value, str) else ""
    if isinstance(author, str):
        return author.strip()
    return ""


def _association(source: dict[str, Any]) -> str:
    value = source.get("author_association") or source.get("authorAssociation") or ""
    return str(value).strip().upper()


def trusted(source: dict[str, Any]) -> bool:
    login = _login(source)
    return _association(source) in TRUSTED_ASSOCIATIONS or login in TRUSTED_BOTS


def render_context(
    issue: dict[str, Any],
    comments: list[dict[str, Any]],
    *,
    max_comments: int,
) -> str:
    if not trusted(issue):
        raise PermissionError("autor del issue no confiable para ejecución automática")

    title = str(issue.get("title") or "").strip()
    body = str(issue.get("body") or "").strip()
    accepted = [comment for comment in comments if trusted(comment)]
    if max_comments >= 0:
        accepted = accepted[-max_comments:] if max_comments else []

    lines = ["# Issue", "", f"## {title}", "", body, "", "## Comentarios recientes"]
    for comment in accepted:
        comment_body = str(comment.get("body") or "").strip()
        if not comment_body:
            continue
        lines.extend(["", f"- {_login(comment)}: {comment_body}"])
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--issue", required=True, type=Path)
    parser.add_argument("--comments", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--max-comments", type=int, default=20)
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args()

    issue = json.loads(args.issue.read_text(encoding="utf-8"))
    if not isinstance(issue, dict):
        raise SystemExit("--issue debe contener un objeto JSON")
    if not trusted(issue):
        print(json.dumps({"trusted": False}, separators=(",", ":")))
        return 3
    if args.check_only:
        print(json.dumps({"trusted": True}, separators=(",", ":")))
        return 0

    if args.comments is None or args.output is None:
        raise SystemExit("--comments y --output son obligatorios salvo con --check-only")
    comments = json.loads(args.comments.read_text(encoding="utf-8"))
    if not isinstance(comments, list):
        raise SystemExit("--comments debe contener un array JSON")

    args.output.write_text(
        render_context(issue, comments, max_comments=max(0, args.max_comments)),
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "trusted": True,
                "trusted_comments": sum(1 for comment in comments if trusted(comment)),
                "total_comments": len(comments),
            },
            separators=(",", ":"),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
