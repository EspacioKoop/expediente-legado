#!/usr/bin/env python3
"""CI brain compacto para Expediente Legado.

Usa SQLite de la librería estándar como fuente local. Puede replicar el mismo
esquema y filas a Turso/libSQL mediante Hrana sobre HTTP, sin instalar SDKs.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sqlite3
import statistics
import sys
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Iterable
from io import BytesIO


ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = ROOT / "infra" / "ci-brain" / "schema.sql"
GITHUB_API = "https://api.github.com"
USER_AGENT = "expediente-legado-ci-brain/1"
MAX_MEMORY_SUMMARY = 2000
MAX_MEMORY_METADATA = 8000


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def parse_time(value: str | None) -> datetime | None:
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def duration_seconds(start: str | None, end: str | None) -> float | None:
    a = parse_time(start)
    b = parse_time(end)
    if a is None or b is None:
        return None
    return max(0.0, (b - a).total_seconds())


def connect(path: Path) -> sqlite3.Connection:
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    conn.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))
    return conn


def github_json(url: str, token: str) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "User-Agent": USER_AGENT,
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace")[:1000]
        raise RuntimeError(f"GitHub API {exc.code}: {detail}") from exc


ANSI_RE = re.compile(r"\\x1b\\[[0-9;]*[A-Za-z]")
TIMESTAMP_RE = re.compile(r"^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?Z\\s+")
IMPORTANT_FAILURE_RE = re.compile(
    r"(?:error|failed|failure|fatal|traceback|assert|gdformat|gdlint|"
    r"parse error|exit code|not found|missing|required check)",
    re.IGNORECASE,
)
SECRET_RE = re.compile(
    r"(?:github_pat_[A-Za-z0-9_]+|gh[pousr]_[A-Za-z0-9]+|"
    r"AIza[0-9A-Za-z_-]{12,}|sk-[A-Za-z0-9_-]{12,}|"
    r"Bearer\\s+[A-Za-z0-9._-]{12,})",
    re.IGNORECASE,
)
SHA_RE = re.compile(r"\\b[0-9a-f]{7,40}\\b", re.IGNORECASE)
LINE_NUMBER_RE = re.compile(r":\\d+(?::\\d+)?(?=[:\\s)]|$)")
TOKEN_RE = re.compile(r"[A-Za-z0-9_./:-]{4,}")
CONTEXT_STOPWORDS = {
    "para", "como", "esta", "este", "estos", "estas", "desde", "solo", "sobre",
    "issue", "agent", "https", "github", "repositorio", "corrige", "usando",
    "with", "that", "this", "from", "only", "error", "failed", "failure",
}


def github_bytes(url: str, token: str) -> bytes:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "User-Agent": USER_AGENT,
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace")[:1000]
        raise RuntimeError(f"GitHub API {exc.code}: {detail}") from exc


def github_text(url: str, token: str) -> str:
    return github_bytes(url, token).decode("utf-8", "replace")


def _sanitize_failure_line(line: str) -> str:
    line = ANSI_RE.sub("", line)
    line = TIMESTAMP_RE.sub("", line).strip()
    line = SECRET_RE.sub("<redacted>", line)
    line = re.sub(r"/home/runner/work/[^/]+/[^/]+/", "<workspace>/", line)
    line = SHA_RE.sub("<sha>", line)
    line = LINE_NUMBER_RE.sub(":<n>", line)
    line = re.sub(r"\\s+", " ", line).strip()
    return line[:240]


def normalize_failure_signature(log_text: str) -> str:
    selected: list[str] = []
    fallback: list[str] = []
    for raw in log_text.splitlines():
        line = _sanitize_failure_line(raw)
        if not line:
            continue
        fallback.append(line)
        if IMPORTANT_FAILURE_RE.search(line) and line not in selected:
            selected.append(line)
    source = selected[-8:] if selected else fallback[-4:]
    return "\\n".join(source)[:MAX_MEMORY_SUMMARY]


def failure_fingerprint(signature: str) -> str:
    if not signature:
        return ""
    return hashlib.sha256(signature.encode("utf-8")).hexdigest()[:16]


def remember_failure_sample(
    conn: sqlite3.Connection,
    run: dict[str, Any],
    job: dict[str, Any],
    log_text: str,
    *,
    retention_days: int,
) -> str:
    signature = normalize_failure_signature(log_text)
    fingerprint = failure_fingerprint(signature)
    if not fingerprint:
        return ""
    completed = job.get("completed_at") or run.get("updated_at") or iso(utc_now())
    expires_at = iso(utc_now() + timedelta(days=max(1, retention_days)))
    remember(
        conn,
        kind="ci_failure_sample",
        key=str(int(job["id"])),
        summary=signature,
        metadata={
            "fingerprint": fingerprint,
            "workflow": str(run.get("name") or "workflow"),
            "job": str(job.get("name") or "job"),
            "run_id": int(run["id"]),
            "job_id": int(job["id"]),
            "completed_at": completed,
        },
        expires_at=expires_at,
    )
    return fingerprint


def refresh_failure_fingerprint_memory(conn: sqlite3.Connection) -> None:
    now = iso(utc_now())
    rows = conn.execute(
        """
        SELECT summary, metadata_json
        FROM memory_entries
        WHERE kind = 'ci_failure_sample'
          AND (expires_at IS NULL OR expires_at >= ?)
        """,
        (now,),
    ).fetchall()
    groups: dict[str, dict[str, Any]] = {}
    for row in rows:
        try:
            metadata = json.loads(row["metadata_json"])
        except (TypeError, json.JSONDecodeError):
            continue
        fingerprint = str(metadata.get("fingerprint") or "")
        if not fingerprint:
            continue
        group = groups.setdefault(
            fingerprint,
            {
                "count": 0,
                "signature": row["summary"],
                "workflows": set(),
                "jobs": set(),
                "last_failed": "",
            },
        )
        group["count"] += 1
        group["workflows"].add(str(metadata.get("workflow") or ""))
        group["jobs"].add(str(metadata.get("job") or ""))
        completed = str(metadata.get("completed_at") or "")
        if completed > group["last_failed"]:
            group["last_failed"] = completed
            group["signature"] = row["summary"]

    for fingerprint, group in groups.items():
        signature = str(group["signature"])
        first_line = signature.splitlines()[0] if signature else "fallo sin firma"
        remember(
            conn,
            kind="ci_failure_fingerprint",
            key=fingerprint,
            summary=(
                f"Fingerprint CI {fingerprint}: {group['count']} aparición(es); "
                f"última {group['last_failed'] or 'desconocida'}. {first_line}"
            ),
            metadata={
                "fingerprint": fingerprint,
                "count": group["count"],
                "workflows": sorted(item for item in group["workflows"] if item)[:8],
                "jobs": sorted(item for item in group["jobs"] if item)[:12],
                "last_failed": group["last_failed"],
                "signature": signature[:1200],
            },
        )


def _context_tokens(text: str) -> set[str]:
    return {
        token.lower()
        for token in TOKEN_RE.findall(text)
        if token.lower() not in CONTEXT_STOPWORDS
    }


def build_memory_context(
    conn: sqlite3.Connection,
    query_text: str,
    paths: list[str] | None = None,
    *,
    limit: int = 8,
) -> dict[str, Any]:
    now = iso(utc_now())
    rows = conn.execute(
        """
        SELECT kind, memory_key, summary, metadata_json, updated_at
        FROM memory_entries
        WHERE kind != 'ci_failure_sample'
          AND (expires_at IS NULL OR expires_at >= ?)
        ORDER BY updated_at DESC
        LIMIT 500
        """,
        (now,),
    ).fetchall()
    query_tokens = _context_tokens(query_text)
    path_tokens: set[str] = set()
    for path in paths or []:
        path_tokens |= _context_tokens(path.replace("\\", "/"))

    scored: list[tuple[int, str, dict[str, Any]]] = []
    for row in rows:
        try:
            metadata = json.loads(row["metadata_json"])
        except (TypeError, json.JSONDecodeError):
            metadata = {}
        item = {
            "kind": row["kind"],
            "key": row["memory_key"],
            "summary": row["summary"],
            "metadata": metadata,
            "updated_at": row["updated_at"],
        }
        haystack = " ".join(
            [
                str(row["memory_key"]),
                str(row["summary"]),
                json.dumps(metadata, ensure_ascii=False, sort_keys=True),
            ]
        ).lower()
        score = sum(2 for token in query_tokens if token in haystack)
        score += sum(5 for token in path_tokens if token in haystack)
        if row["kind"] == "ci_failure_fingerprint" and score:
            score += 3
        if score:
            scored.append((score, str(row["updated_at"]), item))
    scored.sort(key=lambda item: (item[0], item[1]), reverse=True)
    return {
        "ok": True,
        "source": "ci-brain-sqlite",
        "memories": [item for _, _, item in scored[: max(1, min(limit, 20))]],
    }


def restore_latest_snapshot(
    destination: Path,
    *,
    repo: str,
    token: str,
    workflow: str = "ci-brain.yml",
) -> int | None:
    encoded = urllib.parse.quote(workflow, safe="")
    query = urllib.parse.urlencode(
        {"branch": "main", "status": "success", "per_page": 10}
    )
    runs = github_json(
        f"{GITHUB_API}/repos/{repo}/actions/workflows/{encoded}/runs?{query}",
        token,
    ).get("workflow_runs", [])
    for run in runs:
        run_id = int(run["id"])
        artifacts = github_json(
            f"{GITHUB_API}/repos/{repo}/actions/runs/{run_id}/artifacts?per_page=100",
            token,
        ).get("artifacts", [])
        expected = f"ci-brain-{run_id}"
        artifact = next(
            (
                item
                for item in artifacts
                if item.get("name") == expected and not item.get("expired", False)
            ),
            None,
        )
        if not artifact:
            continue
        payload = github_bytes(str(artifact["archive_download_url"]), token)
        with zipfile.ZipFile(BytesIO(payload)) as archive:
            member = next(
                (name for name in archive.namelist() if name.endswith("ci-brain.sqlite3")),
                None,
            )
            if not member:
                continue
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(archive.read(member))
            return run_id
    return None


RUN_SQL = """
INSERT INTO ci_runs (
    run_id, workflow, workflow_id, head_sha, head_branch, event, conclusion,
    run_attempt, created_at, updated_at, duration_seconds, html_url
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(run_id) DO UPDATE SET
    workflow=excluded.workflow,
    workflow_id=excluded.workflow_id,
    head_sha=excluded.head_sha,
    head_branch=excluded.head_branch,
    event=excluded.event,
    conclusion=excluded.conclusion,
    run_attempt=excluded.run_attempt,
    created_at=excluded.created_at,
    updated_at=excluded.updated_at,
    duration_seconds=excluded.duration_seconds,
    html_url=excluded.html_url
"""

JOB_SQL = """
INSERT INTO ci_jobs (
    job_id, run_id, workflow, name, conclusion, started_at, completed_at,
    duration_seconds, html_url
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(job_id) DO UPDATE SET
    run_id=excluded.run_id,
    workflow=excluded.workflow,
    name=excluded.name,
    conclusion=excluded.conclusion,
    started_at=excluded.started_at,
    completed_at=excluded.completed_at,
    duration_seconds=excluded.duration_seconds,
    html_url=excluded.html_url
"""

MEMORY_SQL = """
INSERT INTO memory_entries (
    kind, memory_key, summary, metadata_json, created_at, updated_at, expires_at
) VALUES (?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(kind, memory_key) DO UPDATE SET
    summary=excluded.summary,
    metadata_json=excluded.metadata_json,
    updated_at=excluded.updated_at,
    expires_at=excluded.expires_at
"""


def normalize_run(run: dict[str, Any]) -> tuple[Any, ...]:
    return (
        int(run["id"]),
        str(run.get("name") or run.get("display_title") or "workflow"),
        run.get("workflow_id"),
        run.get("head_sha"),
        run.get("head_branch"),
        run.get("event"),
        run.get("conclusion"),
        int(run.get("run_attempt") or 1),
        run.get("created_at"),
        run.get("updated_at"),
        duration_seconds(run.get("run_started_at") or run.get("created_at"), run.get("updated_at")),
        run.get("html_url"),
    )


def normalize_job(run: dict[str, Any], job: dict[str, Any]) -> tuple[Any, ...]:
    return (
        int(job["id"]),
        int(run["id"]),
        str(run.get("name") or run.get("display_title") or "workflow"),
        str(job.get("name") or "job"),
        job.get("conclusion"),
        job.get("started_at"),
        job.get("completed_at"),
        duration_seconds(job.get("started_at"), job.get("completed_at")),
        job.get("html_url"),
    )


def remember(
    conn: sqlite3.Connection,
    *,
    kind: str,
    key: str,
    summary: str,
    metadata: dict[str, Any] | None = None,
    expires_at: str | None = None,
) -> None:
    summary = " ".join(summary.split()).strip()
    if not kind or not key or not summary:
        raise ValueError("kind, key y summary son obligatorios")
    if len(summary) > MAX_MEMORY_SUMMARY:
        raise ValueError(f"summary supera {MAX_MEMORY_SUMMARY} caracteres")
    metadata_json = json.dumps(metadata or {}, ensure_ascii=False, sort_keys=True)
    if len(metadata_json) > MAX_MEMORY_METADATA:
        raise ValueError(f"metadata supera {MAX_MEMORY_METADATA} caracteres")
    now = iso(utc_now())
    conn.execute(
        MEMORY_SQL,
        (kind, key, summary, metadata_json, now, now, expires_at),
    )


def prune(conn: sqlite3.Connection, days: int = 120) -> None:
    threshold = iso(utc_now() - timedelta(days=days))
    conn.execute("DELETE FROM ci_jobs WHERE run_id IN (SELECT run_id FROM ci_runs WHERE updated_at < ?)", (threshold,))
    conn.execute("DELETE FROM ci_runs WHERE updated_at < ?", (threshold,))
    conn.execute(
        "DELETE FROM memory_entries WHERE expires_at IS NOT NULL AND expires_at < ?",
        (iso(utc_now()),),
    )


def refresh_failure_memory(conn: sqlite3.Connection) -> None:
    since = iso(utc_now() - timedelta(days=30))
    rows = conn.execute(
        """
        SELECT j.workflow, j.name, COUNT(*) AS failures,
               MAX(j.completed_at) AS last_failed
        FROM ci_jobs AS j
        JOIN ci_runs AS r ON r.run_id = j.run_id
        WHERE j.conclusion = 'failure' AND r.updated_at >= ?
        GROUP BY j.workflow, j.name
        HAVING COUNT(*) >= 2
        ORDER BY failures DESC, last_failed DESC
        LIMIT 100
        """,
        (since,),
    ).fetchall()
    for row in rows:
        key = f"{row['workflow']}::{row['name']}"
        remember(
            conn,
            kind="ci_failure",
            key=key,
            summary=(
                f"{row['workflow']} / {row['name']}: "
                f"{row['failures']} fallos en los últimos 30 días; "
                f"último {row['last_failed'] or 'desconocido'}."
            ),
            metadata={
                "workflow": row["workflow"],
                "job": row["name"],
                "failures_30d": row["failures"],
                "last_failed": row["last_failed"],
            },
        )


def collect(args: argparse.Namespace) -> int:
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    repo = args.repo or os.environ.get("GITHUB_REPOSITORY")
    if not token:
        raise SystemExit("falta GH_TOKEN/GITHUB_TOKEN")
    if not repo or "/" not in repo:
        raise SystemExit("falta --repo owner/name o GITHUB_REPOSITORY")

    limit = max(1, min(int(args.limit), 100))
    since = utc_now() - timedelta(hours=max(1, int(args.hours)))
    query = urllib.parse.urlencode({"status": "completed", "per_page": limit})
    data = github_json(f"{GITHUB_API}/repos/{repo}/actions/runs?{query}", token)

    conn = connect(Path(args.sqlite))
    inserted = 0
    jobs_seen = 0
    try:
        for run in data.get("workflow_runs", []):
            updated = parse_time(run.get("updated_at"))
            if updated is not None and updated < since:
                continue
            conn.execute(RUN_SQL, normalize_run(run))
            inserted += 1
            jobs_url = f"{GITHUB_API}/repos/{repo}/actions/runs/{int(run['id'])}/jobs?per_page=100"
            jobs = github_json(jobs_url, token).get("jobs", [])
            for job in jobs:
                conn.execute(JOB_SQL, normalize_job(run, job))
                jobs_seen += 1
                if job.get("conclusion") == "failure":
                    try:
                        log_text = github_text(
                            f"{GITHUB_API}/repos/{repo}/actions/jobs/{int(job['id'])}/logs",
                            token,
                        )
                        remember_failure_sample(
                            conn,
                            run,
                            job,
                            log_text,
                            retention_days=args.retention_days,
                        )
                    except (RuntimeError, ValueError) as exc:
                        print(
                            f"aviso: no se pudo fingerprint job {job.get('id')}: {exc}",
                            file=sys.stderr,
                        )
        prune(conn, days=args.retention_days)
        refresh_failure_memory(conn)
        refresh_failure_fingerprint_memory(conn)
        conn.commit()
    finally:
        conn.close()

    print(json.dumps({"runs": inserted, "jobs": jobs_seen, "since": iso(since)}, ensure_ascii=False))
    return 0


def percentile_95(values: list[float]) -> float | None:
    if not values:
        return None
    values = sorted(values)
    index = max(0, min(len(values) - 1, int(round(0.95 * (len(values) - 1)))))
    return values[index]


def build_summary(conn: sqlite3.Connection) -> dict[str, Any]:
    runs = conn.execute(
        "SELECT workflow, conclusion, duration_seconds, updated_at FROM ci_runs ORDER BY updated_at DESC"
    ).fetchall()
    by_workflow: dict[str, dict[str, Any]] = {}
    for row in runs:
        bucket = by_workflow.setdefault(
            row["workflow"],
            {"runs": 0, "success": 0, "failure": 0, "durations": []},
        )
        bucket["runs"] += 1
        if row["conclusion"] == "success":
            bucket["success"] += 1
        elif row["conclusion"] == "failure":
            bucket["failure"] += 1
        if row["duration_seconds"] is not None:
            bucket["durations"].append(float(row["duration_seconds"]))

    workflows = []
    for name, bucket in by_workflow.items():
        durations = bucket.pop("durations")
        total = bucket["runs"]
        workflows.append(
            {
                "workflow": name,
                **bucket,
                "success_rate": round(bucket["success"] / total, 4) if total else None,
                "median_seconds": round(statistics.median(durations), 1) if durations else None,
                "p95_seconds": round(percentile_95(durations), 1) if durations else None,
            }
        )
    workflows.sort(key=lambda item: (-item["failure"], -item["runs"], item["workflow"]))

    recurring = [
        dict(row)
        for row in conn.execute(
            """
            SELECT memory_key, summary, metadata_json, updated_at
            FROM memory_entries
            WHERE kind IN ('ci_failure_fingerprint', 'ci_failure')
            ORDER BY
                CASE kind WHEN 'ci_failure_fingerprint' THEN 0 ELSE 1 END,
                updated_at DESC
            LIMIT 20
            """
        )
    ]
    for item in recurring:
        item["metadata"] = json.loads(item.pop("metadata_json"))

    total = len(runs)
    failures = sum(1 for row in runs if row["conclusion"] == "failure")
    return {
        "generated_at": iso(utc_now()),
        "runs": total,
        "failures": failures,
        "failure_rate": round(failures / total, 4) if total else 0.0,
        "workflows": workflows,
        "recurring_failures": recurring,
    }


def summary(args: argparse.Namespace) -> int:
    conn = connect(Path(args.sqlite))
    try:
        result = build_summary(conn)
    finally:
        conn.close()
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output:
        Path(args.output).parent.mkdir(parents=True, exist_ok=True)
        Path(args.output).write_text(rendered, encoding="utf-8")
    sys.stdout.write(rendered)
    return 0


def remember_command(args: argparse.Namespace) -> int:
    metadata = json.loads(args.metadata or "{}")
    expires = None
    if args.ttl_days:
        expires = iso(utc_now() + timedelta(days=int(args.ttl_days)))
    conn = connect(Path(args.sqlite))
    try:
        remember(
            conn,
            kind=args.kind,
            key=args.key,
            summary=args.summary,
            metadata=metadata,
            expires_at=expires,
        )
        conn.commit()
    finally:
        conn.close()
    return 0


def recall(args: argparse.Namespace) -> int:
    conn = connect(Path(args.sqlite))
    try:
        pattern = f"%{args.query}%"
        rows = conn.execute(
            """
            SELECT kind, memory_key, summary, metadata_json, updated_at, expires_at
            FROM memory_entries
            WHERE (memory_key LIKE ? OR summary LIKE ?)
              AND (expires_at IS NULL OR expires_at >= ?)
            ORDER BY updated_at DESC
            LIMIT ?
            """,
            (pattern, pattern, iso(utc_now()), max(1, min(args.limit, 50))),
        ).fetchall()
    finally:
        conn.close()
    result = []
    for row in rows:
        item = dict(row)
        item["metadata"] = json.loads(item.pop("metadata_json"))
        result.append(item)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


def context_command(args: argparse.Namespace) -> int:
    query_text = ""
    if args.query_file:
        query_text = Path(args.query_file).read_text(encoding="utf-8", errors="replace")
    if args.query:
        query_text += "\\n" + args.query
    paths: list[str] = []
    if args.paths_json:
        raw = json.loads(Path(args.paths_json).read_text(encoding="utf-8"))
        if isinstance(raw, dict):
            raw = raw.get("files", [])
        if isinstance(raw, list):
            paths = [str(item) for item in raw[:50]]
    conn = connect(Path(args.sqlite))
    try:
        result = build_memory_context(conn, query_text, paths, limit=args.limit)
    finally:
        conn.close()
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + "\\n"
    if args.output:
        Path(args.output).write_text(rendered, encoding="utf-8")
    sys.stdout.write(rendered)
    return 0


def restore_command(args: argparse.Namespace) -> int:
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    repo = args.repo or os.environ.get("GITHUB_REPOSITORY")
    if not token:
        raise SystemExit("falta GH_TOKEN/GITHUB_TOKEN")
    if not repo or "/" not in repo:
        raise SystemExit("falta --repo owner/name o GITHUB_REPOSITORY")
    run_id = restore_latest_snapshot(
        Path(args.sqlite),
        repo=repo,
        token=token,
        workflow=args.workflow,
    )
    if run_id is None:
        print(json.dumps({"restored": False}, ensure_ascii=False))
        return 1
    print(json.dumps({"restored": True, "run_id": run_id}, ensure_ascii=False))
    return 0


def hrana_value(value: Any) -> dict[str, Any]:
    if value is None:
        return {"type": "null"}
    if isinstance(value, bool):
        return {"type": "integer", "value": "1" if value else "0"}
    if isinstance(value, int):
        return {"type": "integer", "value": str(value)}
    if isinstance(value, float):
        return {"type": "float", "value": value}
    return {"type": "text", "value": str(value)}


def turso_endpoint(database_url: str) -> str:
    database_url = database_url.strip()
    if database_url.startswith("libsql://"):
        database_url = "https://" + database_url[len("libsql://") :]
    parsed = urllib.parse.urlsplit(database_url)
    if parsed.scheme != "https" or not parsed.netloc:
        raise ValueError("TURSO_DATABASE_URL debe usar libsql:// o https://")
    base = urllib.parse.urlunsplit((parsed.scheme, parsed.netloc, parsed.path.rstrip("/"), "", ""))
    return base + "/v2/pipeline"


def turso_pipeline(endpoint: str, token: str, requests: list[dict[str, Any]]) -> None:
    body = json.dumps({"baton": None, "requests": requests + [{"type": "close"}]}).encode("utf-8")
    request = urllib.request.Request(
        endpoint,
        data=body,
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": USER_AGENT,
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace")[:1000]
        raise RuntimeError(f"Turso HTTP {exc.code}: {detail}") from exc
    errors = [item.get("error", {}) for item in payload.get("results", []) if item.get("type") == "error"]
    if errors:
        raise RuntimeError(f"Turso rechazó pipeline: {errors[0].get('message', errors[0])}")


def execute_request(sql: str, args: Iterable[Any] = ()) -> dict[str, Any]:
    return {
        "type": "execute",
        "stmt": {
            "sql": sql,
            "args": [hrana_value(value) for value in args],
            "want_rows": False,
        },
    }


def sync_table(
    conn: sqlite3.Connection,
    endpoint: str,
    token: str,
    table: str,
    columns: list[str],
    upsert_sql: str,
) -> int:
    rows = conn.execute(f"SELECT {', '.join(columns)} FROM {table}").fetchall()
    total = 0
    chunk: list[dict[str, Any]] = []
    for row in rows:
        chunk.append(execute_request(upsert_sql, [row[column] for column in columns]))
        if len(chunk) >= 50:
            turso_pipeline(endpoint, token, chunk)
            total += len(chunk)
            chunk.clear()
    if chunk:
        turso_pipeline(endpoint, token, chunk)
        total += len(chunk)
    return total


def sync_turso(args: argparse.Namespace) -> int:
    url = args.url or os.environ.get("TURSO_DATABASE_URL")
    token = args.token or os.environ.get("TURSO_AUTH_TOKEN")
    if not url or not token:
        raise SystemExit("faltan TURSO_DATABASE_URL y/o TURSO_AUTH_TOKEN")
    endpoint = turso_endpoint(url)

    schema_sql = SCHEMA_PATH.read_text(encoding="utf-8")
    turso_pipeline(endpoint, token, [{"type": "sequence", "sql": schema_sql}])

    conn = connect(Path(args.sqlite))
    try:
        run_cols = [
            "run_id", "workflow", "workflow_id", "head_sha", "head_branch", "event",
            "conclusion", "run_attempt", "created_at", "updated_at", "duration_seconds", "html_url",
        ]
        job_cols = [
            "job_id", "run_id", "workflow", "name", "conclusion", "started_at",
            "completed_at", "duration_seconds", "html_url",
        ]
        memory_cols = [
            "kind", "memory_key", "summary", "metadata_json", "created_at",
            "updated_at", "expires_at",
        ]
        counts = {
            "ci_runs": sync_table(conn, endpoint, token, "ci_runs", run_cols, RUN_SQL),
            "ci_jobs": sync_table(conn, endpoint, token, "ci_jobs", job_cols, JOB_SQL),
            "memory_entries": sync_table(conn, endpoint, token, "memory_entries", memory_cols, MEMORY_SQL),
        }
    finally:
        conn.close()
    print(json.dumps({"endpoint": endpoint, "synced": counts}, ensure_ascii=False))
    return 0


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="command", required=True)

    c = sub.add_parser("collect", help="recoge runs/jobs recientes desde GitHub Actions")
    c.add_argument("--sqlite", default="dist/.cache/ci-brain.sqlite3")
    c.add_argument("--repo")
    c.add_argument("--hours", type=int, default=12)
    c.add_argument("--limit", type=int, default=40)
    c.add_argument("--retention-days", type=int, default=120)
    c.set_defaults(func=collect)

    s = sub.add_parser("summary", help="resume salud de workflows")
    s.add_argument("--sqlite", default="dist/.cache/ci-brain.sqlite3")
    s.add_argument("--output")
    s.set_defaults(func=summary)

    m = sub.add_parser("remember", help="guarda un recuerdo técnico pequeño")
    m.add_argument("--sqlite", default="dist/.cache/ci-brain.sqlite3")
    m.add_argument("--kind", required=True)
    m.add_argument("--key", required=True)
    m.add_argument("--summary", required=True)
    m.add_argument("--metadata", default="{}")
    m.add_argument("--ttl-days", type=int)
    m.set_defaults(func=remember_command)

    r = sub.add_parser("recall", help="busca recuerdos técnicos")
    r.add_argument("--sqlite", default="dist/.cache/ci-brain.sqlite3")
    r.add_argument("--query", required=True)
    r.add_argument("--limit", type=int, default=10)
    r.set_defaults(func=recall)

    x = sub.add_parser("context", help="selecciona memoria histórica relevante")
    x.add_argument("--sqlite", default="dist/.cache/ci-brain.sqlite3")
    x.add_argument("--query")
    x.add_argument("--query-file")
    x.add_argument("--paths-json")
    x.add_argument("--limit", type=int, default=8)
    x.add_argument("--output")
    x.set_defaults(func=context_command)

    z = sub.add_parser("restore", help="recupera el último snapshot CI brain de Actions")
    z.add_argument("--sqlite", default="dist/.cache/ci-brain.sqlite3")
    z.add_argument("--repo")
    z.add_argument("--workflow", default="ci-brain.yml")
    z.set_defaults(func=restore_command)

    t = sub.add_parser("sync-turso", help="replica snapshot local a Turso/libSQL")
    t.add_argument("--sqlite", default="dist/.cache/ci-brain.sqlite3")
    t.add_argument("--url")
    t.add_argument("--token")
    t.set_defaults(func=sync_turso)
    return p


def main() -> int:
    args = parser().parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
