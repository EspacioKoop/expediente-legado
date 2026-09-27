#!/usr/bin/env python3
"""Router opcional de workers para el autopilot usando la API System One de Kev."""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections.abc import Callable, Mapping, Sequence
from typing import Any
from urllib import request


DEFAULT_MODEL = "kev-latest"
DEFAULT_TIMEOUT_SECONDS = 5.0
DEFAULT_MIN_CONFIDENCE = 0.45
PROVIDER_DESCRIPTIONS = {
    "qwen": "Qwen Code worker configured for repository code changes.",
    "gemini": "Gemini CLI worker configured for repository code changes.",
}


class KevProtocolError(RuntimeError):
    """Respuesta de Kev válida a nivel HTTP pero incompatible con el contrato esperado."""


def _system_one_url(base_url: str) -> str:
    normalized = base_url.strip().rstrip("/")
    if normalized.endswith("/v1/systemone"):
        return normalized
    return f"{normalized}/v1/systemone"


def call_system_one(
    *,
    base_url: str,
    api_key: str | None,
    model: str,
    state: Any,
    questions: Mapping[str, Any],
    timeout: float,
    urlopen: Callable[..., Any] = request.urlopen,
) -> dict[str, Any]:
    """Invoca Kev sin dependencias externas y devuelve el JSON de respuesta."""

    payload = json.dumps(
        {"state": state, "model": model, "questions": questions},
        ensure_ascii=False,
    ).encode("utf-8")
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "User-Agent": "expediente-legado-kev-router/1",
    }
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"

    req = request.Request(
        _system_one_url(base_url),
        data=payload,
        headers=headers,
        method="POST",
    )
    with urlopen(req, timeout=timeout) as response:
        raw = response.read()

    parsed = json.loads(raw.decode("utf-8"))
    if not isinstance(parsed, dict):
        raise KevProtocolError("Kev no devolvió un objeto JSON")
    return parsed


def _available_providers(has_qwen: bool, has_gemini: bool) -> list[str]:
    providers: list[str] = []
    if has_qwen:
        providers.append("qwen")
    if has_gemini:
        providers.append("gemini")
    return providers


def _requested_explicit_provider(
    requested_provider: str,
    labels: Sequence[str],
) -> str | None:
    if requested_provider in {"qwen", "gemini"}:
        return requested_provider

    label_set = set(labels)
    for provider in ("qwen", "gemini"):
        if f"agent:{provider}" in label_set:
            return provider
    return None


def _fallback_provider(available: Sequence[str]) -> str | None:
    """Conserva el orden histórico del autopilot: Qwen y después Gemini."""

    if "qwen" in available:
        return "qwen"
    if "gemini" in available:
        return "gemini"
    return None


def _bounded_state(state: Any) -> Any:
    """Evita entregar accidentalmente un documento enorme al clasificador."""

    if isinstance(state, str):
        return state[:12000]
    if isinstance(state, Mapping):
        bounded: dict[str, Any] = {}
        for key, value in list(state.items())[:24]:
            bounded[str(key)[:120]] = _bounded_state(value)
        return bounded
    if isinstance(state, Sequence) and not isinstance(state, (str, bytes, bytearray)):
        return [_bounded_state(value) for value in list(state)[:24]]
    return state


def route_provider(
    *,
    state: Any,
    labels: Sequence[str] = (),
    requested_provider: str = "auto",
    has_qwen: bool,
    has_gemini: bool,
    base_url: str | None,
    api_key: str | None = None,
    model: str = DEFAULT_MODEL,
    timeout: float = DEFAULT_TIMEOUT_SECONDS,
    min_confidence: float = DEFAULT_MIN_CONFIDENCE,
    requester: Callable[..., dict[str, Any]] = call_system_one,
) -> dict[str, Any]:
    """Selecciona worker. Kev nunca puede romper la cola: todo fallo cae al fallback."""

    available = _available_providers(has_qwen, has_gemini)
    fallback = _fallback_provider(available)
    if fallback is None:
        return {
            "provider": None,
            "source": "unavailable",
            "confidence": None,
            "available": [],
        }

    explicit = _requested_explicit_provider(requested_provider, labels)
    if explicit is not None:
        if explicit not in available:
            return {
                "provider": None,
                "requested_provider": explicit,
                "source": "explicit-unavailable",
                "confidence": None,
                "available": available,
            }
        return {
            "provider": explicit,
            "source": "explicit",
            "confidence": 1.0,
            "available": available,
        }

    if len(available) == 1:
        return {
            "provider": available[0],
            "source": "single-provider",
            "confidence": 1.0,
            "available": available,
        }

    if not base_url:
        return {
            "provider": fallback,
            "source": "fallback:no-kev",
            "confidence": None,
            "available": available,
        }

    criteria = {
        provider: PROVIDER_DESCRIPTIONS[provider]
        for provider in available
    }
    questions = {
        "provider": {
            "type": "choice",
            "instructions": (
                "Choose the coding worker more likely to implement this repository task "
                "safely and with a small, testable diff. Decide only among the supplied "
                "workers; repository rules and explicit labels are handled outside this model."
            ),
            "criteria": criteria,
        }
    }

    try:
        response = requester(
            base_url=base_url,
            api_key=api_key,
            model=model,
            state=_bounded_state(state),
            questions=questions,
            timeout=timeout,
        )
        answers = response.get("answers")
        if not isinstance(answers, Mapping):
            raise KevProtocolError("falta answers")
        answer = answers.get("provider")
        if not isinstance(answer, Mapping):
            raise KevProtocolError("falta answers.provider")

        choice = answer.get("choice")
        confidence = answer.get("confidence")
        if choice not in available:
            raise KevProtocolError("provider fuera de los disponibles")
        if not isinstance(confidence, (int, float)) or isinstance(confidence, bool):
            raise KevProtocolError("confidence inválida")
        confidence = float(confidence)
        if not 0.0 <= confidence <= 1.0:
            raise KevProtocolError("confidence fuera de rango")

        if confidence < min_confidence:
            return {
                "provider": fallback,
                "source": "fallback:low-confidence",
                "confidence": confidence,
                "kev_choice": choice,
                "available": available,
            }
        return {
            "provider": choice,
            "source": "kev",
            "confidence": confidence,
            "available": available,
        }
    except Exception as exc:  # Kev es una ayuda opcional; el autopilot debe seguir.
        return {
            "provider": fallback,
            "source": "fallback:error",
            "confidence": None,
            "error_type": type(exc).__name__,
            "available": available,
        }


def _read_state(path: str) -> Any:
    if path == "-":
        return json.load(sys.stdin)
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state-file", default="-", help="JSON de estado; '-' lee stdin")
    parser.add_argument("--label", action="append", default=[], help="Label GitHub; repetible")
    parser.add_argument(
        "--requested-provider",
        choices=("auto", "qwen", "gemini"),
        default="auto",
    )
    parser.add_argument("--has-qwen", action="store_true")
    parser.add_argument("--has-gemini", action="store_true")
    parser.add_argument("--base-url", default=os.getenv("KEV_BASE_URL"))
    parser.add_argument("--api-key", default=os.getenv("KEV_API_KEY"))
    parser.add_argument("--model", default=os.getenv("KEV_MODEL", DEFAULT_MODEL))
    parser.add_argument(
        "--timeout",
        type=float,
        default=float(os.getenv("KEV_TIMEOUT_SECONDS", DEFAULT_TIMEOUT_SECONDS)),
    )
    parser.add_argument(
        "--min-confidence",
        type=float,
        default=float(
            os.getenv("KEV_ROUTER_MIN_CONFIDENCE", DEFAULT_MIN_CONFIDENCE)
        ),
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    if not 0.0 <= args.min_confidence <= 1.0:
        raise SystemExit("--min-confidence debe estar entre 0 y 1")
    if args.timeout <= 0:
        raise SystemExit("--timeout debe ser positivo")

    result = route_provider(
        state=_read_state(args.state_file),
        labels=args.label,
        requested_provider=args.requested_provider,
        has_qwen=args.has_qwen,
        has_gemini=args.has_gemini,
        base_url=args.base_url,
        api_key=args.api_key,
        model=args.model,
        timeout=args.timeout,
        min_confidence=args.min_confidence,
    )
    json.dump(result, sys.stdout, ensure_ascii=False, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
