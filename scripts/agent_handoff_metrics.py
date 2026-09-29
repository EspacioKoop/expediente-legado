#!/usr/bin/env python3
"""Agrega telemetría compacta de handoff/rework de PRs del agent pool."""

from __future__ import annotations

import argparse
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


def _commit_count(pr: dict[str, Any]) -> int:
    commits = pr.get("commits")
    if isinstance(commits, list):
        return len(commits)
    try:
        return max(0, int(commits))
    except (TypeError, ValueError):
        return 0


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
    }


def aggregate_prs(prs: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = {}
    for pr in prs:
        if not isinstance(pr, dict):
            continue
        parsed = parse_agent_pr(pr)
        if parsed is None:
            continue
        grouped.setdefault(parsed["worker"], []).append(parsed)

    result: dict[str, dict[str, Any]] = {}
    for worker, samples in grouped.items():
        samples.sort(
            key=lambda item: int(item.get("number") or 0)
            if str(item.get("number") or "").isdigit()
            else 0,
            reverse=True,
        )
        recent = samples[:50]
        total = len(recent)
        if not total:
            continue

        result[worker] = {
            "provider": recent[0]["provider"],
            "samples": total,
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
        }
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prs", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    data = json.loads(args.prs.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise SystemExit("--prs debe ser una lista JSON")

    result = aggregate_prs([item for item in data if isinstance(item, dict)])
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
