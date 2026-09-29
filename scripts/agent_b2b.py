#!/usr/bin/env python3
"""Contrato B2B versionado para handoffs del pool de agentes (#1866)."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Any

SCHEMA = 1
MESSAGE_TYPES = {"TASK", "CLAIM", "EVIDENCE", "BLOCKER", "QUESTION", "RESULT", "REVIEW", "HANDOFF"}
RESULT_FIELDS = ("facts", "assumptions", "evidence", "unknowns", "changes", "next_action")
RESULT_RE = re.compile(r"AGENT_RESULT_BEGIN\s*(?:```(?:json)?\s*)?(\{.*?\})(?:\s*```)?\s*AGENT_RESULT_END", re.I | re.S)


def _json(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"{path}: se esperaba objeto JSON")
    return data


def _artifact(path: Path) -> dict[str, Any]:
    raw = path.read_bytes()
    return {"path": str(path), "sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw)}


def _clean_text(value: Any, limit: int = 1200) -> str:
    return " ".join(str(value or "").split())[:limit]


def _clean_list(value: Any, *, limit: int = 24, item_limit: int = 500) -> list[str]:
    if not isinstance(value, list):
        return []
    out: list[str] = []
    for item in value[:limit]:
        if isinstance(item, str):
            text = _clean_text(item, item_limit)
            if text:
                out.append(text)
    return out


def validate(packet: dict[str, Any]) -> None:
    if packet.get("schema") != SCHEMA:
        raise ValueError("schema B2B no soportado")
    if packet.get("type") not in MESSAGE_TYPES:
        raise ValueError("tipo B2B no soportado")
    issue = packet.get("issue")
    if not isinstance(issue, int) or isinstance(issue, bool) or issue <= 0:
        raise ValueError("issue B2B invalido")
    handoff = packet.get("handoff")
    if not isinstance(handoff, dict):
        raise ValueError("handoff B2B ausente")
    for key in ("from", "to"):
        value = handoff.get(key)
        if not isinstance(value, str) or not value.strip():
            raise ValueError(f"handoff.{key} B2B invalido")


def verify_task_artifacts(packet: dict[str, Any]) -> None:
    validate(packet)
    if packet.get("type") != "TASK":
        raise ValueError("solo TASK admite verificacion de artefactos")
    artifacts = packet.get("artifacts")
    if not isinstance(artifacts, dict):
        raise ValueError("artifacts B2B ausente")
    for name, meta in artifacts.items():
        if not isinstance(meta, dict):
            raise ValueError(f"artifact {name} invalido")
        path = Path(str(meta.get("path") or ""))
        if not path.is_file():
            raise ValueError(f"artifact {name} ausente: {path}")
        actual = _artifact(path)
        if actual["sha256"] != meta.get("sha256") or actual["bytes"] != meta.get("bytes"):
            raise ValueError(f"artifact {name} cambio despues del handoff")


def _base_artifacts(args: argparse.Namespace) -> dict[str, Any]:
    artifacts: dict[str, Any] = {}
    for name in ("task", "context", "memory", "history", "agents", "rules", "platino_sha"):
        path = getattr(args, name)
        if path.exists():
            artifacts[name] = _artifact(path)
    return artifacts


def build_event(args: argparse.Namespace) -> dict[str, Any]:
    packet = {
        "schema": SCHEMA,
        "type": args.type,
        "issue": args.issue,
        "provider": args.provider or None,
        "worker": args.worker or None,
        "summary": _clean_text(args.summary, 500),
        "refs": _clean_list(args.ref or [], limit=16, item_limit=240),
        "handoff": {"from": args.from_role, "to": args.to_role},
    }
    validate(packet)
    return packet


def build_intake(args: argparse.Namespace) -> dict[str, Any]:
    packet = {
        "schema": SCHEMA,
        "type": "TASK",
        "issue": args.issue,
        "provider": args.provider,
        "worker": args.worker,
        "phase": "plan",
        "goal": "",
        "scope": {"files": [], "max_files": 12, "reserved": False},
        "source_priority": ["repo", "issue", "#181", "#1713", "normas-platino", "wiki", "memory", "ci-history"],
        "abort_on": ["authority_conflict", "unsafe_or_secret_request", "stale_handoff_artifact", "no_safe_scope"],
        "artifacts": _base_artifacts(args),
        "handoff": {"from": "orchestrator", "to": "planner"},
    }
    validate(packet)
    return packet


def build_task(args: argparse.Namespace) -> dict[str, Any]:
    plan = _json(args.plan)
    files = plan.get("files", [])
    if not isinstance(files, list) or any(not isinstance(x, str) for x in files):
        raise ValueError("plan.files invalido")
    artifacts = _base_artifacts(args)
    artifacts["plan"] = _artifact(args.plan)
    if args.claim and args.claim.exists():
        artifacts["claim"] = _artifact(args.claim)
    packet = {
        "schema": SCHEMA,
        "type": "TASK",
        "issue": args.issue,
        "provider": args.provider,
        "worker": args.worker,
        "phase": "implement",
        "goal": _clean_text(plan.get("goal"), 240),
        "scope": {"files": list(dict.fromkeys(files)), "max_files": 12, "reserved": True},
        "source_priority": ["repo", "issue", "#181", "#1713", "normas-platino", "wiki", "memory", "ci-history"],
        "abort_on": ["required_path_outside_claim", "authority_conflict", "unsafe_or_secret_request", "stale_handoff_artifact"],
        "artifacts": artifacts,
        "handoff": {"from": "planner", "to": "implementer"},
    }
    validate(packet)
    return packet


def parse_result(raw: str, task_packet: dict[str, Any]) -> dict[str, Any]:
    match = RESULT_RE.search(raw or "")
    parsed: dict[str, Any] = {}
    if match:
        try:
            value = json.loads(match.group(1))
            parsed = value if isinstance(value, dict) else {}
        except json.JSONDecodeError:
            parsed = {}
    present = [key for key in RESULT_FIELDS if key in parsed]
    coverage = round(100 * len(present) / len(RESULT_FIELDS))
    packet = {
        "schema": SCHEMA,
        "type": "RESULT",
        "issue": int(task_packet["issue"]),
        "provider": task_packet.get("provider"),
        "worker": task_packet.get("worker"),
        "facts": _clean_list(parsed.get("facts")),
        "assumptions": _clean_list(parsed.get("assumptions")),
        "evidence": _clean_list(parsed.get("evidence")),
        "unknowns": _clean_list(parsed.get("unknowns")),
        "changes": _clean_list(parsed.get("changes")),
        "next_action": _clean_text(parsed.get("next_action"), 240),
        "coverage_percent": coverage,
        "contract_status": "complete" if coverage == 100 else ("partial" if present else "missing"),
        "handoff": {"from": "implementer", "to": "reviewer"},
    }
    validate(packet)
    return packet


def build_review(review: dict[str, Any], task: dict[str, Any], result: dict[str, Any]) -> dict[str, Any]:
    packet = {
        "schema": SCHEMA,
        "type": "REVIEW",
        "issue": int(task["issue"]),
        "provider": task.get("provider"),
        "worker": task.get("worker"),
        "status": review.get("status", "skipped"),
        "verdict": review.get("verdict"),
        "findings": _clean_list(review.get("findings"), limit=5, item_limit=240),
        "result_contract_status": result.get("contract_status", "missing"),
        "result_coverage_percent": int(result.get("coverage_percent", 0) or 0),
        "handoff": {"from": "reviewer", "to": "publisher"},
    }
    validate(packet)
    return packet


def compile_prompt(role: str, provider: str, task_path: Path, result_path: Path | None = None) -> str:
    task = _json(task_path)
    validate(task)
    rules = "QWEN.md" if provider == "qwen" else "GEMINI.md"
    if role == "plan":
        return f"""# Agent B2B prompt v1

Rol: planner
Proveedor: {provider}

Lee primero `.agent-plan-task-packet.json`. El workflow ya verificó sus fingerprints. Después lee `AGENTS.md`, `{rules}`, los artefactos declarados por el paquete y obligatoriamente las Normas Platino actuales en `.agent-platino/`.

Jerarquía: repo/issue/#181/#1713/Normas Platino > wiki > memoria > histórico CI.
Trabaja en solo lectura: no edites archivos ni solicites herramientas de edición. Revisa los puntos reales de integración y sus tests antes de cerrar el plan. Si existe un comentario `AGENT_POOL_REPLAN`, usa sus `observed_paths` solo si siguen siendo necesarios.
Termina con AGENT_PLAN_BEGIN y JSON {{"files":["ruta"],"goal":"objetivo"}} seguido de AGENT_PLAN_END. Máximo 12 rutas concretas, sin glob. Usa files=[] si no existe un corte seguro.
"""
    if role == "implement":
        files = ", ".join(task.get("scope", {}).get("files", [])) or "(ninguno)"
        return f"""# Agent B2B prompt v1

Rol: implementer
Proveedor: {provider}

Lee primero `.agent-task-packet.json`. El workflow ya verificó sus fingerprints; trátalos como identidad del handoff. Después lee `AGENTS.md`, `{rules}`, los artefactos declarados por el paquete y obligatoriamente las Normas Platino actuales en `.agent-platino/README.md`, `.agent-platino/docs/FUENTE_DE_VERDAD.md`, `.agent-platino/docs/COOPERACION_AUTONOMA.md`, `.agent-platino/docs/PLANIFICACION_Y_ENTREGAS.md` y `.agent-platino/docs/PRO_CONSUMIDOR.md`.

Jerarquía: repo/issue/#181/#1713/Normas Platino > wiki > memoria > histórico CI.
Scope reservado: {files}. No edites fuera de ese scope. Si necesitas otra ruta, aborta sin saltarte el CLAIM. No hagas commit, push, PR ni merge.

Al terminar emite ambos bloques:
AGENT_RESULT_BEGIN
{{"facts":["hechos verificables"],"assumptions":[],"evidence":["pruebas o rutas"],"unknowns":[],"changes":["cambios realizados"],"next_action":"review"}}
AGENT_RESULT_END
AGENT_MEMORY_BEGIN
{{"summary":"aprendizaje técnico reusable y sin secretos","tags":["b2b"]}}
AGENT_MEMORY_END
"""
    if role == "review":
        status = "missing"
        coverage = 0
        if result_path and result_path.exists():
            result = _json(result_path)
            status = str(result.get("contract_status", status))
            coverage = int(result.get("coverage_percent", coverage) or 0)
        return f"""# Agent B2B prompt v1

Rol: reviewer
Proveedor: {provider}
ResultPacket: {status}, cobertura {coverage}%.

Lee `.agent-review-input.md` y nada más aparte de este prompt. No uses shell ni edites. Revisa únicamente incumplimiento del issue/plan, bug claro del diff, test imprescindible ausente o violación evidente de seguridad. Máximo 5 hallazgos. Mantén compatibilidad emitiendo AGENT_REVIEW_BEGIN con JSON {{"verdict":"approve","findings":[]}} o findings.
"""
    raise ValueError("rol de prompt no soportado")


def _write(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("event")
    p.add_argument("--type", choices=["CLAIM", "EVIDENCE", "BLOCKER", "QUESTION", "HANDOFF"], required=True)
    p.add_argument("--issue", type=int, required=True)
    p.add_argument("--provider", choices=["qwen", "gemini"], default="")
    p.add_argument("--worker", default="")
    p.add_argument("--from-role", required=True)
    p.add_argument("--to-role", required=True)
    p.add_argument("--summary", required=True)
    p.add_argument("--ref", action="append", default=[])
    p.add_argument("--output", type=Path, required=True)
    p = sub.add_parser("intake")
    p.add_argument("--issue", type=int, required=True)
    p.add_argument("--provider", choices=["qwen", "gemini"], required=True)
    p.add_argument("--worker", required=True)
    for name in ("task", "context", "memory", "history", "agents", "rules", "platino-sha", "output"):
        p.add_argument(f"--{name}", type=Path, required=True)
    p = sub.add_parser("task")
    p.add_argument("--issue", type=int, required=True)
    p.add_argument("--provider", choices=["qwen", "gemini"], required=True)
    p.add_argument("--worker", required=True)
    for name in ("task", "plan", "context", "memory", "history", "agents", "rules", "platino-sha", "output"):
        p.add_argument(f"--{name}", type=Path, required=True)
    p.add_argument("--claim", type=Path)
    p = sub.add_parser("result")
    p.add_argument("--summary-file", type=Path, required=True)
    p.add_argument("--task-packet", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    p = sub.add_parser("review")
    p.add_argument("--review", type=Path, required=True)
    p.add_argument("--task-packet", type=Path, required=True)
    p.add_argument("--result-packet", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    p = sub.add_parser("prompt")
    p.add_argument("--role", choices=["plan", "implement", "review"], required=True)
    p.add_argument("--provider", choices=["qwen", "gemini"], required=True)
    p.add_argument("--task-packet", type=Path, required=True)
    p.add_argument("--result-packet", type=Path)
    p.add_argument("--output", type=Path, required=True)
    p = sub.add_parser("validate")
    p.add_argument("--packet", type=Path, required=True)
    p = sub.add_parser("verify")
    p.add_argument("--packet", type=Path, required=True)
    args = parser.parse_args()
    if args.cmd == "event":
        payload = build_event(args)
        _write(args.output, payload)
        print(json.dumps(payload, ensure_ascii=False))
        return 0
    if args.cmd == "intake":
        payload = build_intake(args)
        _write(args.output, payload)
        print(json.dumps(payload, ensure_ascii=False))
        return 0
    if args.cmd == "task":
        payload = build_task(args)
        _write(args.output, payload)
        print(json.dumps(payload, ensure_ascii=False))
        return 0
    if args.cmd == "result":
        task = _json(args.task_packet)
        validate(task)
        raw = args.summary_file.read_text(encoding="utf-8") if args.summary_file.exists() else ""
        payload = parse_result(raw, task)
        _write(args.output, payload)
        print(json.dumps(payload, ensure_ascii=False))
        return 0
    if args.cmd == "review":
        task = _json(args.task_packet)
        result = _json(args.result_packet)
        payload = build_review(_json(args.review), task, result)
        _write(args.output, payload)
        print(json.dumps(payload, ensure_ascii=False))
        return 0
    if args.cmd == "prompt":
        args.output.write_text(compile_prompt(args.role, args.provider, args.task_packet, args.result_packet), encoding="utf-8")
        return 0
    if args.cmd == "verify":
        verify_task_artifacts(_json(args.packet))
        return 0
    validate(_json(args.packet))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
