#!/usr/bin/env python3
"""Agrega telemetría compacta de handoff/rework de PRs del agent pool."""

from __future__ import annotations

import argparse
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import re
from statistics import mean
from typing import Any

TITLE_RE = re.compile(r"^agent\((?P<provider>qwen|gemini)\):\s+#\d+\b", re.I)
WORKER_RE = re.compile(r"worker\s+\x60(?P<worker>[A-Za-z0-9._-]+)\x60")
RESULT_RE = re.compile(
    r"ResultPacket\s+(?P<valid>true|false)/(?P<status>done|partial|blocked|failed|missing);"
    r"\s+handoff-loss proxy\s+(?P<loss>\d+(?:\.\d+)?)%",
    re.I,
)
REVIEW_RE = re.compile(
    r"Reviewer acotado:\s+\x60(?P<status>[A-Za-z0-9._-]+)/(?P<verdict>[A-Za-z0-9._-]+)\x60",
    re.I,
)
CI_FAILURES = {
    "ACTION_REQUIRED",
    "CANCELLED",
    "ERROR",
    "FAILURE",
    "STALE",
    "TIMED_OUT",
}
CI_SUCCESSES = {"SUCCESS", "NEUTRAL", "SKIPPED"}


def _commit_count(pr: dict[str, Any]) -> int:
    commits = pr.get("commits")
    if isinstance(commits, list):
        return len(commits)
    try:
        return max(0, int(commits))
    except (TypeError, ValueError):
        return 0


def _parse_time(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value.strip():
        return None
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _observed_at(pr: dict[str, Any]) -> datetime | None:
    for key in ("mergedAt", "closedAt", "updatedAt", "createdAt"):
        parsed = _parse_time(pr.get(key))
        if parsed is not None:
            return parsed
    return None


def _ci_state(pr: dict[str, Any]) -> str:
    rollup = pr.get("statusCheckRollup")
    if not isinstance(rollup, list):
        return "missing"

    relevant: list[dict[str, Any]] = []
    for item in rollup:
        if not isinstance(item, dict):
            continue
        workflow = str(item.get("workflowName") or "").strip().casefold()
        name = str(item.get("name") or item.get("context") or "").strip().casefold()
        if workflow == "ci" or name == "ci":
            relevant.append(item)
    if not relevant:
        return "missing"

    pending = False
    successes = 0
    for item in relevant:
        conclusion = str(item.get("conclusion") or item.get("state") or "").strip().upper()
        status = str(item.get("status") or "").strip().upper()
        if conclusion in CI_FAILURES:
            return "failure"
        if conclusion in CI_SUCCESSES:
            successes += 1
            continue
        if conclusion in {"PENDING", "EXPECTED"} or (status and status != "COMPLETED"):
            pending = True
            continue
        if not conclusion:
            pending = True

    if pending:
        return "pending"
    return "success" if successes else "missing"


def parse_agent_pr(pr: dict[str, Any]) -> dict[str, Any] | None:
    title = pr.get("title")
    body = pr.get("body")
    if not isinstance(title, str) or not isinstance(body, str):
        return None

    title_match = TITLE_RE.search(title.strip())
    worker_match = WORKER_RE.search(body)
    result_match = RESULT_RE.search(body)
    if not title_match or not worker_match or not result_match:
        return None

    observed = _observed_at(pr)
    review_match = REVIEW_RE.search(body)
    valid = result_match.group("valid").lower() == "true"
    status = result_match.group("status").lower()
    loss = min(100.0, max(0.0, float(result_match.group("loss"))))
    review_verdict = (
        review_match.group("verdict").lower() if review_match else "missing"
    )
    commits = _commit_count(pr)
    rework_signal = review_verdict == "findings" or commits > 1

    return {
        "number": pr.get("number"),
        "provider": title_match.group("provider").lower(),
        "worker": worker_match.group("worker"),
        "result_valid": valid,
        "result_status": status,
        "handoff_loss_proxy_pct": loss,
        "review_verdict": review_verdict,
        "commit_count": commits,
        "rework_signal": rework_signal,
        "ci_state": _ci_state(pr),
        "observed_at": observed,
    }


def aggregate_prs(
    prs: list[dict[str, Any]],
    *,
    window_days: int = 30,
    now: datetime | None = None,
) -> dict[str, dict[str, Any]]:
    if window_days < 1:
        raise ValueError("window_days debe ser >= 1")
    current = now or datetime.now(timezone.utc)
    if current.tzinfo is None:
        current = current.replace(tzinfo=timezone.utc)
    current = current.astimezone(timezone.utc)
    cutoff = current - timedelta(days=window_days)

    grouped: dict[str, list[dict[str, Any]]] = {}
    for pr in prs:
        if not isinstance(pr, dict):
            continue
        parsed = parse_agent_pr(pr)
        if parsed is None:
            continue
        observed = parsed.get("observed_at")
        if not isinstance(observed, datetime) or observed < cutoff or observed > current:
            continue
        grouped.setdefault(parsed["worker"], []).append(parsed)

    result: dict[str, dict[str, Any]] = {}
    for worker, samples in grouped.items():
        samples.sort(
            key=lambda item: (
                item["observed_at"],
                int(item.get("number") or 0)
                if str(item.get("number") or "").isdigit()
                else 0,
            ),
            reverse=True,
        )
        recent = samples[:50]
        total = len(recent)
        if not total:
            continue

        ci_success = sum(item["ci_state"] == "success" for item in recent)
        ci_failure = sum(item["ci_state"] == "failure" for item in recent)
        ci_pending = sum(item["ci_state"] == "pending" for item in recent)
        ci_observed = ci_success + ci_failure + ci_pending
        ci_terminal = ci_success + ci_failure

        result[worker] = {
            "provider": recent[0]["provider"],
            "samples": total,
            "window_days": window_days,
            "newest_sample_at": recent[0]["observed_at"].isoformat(),
            "oldest_sample_at": recent[-1]["observed_at"].isoformat(),
            "handoff_loss_proxy_pct": round(
                mean(float(item["handoff_loss_proxy_pct"]) for item in recent), 2
            ),
            "contract_valid_rate_pct": round(
                100.0 * sum(bool(item["result_valid"]) for item in recent) / total, 2
            ),
            "rework_rate_pct": round(
                100.0 * sum(bool(item["rework_signal"]) for item in recent) / total, 2
            ),
            "review_findings_rate_pct": round(
                100.0
                * sum(item["review_verdict"] == "findings" for item in recent)
                / total,
                2,
            ),
            "partial_or_blocked_rate_pct": round(
                100.0
                * sum(item["result_status"] in {"partial", "blocked"} for item in recent)
                / total,
                2,
            ),
            "ci_observed_rate_pct": round(100.0 * ci_observed / total, 2),
            "ci_success_rate_pct": (
                round(100.0 * ci_success / ci_terminal, 2) if ci_terminal else None
            ),
            "ci_failure_rate_pct": (
                round(100.0 * ci_failure / ci_terminal, 2) if ci_terminal else None
            ),
            "ci_pending_samples": ci_pending,
        }
    return result


def _parse_now(value: str) -> datetime | None:
    if not value:
        return None
    parsed = _parse_time(value)
    if parsed is None:
        raise ValueError("--now debe ser ISO-8601")
    return parsed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prs", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--window-days", type=int, default=30)
    parser.add_argument("--now", default="")
    args = parser.parse_args()

    data = json.loads(args.prs.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise SystemExit("--prs debe ser una lista JSON")

    try:
        result = aggregate_prs(
            [item for item in data if isinstance(item, dict)],
            window_days=args.window_days,
            now=_parse_now(args.now),
        )
    except ValueError as error:
        raise SystemExit(str(error)) from error

    args.output.write_text(
        json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
