#!/usr/bin/env python3
"""Reconciliador conservador de estado para el pool de agentes."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
from typing import Any

import reservas_registro

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


def active_claims(
    comments: list[dict[str, Any]], now: datetime | None = None
) -> dict[int, dict[str, str]]:
    """Reserva vigente más reciente por issue, leída con la capa única de #182 (#1662).

    Antes tenía su propio parser sobre los últimos 300 comentarios: sin lease
    y ciego a CLAIM más antiguos, reencolaba issues con PR abierta (#1630).
    """

    ahora = now or datetime.now(timezone.utc)
    latest: dict[int, dict[str, str]] = {}
    for vigente in reservas_registro.vigentes(comments, ahora):
        latest[vigente.reserva.issue] = {
            "issue": str(vigente.reserva.issue),
            "branch": vigente.reserva.branch,
            "files": vigente.reserva.files,
        }
    return latest

def _run_id(branch: str | None) -> int | None:
    if not branch or not branch.startswith("agent/"):
        return None
    match = RUN_ID_RE.search(branch)
    return int(match.group("run")) if match else None


def discover_run_ids(
    issues: list[dict[str, Any]],
    comments: list[dict[str, Any]],
    now: datetime | None = None,
) -> list[int]:
    claims = active_claims(comments, now)
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
    claims = active_claims(comments, now)
    run_map = {
        int(run["id"]): run
        for run in runs
        if isinstance(run, dict) and str(run.get("id", "")).isdigit()
    }
    open_prs = [
        pr
        for pr in prs
        if isinstance(pr, dict)
        and str(pr.get("state", "OPEN")).upper() in {"OPEN", "OPENED"}
    ]
    open_pr_heads = {_pr_head(pr) for pr in open_prs}
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
        pr_referenciada = _open_pr_for_issue(number, open_prs)

        def reencolar(**campos: Any) -> None:
            # El CLAIM puede haber quedado fuera de la ventana de comentarios
            # leída de #182; una PR abierta que referencia el issue manda:
            # reencolarlo pondría a otro worker sobre trabajo ya entregado.
            if pr_referenciada is not None:
                actions.append(
                    {
                        "issue": number,
                        "action": "pr_open",
                        "branch": _pr_head(pr_referenciada),
                        "reason": "open-pr-referencia-issue",
                    }
                )
            else:
                actions.append({"issue": number, "action": "requeue", **campos})

        if "agent:working" in labels:
            if claim is None:
                reencolar(reason="working-without-claim")
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
                    reencolar(
                        branch=branch,
                        run_id=run_id,
                        reason=f"run-{conclusion or status}",
                    )
                    continue

            updated = _parse_time(issue.get("updatedAt") or issue.get("updated_at"))
            stale = updated is not None and (now - updated).total_seconds() >= ttl_seconds
            if stale:
                reencolar(branch=branch, run_id=run_id, reason="stale-working")
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

        if "agent:pr-open" in labels and claim is None and pr_referenciada is None:
            actions.append(
                {"issue": number, "action": "requeue", "reason": "pr-open-without-pr"}
            )

    return actions


def _pr_head(pr: dict[str, Any]) -> str:
    return str(pr.get("headRefName") or pr.get("head_ref") or pr.get("head") or "")


def _open_pr_for_issue(number: int, open_prs: list[dict[str, Any]]) -> dict[str, Any] | None:
    """PR abierta que trabaja el issue según las convenciones del repo.

    Solo señales fuertes: rama (`tipo/N-slug`, `agent/prov-N-run`), título
    (`fix(N): ...`) o palabra de cierre en el cuerpo. Un `Refs #N` suelto no
    cuenta: muchas PRs citan issues relacionados que no están trabajando.
    """

    rama = re.compile(rf"(?:^|[/-]){number}(?:[-/]|$)")
    titulo = re.compile(rf"^\w+\({number}\)")
    cierre = re.compile(rf"\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s+#{number}(?!\d)", re.I)
    for pr in open_prs:
        if rama.search(_pr_head(pr)):
            return pr
        if titulo.search(str(pr.get("title") or "")):
            return pr
        if cierre.search(str(pr.get("body") or "")):
            return pr
    return None


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

    now = _parse_time(args.now) if args.now else datetime.now(timezone.utc)
    if now is None:
        raise SystemExit("--now inválido")
    if args.mode == "discover":
        result: Any = {"run_ids": discover_run_ids(issues, comments, now)}
    else:
        if not args.prs or not args.runs:
            raise SystemExit("reconcile requiere --prs y --runs")
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
