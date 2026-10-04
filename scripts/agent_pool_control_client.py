#!/usr/bin/env python3
"""Cliente mínimo del control-plane Deno para workflows ya checkoutados.

Centraliza OIDC + POST para evitar repetir el mismo protocolo en cada fase del
worker. La adquisición inicial permanece inline porque ocurre antes del checkout
y debe poder bloquear un worker duplicado sin materializar el repositorio.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Any, Mapping
from urllib import request


AUDIENCE = "siga98-agent-pool"


def control_base(url: str) -> str:
    base = url.rstrip("/")
    if base.endswith("/api/report"):
        base = base[: -len("/api/report")]
    return base


def oidc_url(raw: str) -> str:
    separator = "&" if "?" in raw else "?"
    return f"{raw}{separator}audience={AUDIENCE}"


def _read_json(response: Any) -> dict[str, Any]:
    raw = response.read()
    if not raw:
        return {}
    if isinstance(raw, bytes):
        raw = raw.decode("utf-8")
    data = json.loads(raw)
    if not isinstance(data, dict):
        raise ValueError("respuesta JSON no es un objeto")
    return data


def oidc_token(
    env: Mapping[str, str] | None = None,
    *,
    opener=request.urlopen,
) -> str:
    source = os.environ if env is None else env
    token = source.get("ACTIONS_ID_TOKEN_REQUEST_TOKEN", "")
    raw_url = source.get("ACTIONS_ID_TOKEN_REQUEST_URL", "")
    if not token or not raw_url:
        raise RuntimeError("OIDC de GitHub Actions no disponible")

    req = request.Request(
        oidc_url(raw_url),
        headers={"Authorization": f"bearer {token}"},
    )
    with opener(req, timeout=12) as response:
        data = _read_json(response)
    value = data.get("value")
    if not isinstance(value, str) or not value:
        raise RuntimeError("GitHub Actions no devolvió token OIDC")
    return value


def post_json(
    base_url: str,
    endpoint: str,
    payload: dict[str, Any],
    *,
    env: Mapping[str, str] | None = None,
    opener=request.urlopen,
) -> dict[str, Any]:
    token = oidc_token(env, opener=opener)
    body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    req = request.Request(
        control_base(base_url) + endpoint,
        data=body,
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    with opener(req, timeout=12) as response:
        return _read_json(response)


def transition(
    base_url: str,
    issue: int,
    lease_id: str,
    state: str,
    *,
    env: Mapping[str, str] | None = None,
    opener=request.urlopen,
) -> dict[str, Any]:
    return post_json(
        base_url,
        "/api/agent-pool/transition",
        {
            "schema": 1,
            "issue": issue,
            "lease_id": lease_id,
            "state": state,
        },
        env=env,
        opener=opener,
    )


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser()
    sub = root.add_subparsers(dest="command", required=True)

    command = sub.add_parser("transition")
    command.add_argument("--base-url", required=True)
    command.add_argument("--issue", required=True, type=int)
    command.add_argument("--lease-id", required=True)
    command.add_argument(
        "--state",
        required=True,
        choices=("planning", "implementing", "validating", "publishing"),
    )
    return root


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "transition":
            result = transition(args.base_url, args.issue, args.lease_id, args.state)
        else:
            raise AssertionError(args.command)
    except Exception as exc:
        print(f"agent-pool control error: {exc}", file=sys.stderr)
        return 1

    print(json.dumps(result, separators=(",", ":"), sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
