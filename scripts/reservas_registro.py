#!/usr/bin/env python3
"""Capa única de lectura del registro de reservas #182 (#1662).

El parser canónico es `gestionar_reservas.reconstruir_reservas`: resuelve
CLAIM, HEARTBEAT, PR_READY y RELEASE por rama. Este módulo no vuelve a
parsear: responde las preguntas que hasta ahora cada workflow contestaba con
su propio Python inline (qué reserva sigue vigente, si dos rutas se solapan y
con qué reservas anteriores choca un CLAIM).

CLI para workflows:

    python3 scripts/reservas_registro.py conflictos \\
        --comments comentarios.json --claim-id 123 --issue 45 --branch agent/x

Los comentarios son los de la API REST de #182 (`id`, `created_at`, `body`).
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import sys
from typing import Any

import gestionar_reservas as registro


@dataclass(frozen=True)
class ReservaVigente:
    reserva: registro.Reserva
    claim_id: int

    @property
    def rutas(self) -> list[str]:
        return [ruta for ruta in self.reserva.files.split(",") if ruta]


def _ids_de_claim(comentarios: list[dict[str, Any]]) -> dict[tuple[int, str], int]:
    """ID del comentario que fijó cada reserva (el último CLAIM por issue+rama gana)."""

    ids: dict[tuple[int, str], int] = {}
    for comentario in sorted(comentarios, key=lambda c: (c["created_at"], int(c.get("id", 0)))):
        for tipo, match in registro.eventos_de_comentario(comentario.get("body") or ""):
            if tipo == "claim":
                ids[(int(match.group("issue")), match.group("branch"))] = int(comentario.get("id", 0))
    return ids


def vigente(reserva: registro.Reserva, ahora: datetime) -> bool:
    """Misma regla que el barrido de reservas.yml, sin esperar a que publique RELEASE.

    Una PR asociada mantiene la reserva sin reloj; con lease, caduca a las N
    horas de la última actividad; sin lease (legacy) se mantiene hasta su
    RELEASE, que es la opción conservadora.
    """

    if reserva.released:
        return False
    if reserva.pr is not None or reserva.lease_hours is None:
        return True
    return ahora < reserva.last_activity + timedelta(hours=reserva.lease_hours)


def vigentes(comentarios: list[dict[str, Any]], ahora: datetime) -> list[ReservaVigente]:
    ids = _ids_de_claim(comentarios)
    return sorted(
        (
            ReservaVigente(reserva, ids.get(clave, 0))
            for clave, reserva in registro.reconstruir_reservas(comentarios).items()
            if vigente(reserva, ahora)
        ),
        key=lambda r: r.claim_id,
    )


def solapan(ruta_a: str, ruta_b: str) -> bool:
    """Misma ruta, o una contiene a la otra como directorio."""

    a = ruta_a.strip().rstrip("/")
    b = ruta_b.strip().rstrip("/")
    if not a or not b:
        return False
    return a == b or a.startswith(b + "/") or b.startswith(a + "/")


def conflictos(
    comentarios: list[dict[str, Any]],
    *,
    claim_id: int,
    issue: int,
    branch: str,
    ahora: datetime,
) -> dict[str, Any]:
    """Reservas vigentes anteriores a `claim_id` cuyas rutas solapan con él.

    En #182 gana la reserva anterior; los IDs de comentario son crecientes, así
    que «anterior» es ID menor. Una reserva de la misma rama no choca consigo.
    """

    activas = vigentes(comentarios, ahora)
    mia = next(
        (r for r in activas if r.claim_id == claim_id and r.reserva.issue == issue and r.reserva.branch == branch),
        None,
    )
    if mia is None:
        return {"mine_found": False, "conflicts": []}
    choques = [
        {
            "issue": otra.reserva.issue,
            "branch": otra.reserva.branch,
            "agent": otra.reserva.agent,
            "claim_id": otra.claim_id,
            "paths": sorted({b for a in mia.rutas for b in otra.rutas if solapan(a, b)}),
        }
        for otra in activas
        if otra.claim_id < claim_id
        and otra.reserva.branch != branch
        and any(solapan(a, b) for a in mia.rutas for b in otra.rutas)
    ]
    return {"mine_found": True, "conflicts": choques}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="orden", required=True)
    c = sub.add_parser("conflictos", help="choques de un CLAIM recién publicado")
    c.add_argument("--comments", type=Path, required=True)
    c.add_argument("--claim-id", type=int, required=True)
    c.add_argument("--issue", type=int, required=True)
    c.add_argument("--branch", required=True)
    c.add_argument("--now", help="ISO-8601; por defecto, ahora")
    args = parser.parse_args()

    comentarios = json.loads(args.comments.read_text(encoding="utf-8"))
    ahora = registro.parse_fecha(args.now) if args.now else datetime.now(timezone.utc)
    resultado = conflictos(
        comentarios, claim_id=args.claim_id, issue=args.issue, branch=args.branch, ahora=ahora
    )
    json.dump(resultado, sys.stdout, ensure_ascii=False)
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
