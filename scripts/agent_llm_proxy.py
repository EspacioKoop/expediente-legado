#!/usr/bin/env python3
"""Proxy local que adapta las peticiones del CLI al proveedor real (#1928).

El CLI de Qwen habla el dialecto de OpenAI, y no todos los proveedores
«compatibles» lo aceptan entero:

- Mistral rechaza con 422 (`extra_forbidden`) cualquier campo que no conozca,
  y exige ids de tool call de 9 caracteres alfanuméricos.
- Groq limita `max_tokens` (16 384 en qwen3.8-27b) y devuelve 400 si se pasa.

El proxy corre dentro del job en 127.0.0.1, recibe la petición del CLI, la
adapta según el perfil del host y la reenvía en streaming. La cabecera
`Authorization` pasa tal cual y nunca se registra; el log solo lleva el perfil,
los campos descartados y el cuerpo recortado de los errores del proveedor.

Uso:
    agent_llm_proxy.py detect URL           # perfil del host o "passthrough"
    agent_llm_proxy.py serve --upstream URL --profile mistral --port 18080
"""

from __future__ import annotations

import argparse
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import re
import sys
from typing import Any
import urllib.error
from urllib.parse import urlsplit
import urllib.request

PASSTHROUGH = "passthrough"
HOST_PROFILES = {
    "api.mistral.ai": "mistral",
    "api.groq.com": "groq",
}
HEALTH_PATH = "/__health"
UPSTREAM_TIMEOUT = 600
LOG_ERROR_BYTES = 600
CHUNK = 8192

MISTRAL_TOP = {
    "model", "messages", "temperature", "top_p", "max_tokens", "stream", "stop",
    "random_seed", "response_format", "tools", "tool_choice", "presence_penalty",
    "frequency_penalty", "n", "parallel_tool_calls", "prediction", "safe_prompt",
}
MISTRAL_MESSAGE = {
    "system": {"role", "content"},
    "user": {"role", "content"},
    "assistant": {"role", "content", "tool_calls", "prefix"},
    "tool": {"role", "content", "tool_call_id", "name"},
}
MISTRAL_PART = {"type", "text", "image_url"}
MISTRAL_TOOL_CALL_ID = re.compile(r"^[A-Za-z0-9]{9}$")
GROQ_MAX_TOKENS = 16384
MISTRAL_BUILTIN_TOOLS = {
    "WebSearchTool", "WebSearchPremiumTool", "CodeInterpreterTool",
    "ImageGenerationTool", "DocumentLibraryTool", "CustomConnector",
}


def detect_profile(url: str) -> str:
    host = (urlsplit(url).hostname or "").lower()
    return HOST_PROFILES.get(host, PASSTHROUGH)


def _mistral_id(value: Any) -> Any:
    """Id aceptable por Mistral, estable para que llamada y respuesta casen."""
    if not isinstance(value, str) or MISTRAL_TOOL_CALL_ID.match(value):
        return value
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()
    alfabeto = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    numero = int(digest, 16)
    salida = []
    for _ in range(9):
        numero, resto = divmod(numero, len(alfabeto))
        salida.append(alfabeto[resto])
    return "".join(salida)


def _keep(data: dict[str, Any], allowed: set[str], dropped: set[str], where: str) -> dict[str, Any]:
    for key in data:
        if key not in allowed:
            dropped.add(f"{where}.{key}")
    return {k: v for k, v in data.items() if k in allowed}


def _mistral_message(message: Any, dropped: set[str]) -> Any:
    if not isinstance(message, dict):
        return message
    role = message.get("role")
    allowed = MISTRAL_MESSAGE.get(role, {"role", "content"})
    clean = _keep(message, allowed, dropped, f"message[{role}]")
    content = clean.get("content")
    if isinstance(content, list):
        clean["content"] = [
            _keep(part, MISTRAL_PART, dropped, "content_part") if isinstance(part, dict) else part
            for part in content
        ]
    if role == "assistant" and clean.get("content") is None and clean.get("tool_calls"):
        # Mistral no admite content nulo junto a tool_calls.
        clean["content"] = ""
    if isinstance(clean.get("tool_calls"), list):
        calls = []
        for call in clean["tool_calls"]:
            if not isinstance(call, dict):
                continue
            call = _keep(call, {"id", "type", "function"}, dropped, "tool_call")
            if "id" in call:
                call["id"] = _mistral_id(call["id"])
            if isinstance(call.get("function"), dict):
                call["function"] = _keep(call["function"], {"name", "arguments"}, dropped, "tool_call.function")
            calls.append(call)
        clean["tool_calls"] = calls
    if "tool_call_id" in clean:
        clean["tool_call_id"] = _mistral_id(clean["tool_call_id"])
    return clean


def _mistral_tool(tool: Any, dropped: set[str]) -> Any:
    if not isinstance(tool, dict):
        return tool
    clean = _keep(tool, {"type", "function"}, dropped, "tool")
    if isinstance(clean.get("function"), dict):
        clean["function"] = _keep(
            clean["function"], {"name", "description", "parameters"}, dropped, "tool.function"
        )
    return clean


def adapt_mistral(body: dict[str, Any], dropped: set[str]) -> dict[str, Any]:
    body = dict(body)
    if "max_completion_tokens" in body:
        body.setdefault("max_tokens", body["max_completion_tokens"])
    if "seed" in body:
        body.setdefault("random_seed", body["seed"])
    clean = _keep(body, MISTRAL_TOP, dropped, "body")
    # Los renombrados no cuentan como descartados.
    dropped.discard("body.max_completion_tokens")
    dropped.discard("body.seed")
    if isinstance(clean.get("messages"), list):
        clean["messages"] = [_mistral_message(m, dropped) for m in clean["messages"]]
    if isinstance(clean.get("tools"), list):
        clean["tools"] = [_mistral_tool(t, dropped) for t in clean["tools"]]
    return clean


def adapt_groq(body: dict[str, Any], dropped: set[str]) -> dict[str, Any]:
    body = dict(body)
    for key in ("max_tokens", "max_completion_tokens"):
        value = body.get(key)
        if isinstance(value, int) and value > GROQ_MAX_TOKENS:
            body[key] = GROQ_MAX_TOKENS
            dropped.add(f"body.{key}>{GROQ_MAX_TOKENS}")
    return body


ADAPTERS = {"mistral": adapt_mistral, "groq": adapt_groq}


def adapt(profile: str, body: dict[str, Any]) -> tuple[dict[str, Any], set[str]]:
    dropped: set[str] = set()
    adapter = ADAPTERS.get(profile)
    if adapter is None:
        return body, dropped
    return adapter(body, dropped), dropped


def resumen_error(cuerpo: bytes) -> str:
    """Error del proveedor en una línea por fallo, sin los valores de entrada.

    Mistral devuelve errores de Pydantic con un intento por cada tipo de la
    unión (WebSearchTool, CodeInterpreterTool…) y el motivo útil queda al final;
    `input` puede llevar texto del prompt, así que no se registra.
    """
    try:
        datos = json.loads(cuerpo)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return cuerpo[:LOG_ERROR_BYTES].decode("utf-8", "replace")
    detalle = datos.get("detail") if isinstance(datos, dict) else None
    if isinstance(detalle, list):
        lineas = []
        for item in detalle:
            if not isinstance(item, dict):
                continue
            partes = [str(parte) for parte in item.get("loc", [])]
            # Los intentos contra herramientas integradas de Mistral son ruido:
            # el cliente siempre manda herramientas de tipo function.
            if any(parte in MISTRAL_BUILTIN_TOOLS for parte in partes):
                continue
            lineas.append(f"{'.'.join(partes)}: {item.get('msg', '')} ({item.get('type', '')})")
        if lineas:
            return " | ".join(lineas)[:LOG_ERROR_BYTES * 4]
    return json.dumps(datos, ensure_ascii=False)[:LOG_ERROR_BYTES]


def upstream_url(upstream: str, path: str) -> str:
    """El CLI apunta a http://127.0.0.1:P/v1; se sustituye ese /v1 por la base real."""
    base = upstream.rstrip("/")
    rest = path[3:] if path.startswith("/v1") else path
    return base + rest


def make_handler(upstream: str, profile: str, log):
    class Handler(BaseHTTPRequestHandler):
        # Respuestas delimitadas por cierre: sirven igual con y sin streaming.
        protocol_version = "HTTP/1.0"

        def log_message(self, fmt, *args):  # noqa: D401 - silencia el log por defecto
            return

        def do_GET(self):
            if self.path == HEALTH_PATH:
                self._reply(200, b'{"ok":true}', "application/json")
                return
            self._forward(None)

        def do_POST(self):
            length = int(self.headers.get("Content-Length") or 0)
            raw = self.rfile.read(length) if length else b""
            dropped: set[str] = set()
            try:
                body = json.loads(raw or b"{}")
            except json.JSONDecodeError:
                body = None
            if isinstance(body, dict):
                body, dropped = adapt(profile, body)
                raw = json.dumps(body, ensure_ascii=False).encode("utf-8")
            if dropped:
                print(f"[{profile}] {self.path} descartado: {', '.join(sorted(dropped))}", file=log, flush=True)
            self._forward(raw)

        def _reply(self, status: int, data: bytes, content_type: str) -> None:
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _forward(self, data: bytes | None) -> None:
            headers = {"Accept-Encoding": "identity"}
            for name in ("Authorization", "Content-Type", "Accept", "User-Agent"):
                value = self.headers.get(name)
                if value:
                    headers[name] = value
            request = urllib.request.Request(
                upstream_url(upstream, self.path),
                data=data,
                headers=headers,
                method="POST" if data is not None else "GET",
            )
            try:
                response = urllib.request.urlopen(request, timeout=UPSTREAM_TIMEOUT)
            except urllib.error.HTTPError as exc:
                cuerpo = exc.read()
                print(f"[{profile}] {self.path} -> {exc.code}: {resumen_error(cuerpo)}", file=log, flush=True)
                self._reply(exc.code, cuerpo, exc.headers.get("Content-Type", "application/json"))
                return
            except (urllib.error.URLError, TimeoutError) as exc:
                print(f"[{profile}] {self.path} -> sin respuesta: {exc}", file=log, flush=True)
                self._reply(502, json.dumps({"error": {"message": f"proxy: {exc}"}}).encode(), "application/json")
                return
            with response:
                self.send_response(response.status)
                self.send_header("Content-Type", response.headers.get("Content-Type", "application/json"))
                self.end_headers()
                while True:
                    chunk = response.read1(CHUNK) if hasattr(response, "read1") else response.read(CHUNK)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    self.wfile.flush()

    return Handler


def serve(upstream: str, profile: str, port: int, log=sys.stderr) -> ThreadingHTTPServer:
    server = ThreadingHTTPServer(("127.0.0.1", port), make_handler(upstream, profile, log))
    server.daemon_threads = True
    return server


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)
    detect = sub.add_parser("detect")
    detect.add_argument("url")
    run = sub.add_parser("serve")
    run.add_argument("--upstream", required=True)
    run.add_argument("--profile", required=True, choices=sorted(ADAPTERS))
    run.add_argument("--port", type=int, default=18080)
    args = parser.parse_args(argv)

    if args.command == "detect":
        print(detect_profile(args.url))
        return 0
    server = serve(args.upstream, args.profile, args.port)
    print(f"[{args.profile}] proxy en 127.0.0.1:{args.port} -> {urlsplit(args.upstream).hostname}", file=sys.stderr, flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
