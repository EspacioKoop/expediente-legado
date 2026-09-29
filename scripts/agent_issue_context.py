#!/usr/bin/env python3
"""Materializa contexto de issue usando solo fuentes GitHub de confianza."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
from typing import Any

TRUSTED_ASSOCIATIONS = {"OWNER", "MEMBER", "COLLABORATOR"}
TRUSTED_BOTS = {"github-actions[bot]"}
B2B_TYPES = {"TASK", "CLAIM", "EVIDENCE", "BLOCKER", "QUESTION", "RESULT", "REVIEW", "HANDOFF"}
B2B_RE = re.compile(
    r"AGENT_B2B_BEGIN\s*(?:```(?:json)?\s*)?(\{.*?\})(?:\s*```)?\s*AGENT_B2B_END",
    re.IGNORECASE | re.DOTALL,
)


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


def _b2b_events(comment: dict[str, Any]) -> list[dict[str, Any]]:
    if not trusted(comment):
        return []
    body = str(comment.get("body") or "")
    events: list[dict[str, Any]] = []
    for match in B2B_RE.finditer(body):
        try:
            data = json.loads(match.group(1))
        except json.JSONDecodeError:
            continue
        if not isinstance(data, dict) or data.get("schema") != 1:
            continue
        if data.get("type") not in B2B_TYPES:
            continue
        handoff = data.get("handoff")
        if not isinstance(handoff, dict):
            continue
        source = handoff.get("from")
        target = handoff.get("to")
        if not isinstance(source, str) or not source.strip():
            continue
        if not isinstance(target, str) or not target.strip():
            continue
        issue = data.get("issue")
        if not isinstance(issue, int) or isinstance(issue, bool) or issue <= 0:
            continue
        summary = " ".join(str(data.get("summary") or "").split())[:500]
        refs = data.get("refs")
        clean_refs = []
        if isinstance(refs, list):
            clean_refs = [
                " ".join(item.split())[:240]
                for item in refs[:16]
                if isinstance(item, str) and item.strip()
            ]
        events.append(
            {
                "type": data["type"],
                "issue": issue,
                "from": source.strip(),
                "to": target.strip(),
                "summary": summary,
                "refs": clean_refs,
            }
        )
    return events


def _without_b2b_blocks(body: str) -> str:
    return B2B_RE.sub("", body).strip()


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
    events: list[dict[str, Any]] = []
    for comment in accepted:
        events.extend(_b2b_events(comment))
        comment_body = _without_b2b_blocks(str(comment.get("body") or ""))
        if not comment_body:
            continue
        lines.extend(["", f"- {_login(comment)}: {comment_body}"])

    if events:
        lines.extend(["", "## Eventos B2B recientes"])
        for event in events:
            refs = ",".join(event["refs"]) if event["refs"] else "-"
            lines.extend(
                [
                    "",
                    (
                        f"- {event['type']} issue=#{event['issue']} "
                        f"{event['from']}→{event['to']} "
                        f"summary={event['summary'] or '-'} refs={refs}"
                    ),
                ]
            )
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
