#!/usr/bin/env python3
"""Inventario de workers del pool de agentes: modelos, proveedores y tiers (#1685).

Un worker del pool es un motor (`qwen`: CLI OpenAI-compatible; `gemini`: CLI
nativa) apuntando a un proveedor y un modelo. Los slots `qwen-fallback-N`
admiten cualquier proveedor OpenAI-compatible (NVIDIA, OpenRouter, Gemini por
su endpoint OpenAI, DeepSeek…). Todo se describe con variables del
repositorio (`toJSON(vars)`, no secretas); las claves nunca pasan por aquí:
solo el *nombre* del secret, restringido a una lista cerrada.

Variables por slot `N` (1..MAX_FALLBACKS):

- `QWEN_FALLBACK_N_BASE_URL`, `QWEN_FALLBACK_N_MODEL`: endpoint y modelo.
- `QWEN_FALLBACK_N_TIER`: entero >= 1 (1 por defecto). El dispatcher agota
  un tier antes de usar el siguiente.
- `QWEN_FALLBACK_N_KEY_FROM`: reutiliza una clave existente en vez de pedir
  `QWEN_FALLBACK_N_API_KEY`: otro slot (`2`) o un proveedor base (`qwen`,
  `gemini`). Así se añaden modelos sin duplicar secretos.
- `QWEN_FALLBACK_N_MAX_TASK_BYTES`: presupuesto máximo aproximado de entrada
  para ese worker. `0` o ausente significa sin límite explícito.

Los workers base admiten `QWEN_PRIMARY_MAX_TASK_BYTES` y
`GEMINI_MAX_TASK_BYTES` con la misma semántica. Tiers de los workers base:
`QWEN_PRIMARY_TIER` y `GEMINI_TIER`.

Entorno de la CLI: `VARS_JSON`; `FALLBACK_KEYS` (slots con clave utilizable,
"2 3"); `BASE_KEYS` (proveedores base con clave, "qwen gemini");
`OMNIROUTE` (`true` si qwen-primary puede ir por OmniRoute).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from typing import Any

# Debe coincidir con la tabla de claves de agent-pool.yml (lo fija un test).
MAX_FALLBACKS = 12
WORKER_RE = re.compile(r"^qwen-fallback-(?P<n>[1-9]\d*)$")
SECRET_SLOT_RE = re.compile(r"^QWEN_FALLBACK_(?P<n>[1-9]\d*)_API_KEY$")
# Únicos orígenes de clave que puede nombrar una variable: nunca un secret
# arbitrario (OmniRoute, Kev, Tailscale…) enviado a una URL cualquiera.
SECRETOS_BASE = {"qwen": "QWEN_API_KEY", "gemini": "GEMINI_API_KEY"}
TIER_BASE = {"qwen-primary": "QWEN_PRIMARY_TIER", "gemini": "GEMINI_TIER"}
MAX_TASK_BYTES_BASE = {
    "qwen-primary": "QWEN_PRIMARY_MAX_TASK_BYTES",
    "gemini": "GEMINI_MAX_TASK_BYTES",
}


def claves_presentes(texto: str) -> set[int]:
    """Números de slot con clave, tal como los emite la tabla del pool ("2 3 7")."""

    return {int(t) for t in texto.split() if t.isdigit() and 1 <= int(t) <= MAX_FALLBACKS}


def slot_de_worker(worker: str) -> int | None:
    match = WORKER_RE.match(worker)
    if not match:
        return None
    n = int(match.group("n"))
    return n if n <= MAX_FALLBACKS else None


def _entero_positivo(crudo: Any) -> int:
    texto = str(crudo or "").strip()
    return int(texto) if texto.isdigit() and int(texto) >= 1 else 1


def _entero_no_negativo(crudo: Any) -> int:
    texto = str(crudo or "").strip()
    return int(texto) if texto.isdigit() else 0


def tier_de(variables: dict[str, Any], n: int) -> int:
    """`QWEN_FALLBACK_N_TIER` (entero >= 1); 1 si falta o no es válido."""

    return _entero_positivo(variables.get(f"QWEN_FALLBACK_{n}_TIER"))


def max_task_bytes_de_worker(variables: dict[str, Any], worker: str) -> int:
    """Presupuesto de entrada del worker; 0 significa sin límite explícito."""

    n = slot_de_worker(worker)
    if n is not None:
        return _entero_no_negativo(
            variables.get(f"QWEN_FALLBACK_{n}_MAX_TASK_BYTES")
        )
    return _entero_no_negativo(variables.get(MAX_TASK_BYTES_BASE.get(worker, "")))


def tier_de_worker(variables: dict[str, Any], worker: str) -> int:
    n = slot_de_worker(worker)
    if n is not None:
        return tier_de(variables, n)
    return _entero_positivo(variables.get(TIER_BASE.get(worker, "")))


def secreto_de(variables: dict[str, Any], n: int) -> str:
    """Nombre del secret que usa el slot `n`; "" si `KEY_FROM` no es válido."""

    origen = str(variables.get(f"QWEN_FALLBACK_{n}_KEY_FROM") or "").strip().lower()
    if not origen:
        return f"QWEN_FALLBACK_{n}_API_KEY"
    if origen.isdigit() and 1 <= int(origen) <= MAX_FALLBACKS:
        return f"QWEN_FALLBACK_{int(origen)}_API_KEY"
    return SECRETOS_BASE.get(origen, "")


def _clave_disponible(secreto: str, con_clave: set[int], base: set[str]) -> bool:
    match = SECRET_SLOT_RE.match(secreto)
    if match:
        return int(match.group("n")) in con_clave
    return any(SECRETOS_BASE.get(p) == secreto for p in base)


def fallbacks(
    variables: dict[str, Any], con_clave: set[int], base: set[str] | frozenset[str] = frozenset()
) -> list[dict[str, Any]]:
    """Slots utilizables (BASE_URL + clave propia o heredada), por tier y número.

    Un slot con URL pero sin clave se omite: configurar el endpoint antes de
    tener la cuenta no debe mandar trabajo a un worker que fallará. Un slot que
    figura en `con_clave` se da por utilizable (así lo pasa el pool al worker).
    """

    salida = []
    for n in range(1, MAX_FALLBACKS + 1):
        url = str(variables.get(f"QWEN_FALLBACK_{n}_BASE_URL") or "").strip()
        secreto = secreto_de(variables, n)
        if not url or not secreto:
            continue
        if n not in con_clave and not _clave_disponible(secreto, con_clave, set(base)):
            continue
        salida.append(
            {
                "worker": f"qwen-fallback-{n}",
                "slot": n,
                "url": url,
                "model": str(variables.get(f"QWEN_FALLBACK_{n}_MODEL") or "").strip(),
                "tier": tier_de(variables, n),
                "max_task_bytes": max_task_bytes_de_worker(
                    variables, f"qwen-fallback-{n}"
                ),
                "secret": secreto,
            }
        )
    # `primera` y la cascada de qwen-primary agotan un tier antes de bajar.
    return sorted(salida, key=lambda s: (s["tier"], s["slot"]))


def inventario(
    variables: dict[str, Any], con_clave: set[int], base: set[str], omniroute: bool = False
) -> list[dict[str, Any]]:
    """Todos los workers utilizables del pool, con su tier."""

    workers = []
    if "qwen" in base or omniroute:
        workers.append({"worker": "qwen-primary", "provider": "qwen"})
    if "gemini" in base:
        workers.append({"worker": "gemini", "provider": "gemini"})
    workers += [
        {
            "worker": s["worker"],
            "provider": "qwen",
            "max_task_bytes": s["max_task_bytes"],
        }
        for s in fallbacks(variables, con_clave, base)
    ]
    return [
        {
            **w,
            "tier": tier_de_worker(variables, w["worker"]),
            "max_task_bytes": w.get(
                "max_task_bytes", max_task_bytes_de_worker(variables, w["worker"])
            ),
        }
        for w in workers
    ]


def resolver(
    variables: dict[str, Any],
    worker: str,
    con_clave: set[int],
    modelo_por_defecto: str = "",
    base: set[str] | frozenset[str] = frozenset(),
) -> dict[str, Any] | None:
    """Endpoint de un worker de fallback, o el primer fallback utilizable para `primera`."""

    disponibles = fallbacks(variables, con_clave, base)
    if worker == "primera":
        elegido = disponibles[0] if disponibles else None
    else:
        n = slot_de_worker(worker)
        elegido = next((s for s in disponibles if s["slot"] == n), None)
    if elegido is None:
        return None
    return {**elegido, "model": elegido["model"] or modelo_por_defecto}


def _variables() -> dict[str, Any]:
    crudo = os.environ.get("VARS_JSON") or "{}"
    datos = json.loads(crudo)
    return datos if isinstance(datos, dict) else {}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="orden", required=True)
    sub.add_parser("workers", help="inventario completo de workers utilizables, con tier")
    sub.add_parser("usables", help="números de slot de fallback utilizables (para el worker)")
    sub.add_parser("listar", help="solo los fallbacks utilizables")
    r = sub.add_parser("resolver", help="endpoint de un worker (o `primera`)")
    r.add_argument("--worker", required=True)
    r.add_argument("--modelo-por-defecto", default="")
    s = sub.add_parser("secreto", help="nombre del secret de un worker de fallback")
    s.add_argument("--worker", required=True)
    args = parser.parse_args()

    variables = _variables()
    con_clave = claves_presentes(os.environ.get("FALLBACK_KEYS", ""))
    base = {p for p in os.environ.get("BASE_KEYS", "").split() if p in SECRETOS_BASE}
    omniroute = os.environ.get("OMNIROUTE", "") == "true"

    if args.orden == "workers":
        resultado: Any = inventario(variables, con_clave, base, omniroute)
    elif args.orden == "usables":
        print(" ".join(str(s["slot"]) for s in sorted(fallbacks(variables, con_clave, base), key=lambda s: s["slot"])))
        return 0
    elif args.orden == "listar":
        resultado = [
            {"worker": s["worker"], "provider": "qwen", "tier": s["tier"]}
            for s in fallbacks(variables, con_clave, base)
        ]
    elif args.orden == "secreto":
        n = slot_de_worker(args.worker)
        if n is None or not secreto_de(variables, n):
            print(f"{args.worker}: sin secret válido", file=sys.stderr)
            return 3
        print(secreto_de(variables, n))
        return 0
    else:
        resultado = resolver(variables, args.worker, con_clave, args.modelo_por_defecto, base)
        if resultado is None:
            print(f"{args.worker}: sin slot utilizable (falta BASE_URL o clave)", file=sys.stderr)
            return 3
    json.dump(resultado, sys.stdout)
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
