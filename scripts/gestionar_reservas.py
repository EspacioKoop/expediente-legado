#!/usr/bin/env python3
"""Gestiona leases del registro de reservas #182 sin depender de agentes."""

from __future__ import annotations

import argparse
import json
import os
import re
import time
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Callable
from urllib.error import HTTPError
from urllib.request import Request, urlopen

REGISTRO_ISSUE = int(os.environ.get("REGISTRO_RESERVAS_ISSUE", "182"))
API_URL = os.environ.get("GITHUB_API_URL", "https://api.github.com").rstrip("/")
REPO = os.environ.get("GITHUB_REPOSITORY", "")
TOKEN = os.environ.get("GITHUB_TOKEN", "")

REINTENTOS_MAX = int(os.environ.get("RESERVAS_REINTENTOS", "5"))
ESPERA_MAX_SEGUNDOS = float(os.environ.get("RESERVAS_ESPERA_MAX", "60"))
CODIGOS_TRANSITORIOS = frozenset({429, 500, 502, 503, 504})

CLAIM_RE = re.compile(
    r"^CLAIM issue=#(?P<issue>\d+) agent=(?P<agent>\S+) "
    r"branch=(?P<branch>\S+) files=(?P<files>\S+) goal=(?P<goal>.+)$"
)
HEARTBEAT_RE = re.compile(r"^HEARTBEAT issue=#(?P<issue>\d+) branch=(?P<branch>\S+)(?:\s|$)")
PR_READY_RE = re.compile(r"^PR_READY issue=#(?P<issue>\d+) pr=#(?P<pr>\d+)(?:\s|$)")
RELEASE_RE = re.compile(r"^RELEASE issue=#(?P<issue>\d+)(?P<rest>.*)$")
LEASE_RE = re.compile(r"\s+lease=(?P<hours>\d+)h\s*$")
BRANCH_RE = re.compile(r"(?:^|\s)branch=(?P<branch>\S+)")


@dataclass
class Reserva:
    issue: int
    agent: str
    branch: str
    files: str
    goal: str
    claimed_at: datetime
    last_activity: datetime
    lease_hours: int | None
    pr: int | None = None
    released: bool = False


def parse_fecha(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(timezone.utc)


def eventos_de_comentario(body: str) -> list[tuple[str, re.Match[str]]]:
    eventos: list[tuple[str, re.Match[str]]] = []
    for raw in body.splitlines():
        line = raw.strip()
        for nombre, patron in (
            ("claim", CLAIM_RE),
            ("heartbeat", HEARTBEAT_RE),
            ("pr_ready", PR_READY_RE),
            ("release", RELEASE_RE),
        ):
            match = patron.match(line)
            if match:
                eventos.append((nombre, match))
                break
    return eventos


def reconstruir_reservas(comentarios: list[dict]) -> dict[tuple[int, str], Reserva]:
    reservas: dict[tuple[int, str], Reserva] = {}
    for comentario in sorted(comentarios, key=lambda item: item["created_at"]):
        momento = parse_fecha(comentario["created_at"])
        for tipo, match in eventos_de_comentario(comentario.get("body") or ""):
            if tipo == "claim":
                issue = int(match.group("issue"))
                branch = match.group("branch")
                goal = match.group("goal")
                lease_match = LEASE_RE.search(goal)
                lease_hours = int(lease_match.group("hours")) if lease_match else None
                if lease_match:
                    goal = goal[: lease_match.start()].rstrip()
                reservas[(issue, branch)] = Reserva(
                    issue=issue,
                    agent=match.group("agent"),
                    branch=branch,
                    files=match.group("files"),
                    goal=goal,
                    claimed_at=momento,
                    last_activity=momento,
                    lease_hours=lease_hours,
                )
            elif tipo == "heartbeat":
                key = (int(match.group("issue")), match.group("branch"))
                reserva = reservas.get(key)
                if reserva and not reserva.released:
                    reserva.last_activity = momento
            elif tipo == "pr_ready":
                issue = int(match.group("issue"))
                candidatas = [
                    reserva
                    for reserva in reservas.values()
                    if reserva.issue == issue and not reserva.released
                ]
                if candidatas:
                    max(candidatas, key=lambda reserva: reserva.claimed_at).pr = int(match.group("pr"))
            elif tipo == "release":
                issue = int(match.group("issue"))
                branch_match = BRANCH_RE.search(match.group("rest") or "")
                branch = branch_match.group("branch") if branch_match else None
                for reserva in reservas.values():
                    if reserva.issue != issue or reserva.released:
                        continue
                    if branch is None or reserva.branch == branch:
                        reserva.released = True
    return reservas


def planificar_barrido(
    reservas: dict[tuple[int, str], Reserva],
    ahora: datetime,
    obtener_pr: Callable[[int], dict],
    legacy_cutoff: datetime | None = None,
) -> list[tuple[Reserva, str, dict | None]]:
    acciones: list[tuple[Reserva, str, dict | None]] = []
    cache_pr: dict[int, dict] = {}
    for reserva in reservas.values():
        if reserva.released:
            continue

        if reserva.pr is not None:
            if reserva.pr not in cache_pr:
                try:
                    cache_pr[reserva.pr] = obtener_pr(reserva.pr)
                except RuntimeError as exc:
                    # Sin saber el estado del PR no se libera: se mantiene la reserva
                    # y se sigue planificando el resto en vez de abortar el barrido.
                    print(f"AVISO: no se pudo consultar el PR #{reserva.pr}: {exc}")
                    continue
            pr = cache_pr[reserva.pr]
            if pr.get("state") == "closed":
                motivo = "merge-detectado-automaticamente" if pr.get("merged_at") else "PR-cerrado-sin-integrar"
                acciones.append((reserva, motivo, pr))
            continue

        if reserva.lease_hours is not None:
            vence = reserva.last_activity + timedelta(hours=reserva.lease_hours)
            if ahora >= vence:
                acciones.append((reserva, "reserva-caducada", None))
            continue

        if legacy_cutoff and reserva.last_activity <= legacy_cutoff:
            acciones.append((reserva, "migracion-legacy-sin-trabajo-activo", None))

    return acciones


def headers() -> dict[str, str]:
    if not TOKEN:
        raise RuntimeError("GITHUB_TOKEN es obligatorio")
    return {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {TOKEN}",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "expediente-legado-reservas",
    }


class ErrorTransitorio(RuntimeError):
    """Fallo de API que merece reintento: rate limit secundario o error de servidor."""


def es_transitorio(code: int, detalle: str) -> bool:
    if code in CODIGOS_TRANSITORIOS:
        return True
    # GitHub devuelve 403 tanto para permisos como para el rate limit secundario.
    # Solo el segundo se reintenta; un 403 de permisos no mejora esperando.
    return code == 403 and "rate limit" in detalle.lower()


def espera_recomendada(cabeceras: dict[str, str], intento: int, ahora: float) -> float:
    """Segundos a esperar antes del siguiente intento (0-indexado)."""
    retry_after = cabeceras.get("Retry-After") or cabeceras.get("retry-after")
    if retry_after:
        try:
            return max(0.0, min(float(retry_after), ESPERA_MAX_SEGUNDOS))
        except ValueError:
            pass
    restantes = cabeceras.get("X-RateLimit-Remaining") or cabeceras.get("x-ratelimit-remaining")
    reset = cabeceras.get("X-RateLimit-Reset") or cabeceras.get("x-ratelimit-reset")
    if restantes == "0" and reset:
        try:
            return max(0.0, min(float(reset) - ahora, ESPERA_MAX_SEGUNDOS))
        except ValueError:
            pass
    return min(2.0**intento, ESPERA_MAX_SEGUNDOS)


def api_json(
    method: str,
    path: str,
    payload: dict | None = None,
    dormir: Callable[[float], None] = time.sleep,
) -> tuple[object, dict]:
    data = json.dumps(payload).encode() if payload is not None else None
    for intento in range(REINTENTOS_MAX):
        request = Request(f"{API_URL}{path}", data=data, headers=headers(), method=method)
        try:
            with urlopen(request, timeout=30) as response:
                raw = response.read()
                return (json.loads(raw) if raw else None), dict(response.headers.items())
        except HTTPError as exc:
            detalle = exc.read().decode("utf-8", errors="replace")
            cabeceras = dict(exc.headers.items()) if exc.headers else {}
            if not es_transitorio(exc.code, detalle) or intento == REINTENTOS_MAX - 1:
                error = RuntimeError(f"GitHub API {exc.code} en {path}: {detalle}")
                if es_transitorio(exc.code, detalle):
                    error = ErrorTransitorio(
                        f"GitHub API {exc.code} en {path} tras {REINTENTOS_MAX} intentos: {detalle}"
                    )
                raise error from exc
            espera = espera_recomendada(cabeceras, intento, time.time())
            print(
                f"AVISO: GitHub API {exc.code} en {path}; "
                f"reintento {intento + 1}/{REINTENTOS_MAX - 1} en {espera:.0f}s"
            )
            dormir(espera)
    raise AssertionError("inalcanzable")


def obtener_comentarios() -> list[dict]:
    if not REPO:
        raise RuntimeError("GITHUB_REPOSITORY es obligatorio")
    comentarios: list[dict] = []
    page = 1
    while True:
        payload, _ = api_json(
            "GET", f"/repos/{REPO}/issues/{REGISTRO_ISSUE}/comments?per_page=100&page={page}"
        )
        lote = list(payload or [])
        comentarios.extend(lote)
        if len(lote) < 100:
            return comentarios
        page += 1


def obtener_pr(numero: int) -> dict:
    payload, _ = api_json("GET", f"/repos/{REPO}/pulls/{numero}")
    return dict(payload or {})


def publicar_release(reserva: Reserva, motivo: str, pr: dict | None, dry_run: bool) -> None:
    partes = [f"RELEASE issue=#{reserva.issue}"]
    if pr:
        partes.append(f"pr=#{pr['number']}")
        if pr.get("merged_at") and pr.get("merge_commit_sha"):
            partes.append(f"merge={pr['merge_commit_sha']}")
    partes.append(f"motivo={motivo}")
    partes.append(f"branch={reserva.branch}")
    partes.append("auto=reservas.yml")
    body = " ".join(partes)
    print(body)
    if not dry_run:
        api_json("POST", f"/repos/{REPO}/issues/{REGISTRO_ISSUE}/comments", {"body": body})
        reserva.released = True


def liberar_por_pr(reservas: dict[tuple[int, str], Reserva], numero_pr: int, dry_run: bool) -> int:
    pr = obtener_pr(numero_pr)
    if pr.get("state") != "closed":
        return 0
    branch = ((pr.get("head") or {}).get("ref"))
    candidatas = [
        reserva
        for reserva in reservas.values()
        if not reserva.released and (reserva.pr == numero_pr or reserva.branch == branch)
    ]
    motivo = "merge-detectado-automaticamente" if pr.get("merged_at") else "PR-cerrado-sin-integrar"
    fallos = 0
    for reserva in candidatas:
        try:
            publicar_release(reserva, motivo, pr, dry_run)
        except RuntimeError as exc:
            # Un fallo por reserva no debe dejar sin liberar a las siguientes.
            fallos += 1
            print(f"ERROR: no se pudo liberar #{reserva.issue} ({reserva.branch}): {exc}")
    return fallos


def main() -> int:
    parser = argparse.ArgumentParser()
    grupo = parser.add_mutually_exclusive_group(required=True)
    grupo.add_argument("--pr", type=int, help="PR cerrada que debe liberar su reserva")
    grupo.add_argument("--sweep", action="store_true", help="barre leases y PRs ya cerradas")
    parser.add_argument("--legacy-cutoff", help="libera claims legacy anteriores a este ISO-8601")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    reservas = reconstruir_reservas(obtener_comentarios())
    if args.pr:
        return 1 if liberar_por_pr(reservas, args.pr, args.dry_run) else 0

    cutoff = parse_fecha(args.legacy_cutoff) if args.legacy_cutoff else None
    ahora = datetime.now(timezone.utc)
    acciones = planificar_barrido(reservas, ahora, obtener_pr, cutoff)
    fallos = 0
    for reserva, motivo, pr in acciones:
        try:
            publicar_release(reserva, motivo, pr, args.dry_run)
        except RuntimeError as exc:
            fallos += 1
            print(f"ERROR: no se pudo liberar #{reserva.issue} ({reserva.branch}): {exc}")
    if fallos:
        print(f"ERROR: {fallos} de {len(acciones)} liberaciones fallaron; el resto sí se publicó")
    return 1 if fallos else 0


if __name__ == "__main__":
    raise SystemExit(main())
