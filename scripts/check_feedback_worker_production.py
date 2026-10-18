#!/usr/bin/env python3
"""Valida el /health público del Worker F9 sin realizar POST ni usar tokens.

También admite --health-json para pruebas offline. Nunca imprime el cuerpo
remoto completo: /health solo debe suministrar datos de estado.
"""
from __future__ import annotations

import argparse
import ipaddress
import json
from pathlib import Path
import re
import sys
from urllib.parse import urlsplit, urlunsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener


class NoRedirect(HTTPRedirectHandler):
    """Never follow a 3xx to another host or an insecure/private target."""

    def redirect_request(self, request, fp, code, msg, headers, newurl):
        return None


FIELD_RE = {
    "version": re.compile(r"\bversion:\s*(\d+)\s*,"),
    "publication_guard": re.compile(r"\bpublication_guard:\s*(\d+)\s*,"),
}


def expected_contract(source: str) -> dict[str, int]:
    result = {}
    for name, regex in FIELD_RE.items():
        match = regex.search(source)
        if not match:
            raise ValueError("falta contrato público de /health: " + name)
        result[name] = int(match.group(1))
    return result


def health_url(endpoint: str) -> str:
    p = urlsplit(endpoint.strip())
    if p.scheme != "https" or not p.hostname or p.username or p.password:
        raise ValueError("URL de feedback no es HTTPS público válido")
    if p.query or p.fragment or p.port not in (None, 443):
        raise ValueError("URL de feedback no debe tener query/fragment/puerto")
    if p.hostname.lower() == "localhost" or p.hostname.lower().endswith(".localhost"):
        raise ValueError("Host no público")
    try:
        ip = ipaddress.ip_address(p.hostname)
    except ValueError:
        pass
    else:
        if not ip.is_global:
            raise ValueError("IP no pública")
    if p.path.rstrip("/") not in ("", "/api/report"):
        raise ValueError("Ruta de feedback inesperada")
    return urlunsplit(("https", p.netloc, "/health", "", ""))


def validate_health(source: str, data: object) -> list[str]:
    contract = expected_contract(source)
    if not isinstance(data, dict):
        return ["health debe ser un objeto JSON"]
    errors = []
    if data.get("ok") is not True:
        errors.append("health.ok != true")
    if data.get("service") != "siga98-feedback":
        errors.append("health.service inesperado")
    if data.get("github_configured") is not True:
        errors.append("github_configured != true")
    for key, expected in contract.items():
        value = data.get(key)
        if type(value) is not int or value != expected:
            errors.append(f"{key} desactualizado o ausente")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--health-json", type=Path)
    group.add_argument("--url", help="Endpoint HTTPS del Worker (/api/report o base)")
    args = parser.parse_args()
    try:
        source = args.source.read_text(encoding="utf-8")
        if args.health_json:
            raw = args.health_json.read_bytes()
        else:
            # Despliegue real: GET a /health, nunca envío de datos de juego.
            request = Request(health_url(args.url), headers={"Accept": "application/json"})
            with build_opener(NoRedirect()).open(request, timeout=15) as response:
                raw = response.read(8193)
        if len(raw) > 8192:
            raise ValueError("health supera tamaño máximo")
        result = json.loads(raw)
        errors = validate_health(source, result)
    except (OSError, ValueError, UnicodeError, json.JSONDecodeError, TimeoutError) as exc:
        print("ERROR: no se pudo validar /health del Worker", file=sys.stderr)
        return 2
    print(json.dumps({"ok": not errors, "errors": errors}, ensure_ascii=False))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
