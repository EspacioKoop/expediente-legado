#!/usr/bin/env python3
"""Extrae y valida el AGENT_PLAN que devuelve el planificador del pool (#1881).

Sustituye al python inline de «Validar plan y reservar rutas». Dos motivos:

- Los modelos no respetan el formato al pie de la letra: envuelven los
  marcadores en Markdown (`**AGENT_PLAN_BEGIN**`), meten el JSON en un bloque
  ```json sin marcadores o lo truncan. La regex estricta descartaba planes
  válidos y el issue se reencolaba sin avanzar.
- La salida entraba por una variable de entorno; con más de 128 KB el paso ni
  arrancaba (`Argument list too long`). Aquí se lee siempre de fichero.

Las fuentes se prueban en orden y gana la primera que contenga un plan:
el JSON de `agent_delegated_plan.py`, el `stdout.log` de qwen-code-action
(array de eventos) o de run-gemini-cli (`{"response": ...}`), o texto plano.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
from typing import Any, Iterator

DEFAULT_MAX_FILES = 1
HARD_MAX_FILES = 12
MAX_GOAL = 180
# Un plan son 12 rutas y un objetivo: ningún plan real se acerca a esto.
MAX_OBJECT = 64 * 1024
PROTECTED_FILES = {"AGENTS.md", "QWEN.md", "GEMINI.md", "docs/agents-autonomos.md"}
PROTECTED_PREFIXES = (".github/", ".agent-")

# Salidas del proceso, estables para el workflow.
EXIT_OK = 0
EXIT_UNPARSEABLE = 3
EXIT_INVALID = 4

# El marcador puede llegar decorado: **AGENT_PLAN_BEGIN**, `AGENT_PLAN_BEGIN`,
# ### AGENT_PLAN_BEGIN… Basta con localizar la palabra y buscar el JSON detrás.
BEGIN_RE = re.compile(r"AGENT_PLAN_BEGIN", re.IGNORECASE)
END_RE = re.compile(r"AGENT_PLAN_END", re.IGNORECASE)
OBJECT_START_RE = re.compile(r'\{\s*["}]')
FENCE_RE = re.compile(r"```[ \t]*(?:json|JSON)?[ \t]*\n(.*?)```", re.S)
FILES_RE = re.compile(r'"files"\s*:\s*(\[[^\]]*\])', re.S)
GOAL_RE = re.compile(r'"goal"\s*:\s*"((?:[^"\\]|\\.)*)', re.S)


class PlanError(Exception):
    """Plan localizado pero inválido (rutas, tamaño)."""


def _objects_from(text: str, start: int = 0) -> Iterator[tuple[int, Any]]:
    """Objetos JSON decodificables que empiezan en un `{` desde `start`.

    Solo se intenta decodificar donde puede empezar un objeto JSON (`{"` o
    `{}`): las salidas enormes llenas de código con llaves se recorrían en
    tiempo cuadrático. Por lo mismo se decodifica sobre una ventana acotada:
    `JSONDecodeError` cuenta los saltos de línea desde el principio del texto.
    """
    decoder = json.JSONDecoder()
    match = OBJECT_START_RE.search(text, start)
    while match is not None:
        index = match.start()
        try:
            value, length = decoder.raw_decode(text[index : index + MAX_OBJECT])
        except json.JSONDecodeError:
            match = OBJECT_START_RE.search(text, index + 1)
            continue
        end = index + length
        yield index, value
        match = OBJECT_START_RE.search(text, end)


def _is_plan(value: Any) -> bool:
    return isinstance(value, dict) and isinstance(value.get("files"), list)


def _from_markers(text: str) -> dict[str, Any] | None:
    """Último plan tras un AGENT_PLAN_BEGIN, antes del AGENT_PLAN_END siguiente."""
    found = None
    for begin in BEGIN_RE.finditer(text):
        end = END_RE.search(text, begin.end())
        limit = end.start() if end else len(text)
        for position, value in _objects_from(text, begin.end()):
            if position >= limit:
                break
            if _is_plan(value):
                found = value
                break
    return found


def _from_fences(text: str) -> dict[str, Any] | None:
    found = None
    for match in FENCE_RE.finditer(text):
        for _, value in _objects_from(match.group(1)):
            if _is_plan(value):
                found = value
    return found


def _from_bare_objects(text: str) -> dict[str, Any] | None:
    found = None
    for _, value in _objects_from(text):
        if _is_plan(value):
            found = value
    return found


def _salvage(text: str) -> dict[str, Any] | None:
    """Rescata `files` cuando el JSON llega truncado (p. ej. un goal cortado).

    Solo si la lista en sí se decodifica: una ruta a medias no se inventa.
    """
    matches = list(FILES_RE.finditer(text))
    if not matches:
        return None
    try:
        files = json.loads(matches[-1].group(1))
    except json.JSONDecodeError:
        return None
    if not isinstance(files, list):
        return None
    # El goal suele ir detrás de files; si no, el último que aparezca.
    goal_match = GOAL_RE.search(text, matches[-1].start())
    if goal_match is None:
        goal_match = next(reversed(list(GOAL_RE.finditer(text))), None)
    goal = ""
    if goal_match is not None:
        try:
            goal = json.loads('"' + goal_match.group(1) + '"')
        except json.JSONDecodeError:
            goal = goal_match.group(1)
    return {"files": files, "goal": goal}


STRATEGIES = (
    ("marcadores", _from_markers),
    ("bloque-json", _from_fences),
    ("objeto-json", _from_bare_objects),
    ("rescate", _salvage),
)


def extract_plan(text: str) -> tuple[dict[str, Any], str] | None:
    """Devuelve (plan, estrategia) o None si el texto no contiene ningún plan."""
    if not text:
        return None
    for name, strategy in STRATEGIES:
        plan = strategy(text)
        if plan is not None:
            return plan, name
    return None


def _event_texts(events: list[Any]) -> Iterator[str]:
    """Textos del asistente en un array de eventos de qwen-code (stream JSON)."""
    for event in events:
        if not isinstance(event, dict) or event.get("type") != "assistant":
            continue
        message = event.get("message")
        content = message.get("content") if isinstance(message, dict) else None
        if isinstance(content, str):
            yield content
        elif isinstance(content, list):
            for part in content:
                if isinstance(part, dict) and part.get("type") == "text":
                    text = part.get("text")
                    if isinstance(text, str):
                        yield text


def source_texts(raw: str) -> list[str]:
    """Textos candidatos de una fuente, del más fiable al menos.

    Se prueba primero el último mensaje del asistente (donde debe estar el
    plan) y luego el resto: a veces el plan sale en un mensaje intermedio y el
    último es solo un resumen.
    """
    try:
        data = json.loads(raw)
    except (json.JSONDecodeError, ValueError):
        return [raw]
    if isinstance(data, dict):
        if data.get("found") is True and _is_plan(data.get("plan")):
            return [json.dumps(data["plan"], ensure_ascii=False)]
        if data.get("found") is False:
            return []
        response = data.get("response")
        if isinstance(response, str):
            return [response]
        return [raw]
    if isinstance(data, list):
        texts = list(_event_texts(data))
        return list(reversed(texts))
    return [raw]


def normalize(plan: dict[str, Any], *, max_files: int = DEFAULT_MAX_FILES) -> dict[str, Any]:
    """Valida rutas y aplica el presupuesto real del TaskPacket."""
    if not 1 <= int(max_files) <= HARD_MAX_FILES:
        raise PlanError("max_files fuera de límites")
    files = plan.get("files", [])
    if not isinstance(files, list) or len(files) > int(max_files):
        raise PlanError("plan excede max_files")
    clean: list[str] = []
    for item in files:
        if not isinstance(item, str):
            raise PlanError("ruta invalida")
        item = item.strip().replace("\\", "/")
        if (
            not item
            or item.startswith("/")
            or ".." in item.split("/")
            or any(c in item for c in "*?[]")
        ):
            raise PlanError("ruta invalida")
        if item.startswith(PROTECTED_PREFIXES) or item in PROTECTED_FILES:
            raise PlanError("ruta protegida")
        clean.append(item)
    return {
        "files": list(dict.fromkeys(clean)),
        "goal": str(plan.get("goal", ""))[:MAX_GOAL],
    }


def parse_sources(paths: list[Path]) -> tuple[dict[str, Any], str, Path] | None:
    for path in paths:
        try:
            raw = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for text in source_texts(raw):
            found = extract_plan(text)
            if found is not None:
                plan, strategy = found
                return plan, strategy, path
    return None


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--source",
        type=Path,
        action="append",
        default=[],
        help="fichero con la salida del planificador; repetible, gana el primero con plan",
    )
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--max-files", type=int, default=DEFAULT_MAX_FILES)
    args = parser.parse_args(argv)

    found = parse_sources(args.source)
    if found is None:
        print("plan no parseable", file=sys.stderr)
        return EXIT_UNPARSEABLE
    plan, strategy, path = found
    try:
        normalized = normalize(plan, max_files=args.max_files)
    except PlanError as exc:
        print(str(exc), file=sys.stderr)
        return EXIT_INVALID

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(normalized, ensure_ascii=False), encoding="utf-8")
    print(
        f"plan leído de {path} ({strategy}): {len(normalized['files'])} rutas",
        file=sys.stderr,
    )
    return EXIT_OK


if __name__ == "__main__":
    raise SystemExit(main())
