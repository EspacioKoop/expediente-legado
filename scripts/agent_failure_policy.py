#!/usr/bin/env python3
"""Clasifica fallos del agent pool y propone una acción sin ejecutarla."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re

QUOTA_RE = re.compile(
    r"(^|[^0-9])(429|503)([^0-9]|$)|"
    r"quota exceeded|terminalquotaerror|retryablequotaerror|"
    r"resource_exhausted|rate.?limit|high demand|temporarily unavailable|overloaded",
    re.I,
)
TIMEOUT_RE = re.compile(r"timed? out|timeout|fatalturnlimitederror|maxsessionturns", re.I)
PROVIDER_RE = re.compile(
    r"service unavailable|connection reset|connection refused|gateway|"
    r"provider error|transport error|network error",
    re.I,
)
TEST_RE = re.compile(
    r"\bfailed\b|\bfailure\b|assertionerror|traceback|parse error|"
    r"script error|would reformat|gdlint|unittest",
    re.I,
)

ACTIONS = {
    "quota_or_overload": "rotate_provider",
    "claim_drift": "expand_claim",
    "no_changes": "stop_noop",
    "cancelled": "requeue_neutral",
    "timeout": "split_or_same_worker",
    "test_or_preflight": "same_worker_fix",
    "provider_or_transport": "rotate_provider",
    "unknown": "human_review",
}


def read_text_files(paths: list[Path], *, max_bytes: int = 65536) -> str:
    """Lee logs acotados sin meter salidas grandes en argv/env (#1881)."""
    chunks: list[str] = []
    remaining = max(0, int(max_bytes))
    for path in paths:
        if remaining <= 0:
            break
        try:
            data = path.read_bytes()[:remaining]
        except OSError:
            continue
        remaining -= len(data)
        chunks.append(data.decode("utf-8", "replace"))
    return "\n".join(chunks)


def classify_failure(
    *,
    stage: str,
    job_status: str = "",
    claim_drift: bool = False,
    no_changes: bool = False,
    text: str = "",
) -> dict[str, str]:
    """Devuelve categoría y acción; las señales semánticas ganan al texto."""
    stage = str(stage or "").strip().lower()
    job_status = str(job_status or "").strip().lower()
    text = str(text or "")

    if job_status == "cancelled":
        category = "cancelled"
    elif claim_drift:
        category = "claim_drift"
    elif no_changes:
        category = "no_changes"
    elif QUOTA_RE.search(text):
        category = "quota_or_overload"
    elif TIMEOUT_RE.search(text):
        category = "timeout"
    elif PROVIDER_RE.search(text):
        category = "provider_or_transport"
    elif stage in {"validating", "preflight", "ci", "review"} and TEST_RE.search(text):
        category = "test_or_preflight"
    elif stage in {"implement", "implementing"} and TEST_RE.search(text):
        category = "test_or_preflight"
    else:
        category = "unknown"

    return {
        "category": category,
        "action": ACTIONS[category],
        "stage": stage or "unknown",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stage", required=True)
    parser.add_argument("--job-status", default="")
    parser.add_argument("--claim-drift", action="store_true")
    parser.add_argument("--no-changes", action="store_true")
    parser.add_argument("--text", default="")
    parser.add_argument("--text-file", type=Path, action="append", default=[])
    args = parser.parse_args()

    text = args.text
    file_text = read_text_files(args.text_file)
    if file_text:
        text = text + ("\n" if text else "") + file_text

    result = classify_failure(
        stage=args.stage,
        job_status=args.job_status,
        claim_drift=args.claim_drift,
        no_changes=args.no_changes,
        text=text,
    )
    print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
