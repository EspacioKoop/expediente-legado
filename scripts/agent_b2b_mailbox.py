#!/usr/bin/env python3
"""Cliente mínimo para el mailbox B2B del control-plane Deno (#1870)."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import sys
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlsplit, urlunsplit
from urllib.request import Request, urlopen

AUDIENCE = "siga98-agent-pool"
SCHEMA = 1
MESSAGE_TYPES = {"QUESTION", "BLOCKER", "EVIDENCE", "HANDOFF", "RESULT", "REVIEW"}
RECIPIENTS = {"dispatcher", "worker", "reviewer"}
# Códigos públicos de agent_b2b.ts. Un proxy puede devolver mensajes libres
# con credenciales o instrucciones de log; solo se publica el protocolo conocido.
HTTP_ERROR_CODES = {
    "forbidden", "invalid_request", "sensitive_payload",
    "idempotency_conflict", "message_race", "not_found",
}
TOKEN_RE = re.compile(r"^[A-Za-z0-9._:/#@-]+$")
SENSITIVE_RE = re.compile(
    r"(gh[pousr]_|github_pat_|sk-[A-Za-z0-9]|Bearer\s+[A-Za-z0-9._-]{12,}|"
    r"-----BEGIN [A-Z ]*PRIVATE KEY-----)",
    re.IGNORECASE,
)


class MailboxError(RuntimeError):
    """Error controlado del cliente sin incluir credenciales."""


def _text(value: Any, limit: int) -> str:
    if not isinstance(value, str):
        return ""
    return value.strip()[:limit]


def _token(value: Any, limit: int) -> str:
    value = _text(value, limit)
    return value if value and TOKEN_RE.fullmatch(value) else ""


def _evidence(values: list[str] | None) -> list[str]:
    out: list[str] = []
    for value in (values or [])[:8]:
        clean = _text(value, 500)
        if clean:
            out.append(clean)
    return out


def _reject_sensitive(*values: str) -> None:
    if SENSITIVE_RE.search("\n".join(values)):
        raise ValueError("payload sensible rechazado")


def control_base_url(value: str) -> str:
    """Normaliza SIGA98_FEEDBACK_FALLBACK_URL al origen del control-plane."""

    raw = _text(value, 2048).rstrip("/")
    if raw.endswith("/api/report"):
        raw = raw[: -len("/api/report")]
    parsed = urlsplit(raw)
    if parsed.scheme != "https" or not parsed.netloc or parsed.query or parsed.fragment:
        raise ValueError("control URL inválida: se requiere HTTPS sin query/fragment")
    path = parsed.path.rstrip("/")
    return urlunsplit((parsed.scheme, parsed.netloc, path, "", ""))


def build_send_payload(
    *,
    task_id: str,
    message_type: str,
    recipient: str,
    idempotency_key: str,
    correlation_id: str = "",
    reply_to: str = "",
    subject: str = "",
    body: str = "",
    evidence: list[str] | None = None,
    blocking: bool = False,
    ttl_seconds: int | None = None,
) -> dict[str, Any]:
    task = _token(task_id, 240)
    kind = _text(message_type, 24).upper()
    target = _text(recipient, 24)
    idem = _token(idempotency_key, 120)
    correlation = _token(correlation_id, 120) if correlation_id else ""
    reply = _token(reply_to, 120) if reply_to else ""
    clean_subject = _text(subject, 160)
    clean_body = _text(body, 4000)
    clean_evidence = _evidence(evidence)

    if not task or kind not in MESSAGE_TYPES or target not in RECIPIENTS or not idem:
        raise ValueError("sobre B2B inválido")
    if correlation_id and not correlation:
        raise ValueError("correlation_id inválido")
    if reply_to and not reply:
        raise ValueError("reply_to inválido")
    if not clean_subject and not clean_body and not clean_evidence:
        raise ValueError("mensaje B2B vacío")
    _reject_sensitive(clean_subject, clean_body, *clean_evidence)

    payload: dict[str, Any] = {
        "schema": SCHEMA,
        "task_id": task,
        "message_type": kind,
        "recipient": target,
        "idempotency_key": idem,
        "subject": clean_subject,
        "body": clean_body,
        "evidence": clean_evidence,
        "blocking": bool(blocking or kind == "BLOCKER"),
    }
    if correlation:
        payload["correlation_id"] = correlation
    if reply:
        payload["reply_to"] = reply
    if ttl_seconds is not None:
        payload["ttl_seconds"] = int(ttl_seconds)
    return payload


def build_inbox_payload(*, recipient: str, task_id: str = "", limit: int = 20) -> dict[str, Any]:
    target = _text(recipient, 24)
    task = _token(task_id, 240) if task_id else ""
    if target not in RECIPIENTS:
        raise ValueError("recipient B2B inválido")
    if target != "dispatcher" and not task:
        raise ValueError("worker/reviewer requieren task_id")
    if task_id and not task:
        raise ValueError("task_id inválido")
    return {
        "schema": SCHEMA,
        "recipient": target,
        "task_id": task,
        "limit": min(50, max(1, int(limit))),
    }


def build_ack_payload(*, recipient: str, task_id: str, message_id: str) -> dict[str, Any]:
    target = _text(recipient, 24)
    task = _token(task_id, 240)
    message = _token(message_id, 120)
    if target not in RECIPIENTS or not task or not message:
        raise ValueError("ACK B2B inválido")
    return {"schema": SCHEMA, "recipient": target, "task_id": task, "message_id": message}


def oidc_request_url(request_url: str) -> str:
    raw = _text(request_url, 4096)
    parsed = urlsplit(raw)
    if parsed.scheme != "https" or not parsed.netloc:
        raise ValueError("ACTIONS_ID_TOKEN_REQUEST_URL inválida")
    query = parsed.query
    audience = urlencode({"audience": AUDIENCE})
    query = f"{query}&{audience}" if query else audience
    return urlunsplit((parsed.scheme, parsed.netloc, parsed.path, query, parsed.fragment))


def request_oidc_token(timeout: int = 12) -> str:
    request_url = os.environ.get("ACTIONS_ID_TOKEN_REQUEST_URL", "")
    request_token = os.environ.get("ACTIONS_ID_TOKEN_REQUEST_TOKEN", "")
    if not request_url or not request_token:
        raise MailboxError("OIDC de GitHub Actions no disponible")
    request = Request(
        oidc_request_url(request_url),
        headers={"Authorization": f"bearer {request_token}", "Accept": "application/json"},
    )
    try:
        with urlopen(request, timeout=timeout) as response:
            payload = json.load(response)
    except (HTTPError, URLError, TimeoutError, json.JSONDecodeError) as error:
        raise MailboxError("no se pudo obtener OIDC de GitHub Actions") from error
    token = payload.get("value") if isinstance(payload, dict) else None
    if not isinstance(token, str) or token.count(".") != 2:
        raise MailboxError("GitHub Actions devolvió un OIDC inválido")
    return token


def post_json(
    *, base_url: str, endpoint: str, payload: dict[str, Any], oidc_token: str, timeout: int = 12
) -> dict[str, Any]:
    base = control_base_url(base_url)
    token = _text(oidc_token, 12000)
    if token.count(".") != 2:
        raise MailboxError("OIDC inválido")
    request = Request(
        base + endpoint,
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        data=json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8"),
    )
    try:
        with urlopen(request, timeout=timeout) as response:
            data = json.load(response)
    except HTTPError as error:
        error_name = "http_error"
        try:
            body = json.load(error)
            candidate = body.get("error") if isinstance(body, dict) else None
            if isinstance(candidate, str) and candidate in HTTP_ERROR_CODES:
                error_name = candidate
        except (json.JSONDecodeError, TypeError, ValueError):
            pass
        raise MailboxError(f"mailbox HTTP {error.code}: {error_name}") from error
    except (URLError, TimeoutError, json.JSONDecodeError) as error:
        raise MailboxError("mailbox no disponible o respuesta inválida") from error
    if not isinstance(data, dict):
        raise MailboxError("respuesta mailbox no es un objeto JSON")
    return data


def _body(args: argparse.Namespace) -> str:
    if args.body_file:
        return args.body_file.read_text(encoding="utf-8")
    return args.body or ""


def _write_result(data: dict[str, Any], output: Path | None) -> None:
    rendered = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    if output:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(rendered, encoding="utf-8")
    else:
        sys.stdout.write(rendered)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--control-url",
        default=os.environ.get("SIGA98_FEEDBACK_FALLBACK_URL", ""),
        help="URL del gateway; puede terminar en /api/report",
    )
    parser.add_argument("--oidc-token", default="", help="OIDC ya obtenido; normalmente se omite")
    parser.add_argument("--timeout", type=int, default=12)
    parser.add_argument("--output", type=Path)
    sub = parser.add_subparsers(dest="command", required=True)

    send = sub.add_parser("send")
    send.add_argument("--task-id", required=True)
    send.add_argument("--type", required=True, choices=sorted(MESSAGE_TYPES))
    send.add_argument("--recipient", required=True, choices=sorted(RECIPIENTS))
    send.add_argument("--idempotency-key", required=True)
    send.add_argument("--correlation-id", default="")
    send.add_argument("--reply-to", default="")
    send.add_argument("--subject", default="")
    body_group = send.add_mutually_exclusive_group()
    body_group.add_argument("--body", default="")
    body_group.add_argument("--body-file", type=Path)
    send.add_argument("--evidence", action="append", default=[])
    send.add_argument("--blocking", action="store_true")
    send.add_argument("--ttl-seconds", type=int)

    inbox = sub.add_parser("inbox")
    inbox.add_argument("--recipient", required=True, choices=sorted(RECIPIENTS))
    inbox.add_argument("--task-id", default="")
    inbox.add_argument("--limit", type=int, default=20)

    ack = sub.add_parser("ack")
    ack.add_argument("--recipient", required=True, choices=sorted(RECIPIENTS))
    ack.add_argument("--task-id", required=True)
    ack.add_argument("--message-id", required=True)

    args = parser.parse_args()
    if not args.control_url:
        parser.error("--control-url o SIGA98_FEEDBACK_FALLBACK_URL es obligatorio")

    try:
        if args.command == "send":
            payload = build_send_payload(
                task_id=args.task_id,
                message_type=args.type,
                recipient=args.recipient,
                idempotency_key=args.idempotency_key,
                correlation_id=args.correlation_id,
                reply_to=args.reply_to,
                subject=args.subject,
                body=_body(args),
                evidence=args.evidence,
                blocking=args.blocking,
                ttl_seconds=args.ttl_seconds,
            )
            endpoint = "/api/agent-pool/b2b/send"
        elif args.command == "inbox":
            payload = build_inbox_payload(
                recipient=args.recipient, task_id=args.task_id, limit=args.limit
            )
            endpoint = "/api/agent-pool/b2b/inbox"
        else:
            payload = build_ack_payload(
                recipient=args.recipient, task_id=args.task_id, message_id=args.message_id
            )
            endpoint = "/api/agent-pool/b2b/ack"

        oidc = args.oidc_token or request_oidc_token(timeout=args.timeout)
        result = post_json(
            base_url=args.control_url,
            endpoint=endpoint,
            payload=payload,
            oidc_token=oidc,
            timeout=args.timeout,
        )
        _write_result(result, args.output)
        return 0
    except (ValueError, MailboxError, OSError) as error:
        print(f"agent_b2b_mailbox: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
