#!/usr/bin/env python3
"""Slots de fallback Qwen/OpenAI-compatible para el pool de agentes (#1685).

Antes cada slot `QWEN_FALLBACK_N_*` estaba copiado a mano en varios workflows;
añadir uno exigía tocar decenas de líneas. Aquí se descubren desde las
variables del repositorio (`toJSON(vars)`, que no son secretas) y se resuelve
el endpoint de cada worker. Las claves nunca pasan por este módulo: el pool
solo le dice qué números de slot tienen clave, y el worker toma la suya con
`secrets[format('QWEN_FALLBACK_{0}_API_KEY', n)]`.

Uso desde workflows:

    VARS_JSON='${{ toJSON(vars) }}' FALLBACK_KEYS="2 3" \\
        python3 scripts/agent_slots.py listar
    python3 scripts/agent_slots.py resolver --worker qwen-fallback-3
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


def claves_presentes(texto: str) -> set[int]:
    """Números de slot con clave, tal como los emite la tabla del pool ("2 3 7")."""

    return {int(t) for t in texto.split() if t.isdigit() and 1 <= int(t) <= MAX_FALLBACKS}


def slot_de_worker(worker: str) -> int | None:
    match = WORKER_RE.match(worker)
    if not match:
        return None
    n = int(match.group("n"))
    return n if n <= MAX_FALLBACKS else None


def fallbacks(variables: dict[str, Any], con_clave: set[int]) -> list[dict[str, Any]]:
    """Slots completos (clave + BASE_URL), ordenados por número.

    Un slot con URL pero sin clave se omite: configurar el endpoint antes de
    tener la cuenta no debe mandar trabajo a un worker que fallará.
    """

    salida = []
    for n in range(1, MAX_FALLBACKS + 1):
        url = str(variables.get(f"QWEN_FALLBACK_{n}_BASE_URL") or "").strip()
        if not url or n not in con_clave:
            continue
        salida.append(
            {
                "worker": f"qwen-fallback-{n}",
                "slot": n,
                "url": url,
                "model": str(variables.get(f"QWEN_FALLBACK_{n}_MODEL") or "").strip(),
            }
        )
    return salida


def resolver(
    variables: dict[str, Any], worker: str, con_clave: set[int], modelo_por_defecto: str = ""
) -> dict[str, Any] | None:
    """Endpoint de un worker de fallback, o el primer fallback con clave para `primera`."""

    disponibles = fallbacks(variables, con_clave)
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
    sub.add_parser("listar", help="workers de fallback utilizables, para el pool")
    r = sub.add_parser("resolver", help="endpoint de un worker (o `primera`)")
    r.add_argument("--worker", required=True)
    r.add_argument("--modelo-por-defecto", default="")
    args = parser.parse_args()

    variables = _variables()
    con_clave = claves_presentes(os.environ.get("FALLBACK_KEYS", ""))
    if args.orden == "listar":
        workers = [{"worker": s["worker"], "provider": "qwen"} for s in fallbacks(variables, con_clave)]
        json.dump(workers, sys.stdout)
        print()
        return 0
    resultado = resolver(variables, args.worker, con_clave, args.modelo_por_defecto)
    if resultado is None:
        print(f"{args.worker}: sin slot utilizable (falta BASE_URL o clave)", file=sys.stderr)
        return 3
    json.dump(resultado, sys.stdout)
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
