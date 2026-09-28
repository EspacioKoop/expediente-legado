#!/usr/bin/env python3
"""Reconciliador conservador de estado para el pool de agentes."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
from typing import Any

CLAIM_RE = re.compile(
    r"^CLAIM\s+issue=#(?P<issue>\d+).*?\bbranch=(?P<branch>[^\s]+).*?\bfiles=(?P<files>[^\s]+)",
    re.MULTILINE,
)
RELEASE_RE = re.compile(
    r"^RELEASE\s+issue=#(?P<issue>\d+)(?:.*?\bbranch=(?P<branch>[^\s]+))?",
    re.MULTILINE,
)
RUN_ID_RE = re.compile(r"-(?P<run>\d+)$")
TERMINAL_CONCLUSIONS = {
    "cancelled", "failure", "timed_out", "action_required",
    "startup_failure", "stale", "success",
}


def _labels(issue: dict[str, Any]) -> set[str]:
    result: set[str] = set()
    raw = issue.get("labels", [])
    if not isinstance(raw, list):
        return result
    for item in raw:
        if isinstance(item, str):
            result.add(item)
        elif isinstance(item, dict) and isinstance(item.get("name"), str):
            result.add(item["name"])
    return result


def _parse_time(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(timezone.utc)
    except ValueError:
        return None


def active_claims(comments: list[dict[str, Any]]) -> dict[int, dict[str, str]]:
    active: dict[tuple[int, str], dict[str, str]] = {}
    for comment in comments:
        body = comment.get("body", "") if isinstance(comment, dict) else ""
        if not isinstance(body, str):
            continue
        for match in RELEASE_RE.finditer(body):
            issue = int(match.group("issue"))
            branch = match.group("branch")
            for key in list(active):
                if key[0] == issue and (not branch or key[1] == branch):
                    del active[key]
        for match in CLAIM_RE.finditer(body):
            issue = int(match.group("issue"))
            branch = match.group("branch")
            active[(issue, branch)] = {
                "issue": str(issue),
                "branch": branch,
                "files": match.group("files"),
            }

    latest: dict[int, dict[str, str]] = {}
    for (issue, _branch), claim in active.items():
        latest[issue] = claim
    return latest


def _run_id(branch: str | None) -> int | None:
    if not branch or not branch.startswith("agent/"):
        return None
    match = RUN_ID_RE.search(branch)
    return int(match.group("run")) if match else None


def discover_run_ids(
    issues: list[dict[str, Any]],
    comments: list[dict[str, Any]],
) -> list[int]:
    claims = active_claims(comments)
    result: set[int] = set()
    for issue in issues:
        try:
            number = int(issue.get("number"))
        except (TypeError, ValueError):
            continue
        if "agent:working" not in _labels(issue):
            continue
        claim = claims.get(number)
        if not claim:
            continue
        run_id = _run_id(claim.get("branch"))
        if run_id is not None:
            result.add(run_id)
    return sorted(result)


def reconcile(
    issues: list[dict[str, Any]],
    comments: list[dict[str, Any]],
    prs: list[dict[str, Any]],
    runs: list[dict[str, Any]],
    *,
    now: datetime,
    ttl_minutes: int = 90,
) -> list[dict[str, Any]]:
    claims = active_claims(comments)
    run_map = {
        int(run["id"]): run
        for run in runs
        if isinstance(run, dict) and str(run.get("id", "")).isdigit()
    }
    open_pr_heads = {
        str(pr.get("headRefName") or pr.get("head_ref") or pr.get("head") or "")
        for pr in prs
        if isinstance(pr, dict)
        and str(pr.get("state", "OPEN")).upper() in {"OPEN", "OPENED"}
    }
    ttl_seconds = max(15, ttl_minutes) * 60
    actions: list[dict[str, Any]] = []

    for issue in issues:
        try:
            number = int(issue.get("number"))
        except (TypeError, ValueError):
            continue
        labels = _labels(issue)
        claim = claims.get(number)
        branch = claim.get("branch") if claim else None

        if "agent:working" in labels:
            if claim is None:
                actions.append(
                    {"issue": number, "action": "requeue", "reason": "working-without-claim"}
                )
                continue
            if not branch or not branch.startswith("agent/"):
                actions.append(
                    {"issue": number, "action": "keep", "reason": "non-pool-claim"}
                )
                continue
            if branch in open_pr_heads:
                actions.append(
                    {
                        "issue": number,
                        "action": "pr_open",
                        "branch": branch,
                        "reason": "open-pr",
                    }
                )
                continue

            run_id = _run_id(branch)
            run = run_map.get(run_id) if run_id is not None else None
            if run is not None:
                status = str(run.get("status", "")).lower()
                conclusion = str(run.get("conclusion") or "").lower()
                if status in {"queued", "in_progress", "waiting", "requested", "pending"}:
                    actions.append(
                        {
                            "issue": number,
                            "action": "keep",
                            "branch": branch,
                            "run_id": run_id,
                            "reason": f"run-{status}",
                        }
                    )
                    continue
                if status == "completed" or conclusion in TERMINAL_CONCLUSIONS:
                    actions.append(
                        {
                            "issue": number,
                            "action": "requeue",
                            "branch": branch,
                            "run_id": run_id,
                            "reason": f"run-{conclusion or status}",
                        }
                    )
                    continue

            updated = _parse_time(issue.get("updatedAt") or issue.get("updated_at"))
            stale = updated is not None and (now - updated).total_seconds() >= ttl_seconds
            if stale:
                actions.append(
                    {
                        "issue": number,
                        "action": "requeue",
                        "branch": branch,
                        "run_id": run_id,
                        "reason": "stale-working",
                    }
                )
            else:
                actions.append(
                    {
                        "issue": number,
                        "action": "keep",
                        "branch": branch,
                        "run_id": run_id,
                        "reason": "run-unknown-not-stale",
                    }
                )
            continue

        if "agent:pr-open" in labels and claim is None:
            has_open_pr = False
            if branch:
                has_open_pr = branch in open_pr_heads
            if not has_open_pr:
                actions.append(
                    {"issue": number, "action": "requeue", "reason": "pr-open-without-pr"}
                )

    return actions


def _read_list(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise SystemExit(f"{path} debe contener una lista JSON")
    return [item for item in data if isinstance(item, dict)]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("discover", "reconcile"))
    parser.add_argument("--issues", type=Path, required=True)
    parser.add_argument("--comments", type=Path, required=True)
    parser.add_argument("--prs", type=Path)
    parser.add_argument("--runs", type=Path)
    parser.add_argument("--ttl-minutes", type=int, default=90)
    parser.add_argument("--now")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    issues = _read_list(args.issues)
    comments = _read_list(args.comments)

    if args.mode == "discover":
        result: Any = {"run_ids": discover_run_ids(issues, comments)}
    else:
        if not args.prs or not args.runs:
            raise SystemExit("reconcile requiere --prs y --runs")
        now = _parse_time(args.now) if args.now else datetime.now(timezone.utc)
        if now is None:
            raise SystemExit("--now inválido")
        result = {
            "actions": reconcile(
                issues,
                comments,
                _read_list(args.prs),
                _read_list(args.runs),
                now=now,
                ttl_minutes=args.ttl_minutes,
            )
        }

    rendered = json.dumps(result, ensure_ascii=False, separators=(",", ":"))
    if args.output:
        args.output.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
