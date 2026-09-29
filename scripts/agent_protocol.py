#!/usr/bin/env python3
"""Protocol v1 para handoffs deterministas entre agentes.

Materializa un TaskPacket canónico, compila un prompt corto para el worker final
y normaliza su ResultPacket. No usa red ni modifica GitHub.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
from typing import Any

SCHEMA_VERSION = 1
MESSAGE_TYPES = {
    "TASK", "CLAIM", "EVIDENCE", "BLOCKER", "QUESTION", "RESULT", "REVIEW", "HANDOFF"
}
RESULT_STATUSES = {"done", "partial", "blocked", "failed"}
MAX_LIST_ITEMS = 12
MAX_TEXT = 800
CHECK_RE = re.compile(r"(?m)^\s*[-*]\s*\[[ xX]\]\s+(.+?)\s*$")


def _text(value: Any, limit: int = MAX_TEXT) -> str:
    if not isinstance(value, str):
        return ""
    return " ".join(value.split()).strip()[:limit]


def _path(value: Any) -> str:
    value = _text(value, 300).replace("\\", "/")
    if not value or value.startswith("/") or ".." in value.split("/"):
        return ""
    return value


def _strings(value: Any, *, limit: int = MAX_LIST_ITEMS) -> list[str]:
    if not isinstance(value, list):
        return []
    result: list[str] = []
    for item in value[:limit]:
        clean = _text(item)
        if clean:
            result.append(clean)
    return result


def _extract_json_block(raw: str, begin: str, end: str) -> dict[str, Any] | None:
    if not isinstance(raw, str):
        return None
    start = raw.find(begin)
    if start < 0:
        return None
    start += len(begin)
    finish = raw.find(end, start)
    if finish < 0:
        return None
    payload = raw[start:finish].strip()
    fence = chr(96) * 3
    if payload.startswith(fence):
        lines = payload.splitlines()
        if lines:
            lines = lines[1:]
        if lines and lines[-1].strip().startswith(fence):
            lines = lines[:-1]
        payload = "\n".join(lines).strip()
    try:
        data = json.loads(payload)
    except (json.JSONDecodeError, TypeError):
        return None
    return data if isinstance(data, dict) else None


def normalize_message(data: Any) -> dict[str, Any] | None:
    """Valida el sobre común B2B sin imponer el payload de cada tipo."""
    if not isinstance(data, dict):
        return None
    message_type = _text(data.get("message_type"), 32).upper()
    if message_type not in MESSAGE_TYPES:
        return None
    schema = data.get("schema", SCHEMA_VERSION)
    if schema != SCHEMA_VERSION:
        return None
    normalized = dict(data)
    normalized["schema"] = SCHEMA_VERSION
    normalized["message_type"] = message_type
    if "task_id" in normalized:
        normalized["task_id"] = _text(normalized["task_id"], 240)
    return normalized


def _issue_number(issue: dict[str, Any]) -> int:
    number = issue.get("number")
    if number is None:
        number = issue.get("issue_number")
    try:
        value = int(number)
    except (TypeError, ValueError):
        raise ValueError("issue sin número válido")
    if value <= 0:
        raise ValueError("issue sin número válido")
    return value


def _plan_files(plan: dict[str, Any]) -> list[str]:
    raw = plan.get("files")
    if not isinstance(raw, list):
        raise ValueError("plan sin files[]")
    files: list[str] = []
    for item in raw:
        clean = _path(item)
        if not clean:
            raise ValueError(f"ruta inválida en plan: {item!r}")
        if clean not in files:
            files.append(clean)
    if len(files) > 12:
        raise ValueError("plan excede 12 rutas")
    return files


def build_task_packet(
    issue: dict[str, Any],
    plan: dict[str, Any],
    *,
    repository: str,
    base_sha: str,
    policy_sha: str,
    provider: str,
    worker: str,
) -> dict[str, Any]:
    number = _issue_number(issue)
    files = _plan_files(plan)
    title = _text(issue.get("title"), 300)
    body = issue.get("body") if isinstance(issue.get("body"), str) else ""
    goal = _text(plan.get("goal"), 500) or title
    base_sha = _text(base_sha, 64)
    policy_sha = _text(policy_sha, 64)
    if not repository or not base_sha or not provider or not worker:
        raise ValueError("faltan metadatos de asignación")

    acceptance = [_text(item, 400) for item in CHECK_RE.findall(body)[:8]]
    task_id = f"{repository}#{number}@{base_sha[:12]}"
    return {
        "schema": SCHEMA_VERSION,
        "message_type": "TASK",
        "task_id": task_id,
        "repository": repository,
        "issue": number,
        "base_sha": base_sha,
        "policy_sha": policy_sha,
        "assignment": {"provider": provider, "worker": worker},
        "objective": {"title": title, "goal": goal},
        "source_priority": [
            "repository_state",
            "issue_and_trusted_comments",
            "normas_platino",
            "selected_wiki_context",
            "temporary_memory",
            "historical_ci_memory",
        ],
        "context_layers": {
            "L0": [".agent-task-packet.json", ".agent-plan.json"],
            "L1": [".agent-task.md", ".agent-context.md", ".agent-platino/"],
            "L2": [".agent-wiki/", ".agent-memory.json", ".agent-history.json"],
        },
        "scope": {
            "allowed_files": files,
            "max_files": 12,
            "soft_diff_lines": 800,
            "constraints": [
                "minimal_diff",
                "no_unrelated_refactors",
                "preserve_existing_behavior_unless_task_requires_change",
                "run_relevant_tests",
                "no_commit_push_pr_or_merge",
                "never_edit_outside_allowed_files",
            ],
        },
        "acceptance_from_issue": acceptance,
        "abort_conditions": [
            "HEAD no coincide con base_sha antes de editar",
            "la tarea ya está resuelta en el estado actual",
            "hace falta una ruta fuera de allowed_files",
            "existe una decisión de producto o seguridad no resoluble por evidencia",
            "el cambio seguro requiere secretos o permisos no disponibles",
        ],
        "evidence_model": {
            "facts": "hechos observados directamente",
            "assumptions": "inferencias aún no verificadas",
            "verified": "comprobaciones ejecutadas y su resultado",
            "unknowns": "incógnitas relevantes que siguen abiertas",
        },
        "result_contract": {
            "message_type": "RESULT",
            "statuses": sorted(RESULT_STATUSES),
            "required": [
                "schema", "message_type", "task_id", "base_sha", "status", "summary",
                "facts", "assumptions", "verified", "unknowns", "changes", "evidence",
                "unresolved", "next_action"
            ],
        },
        "coordination": {
            "lease": "Deno KV con fallback GitHub",
            "claim": "reserva de rutas del registro central",
            "rule": "el estado autoritativo del repo/CI prevalece sobre cualquier memoria",
        },
    }


def render_worker_prompt(packet: dict[str, Any], provider: str) -> str:
    task_id = _text(packet.get("task_id"), 240)
    base_sha = _text(packet.get("base_sha"), 64)
    scope = packet.get("scope") if isinstance(packet.get("scope"), dict) else {}
    files = scope.get("allowed_files") if isinstance(scope.get("allowed_files"), list) else []
    rendered_files = "\n".join(f"- {item}" for item in files) or "- (ninguna)"
    return f"""# Worker contract v1

Tarea: {task_id}
Proveedor: {provider}
Base autoritativa: {base_sha}

Lee primero '.agent-task-packet.json'. Es el contrato operativo. Para detalle consulta
'.agent-task.md', '.agent-plan.json', '.agent-context.md' y las Normas Platino en
'.agent-platino/'; usa wiki/memorias solo si hace falta. La prioridad de fuentes está
en el TaskPacket.

## Scope
Solo puedes modificar estas rutas:
{rendered_files}

El workflow ha sellado la base en 'base_sha'. No asumas otra base ni reconstruyas el
contexto desde memoria. Si detectas evidencia de que el estado leído no corresponde a
esa base, detente. Haz el diff mínimo, evita refactors laterales y ejecuta las
verificaciones relevantes que estén disponibles. No hagas commit, push, PR ni merge.

Si necesitas una ruta fuera del CLAIM, si la tarea ya está resuelta o si falta una
decisión humana real, detente y refleja el bloqueo en el resultado. No inventes
evidencia ni presentes una suposición como hecho.

## Salida obligatoria
Al terminar, emite exactamente un bloque 'AGENT_RESULT_BEGIN' / 'AGENT_RESULT_END'
con JSON válido de esta forma:

{{
  "schema": 1,
  "message_type": "RESULT",
  "task_id": "{task_id}",
  "base_sha": "{base_sha}",
  "status": "done|partial|blocked|failed",
  "summary": "resultado concreto",
  "facts": ["hechos observados"],
  "assumptions": ["suposiciones pendientes"],
  "verified": ["comprobación y resultado"],
  "unknowns": ["incógnitas"],
  "changes": [{{"path": "ruta", "reason": "por qué cambió"}}],
  "evidence": [{{"kind": "test|diff|runtime|source", "detail": "evidencia"}}],
  "unresolved": ["pendientes"],
  "next_action": "siguiente acción concreta"
}}

Después puedes emitir 'AGENT_MEMORY_BEGIN' seguido de JSON
{"summary":"aprendizaje verificable y reusable, sin secretos","tags":["tag"]}
y 'AGENT_MEMORY_END' para conservar la memoria histórica existente.
No incluyas secretos, razonamiento interno ni texto sensible en ninguno de los dos
bloques.
"""


def _changes(value: Any) -> list[dict[str, str]]:
    if not isinstance(value, list):
        return []
    out: list[dict[str, str]] = []
    for item in value[:MAX_LIST_ITEMS]:
        if not isinstance(item, dict):
            continue
        path = _path(item.get("path"))
        reason = _text(item.get("reason"), 400)
        if path:
            out.append({"path": path, "reason": reason})
    return out


def _evidence(value: Any) -> list[dict[str, str]]:
    if not isinstance(value, list):
        return []
    out: list[dict[str, str]] = []
    for item in value[:MAX_LIST_ITEMS]:
        if isinstance(item, str):
            detail = _text(item, 500)
            if detail:
                out.append({"kind": "other", "detail": detail})
        elif isinstance(item, dict):
            detail = _text(item.get("detail"), 500)
            if detail:
                out.append({"kind": _text(item.get("kind"), 40) or "other", "detail": detail})
    return out


def parse_result(raw: str) -> dict[str, Any]:
    data = _extract_json_block(raw, "AGENT_RESULT_BEGIN", "AGENT_RESULT_END")
    if data is None:
        return {"valid": False, "reason": "missing-or-invalid-json", "status": None}

    message = normalize_message(data)
    if message is None or message.get("message_type") != "RESULT":
        return {"valid": False, "reason": "invalid-envelope", "status": None}

    status = _text(message.get("status"), 32).lower()
    summary = _text(message.get("summary"), 1000)
    if status not in RESULT_STATUSES or not summary:
        return {"valid": False, "reason": "invalid-status-or-summary", "status": status or None}

    required = {
        "schema", "message_type", "task_id", "base_sha", "status", "summary",
        "facts", "assumptions", "verified", "unknowns", "changes", "evidence",
        "unresolved", "next_action",
    }
    present = sorted(required & set(message))
    return {
        "valid": True,
        "reason": "ok",
        "schema": SCHEMA_VERSION,
        "message_type": "RESULT",
        "task_id": _text(message.get("task_id"), 240),
        "base_sha": _text(message.get("base_sha"), 64),
        "status": status,
        "summary": summary,
        "facts": _strings(message.get("facts")),
        "assumptions": _strings(message.get("assumptions")),
        "verified": _strings(message.get("verified")),
        "unknowns": _strings(message.get("unknowns")),
        "changes": _changes(message.get("changes")),
        "evidence": _evidence(message.get("evidence")),
        "unresolved": _strings(message.get("unresolved")),
        "next_action": _text(message.get("next_action"), 500),
        "contract_coverage_pct": round(100.0 * len(present) / len(required), 1),
    }


def result_metrics(
    packet: dict[str, Any],
    result: dict[str, Any],
    changed_files: list[str],
) -> dict[str, Any]:
    actual = sorted({_path(item) for item in changed_files if _path(item)})
    if not result.get("valid"):
        return {
            "result_contract_valid": False,
            "handoff_loss_proxy_pct": 100.0,
            "actual_changed_files": actual,
            "unreported_changed_files": actual,
        }

    reported = sorted({item["path"] for item in result.get("changes", []) if item.get("path")})
    missing = sorted(set(actual) - set(reported))
    checks = [
        result.get("task_id") == packet.get("task_id"),
        result.get("base_sha") == packet.get("base_sha"),
        not missing,
        bool(result.get("evidence")) or not actual,
        bool(result.get("next_action")),
        float(result.get("contract_coverage_pct", 0)) == 100.0,
    ]
    loss = round(100.0 * (len(checks) - sum(bool(x) for x in checks)) / len(checks), 1)
    return {
        "result_contract_valid": True,
        "handoff_loss_proxy_pct": loss,
        "contract_coverage_pct": result.get("contract_coverage_pct", 0.0),
        "actual_changed_files": actual,
        "reported_changed_files": reported,
        "unreported_changed_files": missing,
        "task_id_matches": checks[0],
        "base_sha_matches": checks[1],
    }


def _load(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _write(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    task = sub.add_parser("task")
    task.add_argument("--issue-json", type=Path, required=True)
    task.add_argument("--plan", type=Path, required=True)
    task.add_argument("--repo", required=True)
    task.add_argument("--base-sha", required=True)
    task.add_argument("--policy-sha", default="")
    task.add_argument("--provider", required=True)
    task.add_argument("--worker", required=True)
    task.add_argument("--output", type=Path, required=True)

    prompt = sub.add_parser("prompt")
    prompt.add_argument("--packet", type=Path, required=True)
    prompt.add_argument("--provider", required=True)
    prompt.add_argument("--output", type=Path, required=True)

    result = sub.add_parser("result")
    result.add_argument("--summary-file", type=Path, required=True)
    result.add_argument("--packet", type=Path, required=True)
    result.add_argument("--changed-files", type=Path)
    result.add_argument("--output", type=Path, required=True)

    args = parser.parse_args()

    if args.command == "task":
        packet = build_task_packet(
            _load(args.issue_json),
            _load(args.plan),
            repository=args.repo,
            base_sha=args.base_sha,
            policy_sha=args.policy_sha,
            provider=args.provider,
            worker=args.worker,
        )
        _write(args.output, packet)
        print(json.dumps({"task_id": packet["task_id"], "files": len(packet["scope"]["allowed_files"])}))
        return 0

    if args.command == "prompt":
        packet = _load(args.packet)
        args.output.write_text(render_worker_prompt(packet, args.provider), encoding="utf-8")
        print(json.dumps({"task_id": packet.get("task_id"), "provider": args.provider}))
        return 0

    raw = args.summary_file.read_text(encoding="utf-8") if args.summary_file.exists() else ""
    parsed = parse_result(raw)
    packet = _load(args.packet)
    changed = []
    if args.changed_files and args.changed_files.exists():
        changed = [line.strip() for line in args.changed_files.read_text(encoding="utf-8").splitlines() if line.strip()]
    payload = {"result": parsed, "metrics": result_metrics(packet, parsed, changed)}
    _write(args.output, payload)
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
