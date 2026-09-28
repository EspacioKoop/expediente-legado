#!/usr/bin/env python3
"""Rollover del registro de reservas cuando el issue activo se satura.

Mantiene la semántica probada de gestionar_reservas.py sin modificarla:
lee comentarios históricos + activos, reconstruye una sola línea temporal y
publica cualquier evento nuevo únicamente en el registro activo.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import gestionar_reservas as base


RAIZ = Path(__file__).resolve().parents[1]
CONFIG = RAIZ / ".github" / "reservas-registro.json"


def cargar_config(ruta: Path = CONFIG) -> tuple[int, list[int]]:
    datos = json.loads(ruta.read_text(encoding="utf-8"))
    activo = int(datos["active"])
    lectura = [int(valor) for valor in datos.get("read", [activo])]
    if activo not in lectura:
        lectura.append(activo)
    if len(set(lectura)) != len(lectura):
        raise ValueError("reservas-registro.json contiene issues duplicados")
    if activo <= 0 or any(numero <= 0 for numero in lectura):
        raise ValueError("los números de issue del registro deben ser positivos")
    return activo, lectura


def obtener_comentarios(registros: list[int]) -> list[dict]:
    if not base.REPO:
        raise RuntimeError("GITHUB_REPOSITORY es obligatorio")
    comentarios: list[dict] = []
    for registro in registros:
        pagina = 1
        while True:
            payload, _ = base.api_json(
                "GET",
                f"/repos/{base.REPO}/issues/{registro}/comments?per_page=100&page={pagina}",
            )
            lote = list(payload or [])
            comentarios.extend(lote)
            if len(lote) < 100:
                break
            pagina += 1
    return sorted(
        comentarios,
        key=lambda item: (item.get("created_at", ""), int(item.get("id", 0))),
    )


def reconstruir() -> tuple[int, dict]:
    activo, lectura = cargar_config()
    comentarios = obtener_comentarios(lectura)
    return activo, base.reconstruir_reservas(comentarios)


def ejecutar_gestion(
    *,
    numero_pr: int | None,
    barrer: bool,
    legacy_cutoff: str | None,
    dry_run: bool,
) -> int:
    activo, reservas = reconstruir()
    # La lectura puede abarcar registros antiguos, pero cualquier RELEASE nuevo
    # se publica solo en el issue activo.
    base.REGISTRO_ISSUE = activo
    ahora = datetime.now(timezone.utc)

    if numero_pr is not None:
        fallos = base.liberar_por_pr(reservas, numero_pr, dry_run)
        fallos += base.recuperar_prs_cerradas(reservas, ahora, dry_run)
        return 1 if fallos else 0

    if not barrer:
        raise ValueError("se requiere --pr o --sweep")
    cutoff = base.parse_fecha(legacy_cutoff) if legacy_cutoff else None
    acciones = base.planificar_barrido(
        reservas,
        ahora,
        base.obtener_pr,
        cutoff,
        pr_cerrada_de_rama=base.obtener_pr_cerrada_de_rama,
    )
    return 1 if base.publicar_acciones(acciones, dry_run) else 0


def main() -> int:
    parser = argparse.ArgumentParser()
    modo = parser.add_mutually_exclusive_group(required=True)
    modo.add_argument("--active", action="store_true")
    modo.add_argument("--comments-output", type=Path)
    modo.add_argument("--pr", type=int)
    modo.add_argument("--sweep", action="store_true")
    parser.add_argument("--legacy-cutoff")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    activo, lectura = cargar_config()
    if args.active:
        print(activo)
        return 0
    if args.comments_output is not None:
        comentarios = obtener_comentarios(lectura)
        args.comments_output.write_text(
            json.dumps(comentarios, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        return 0
    return ejecutar_gestion(
        numero_pr=args.pr,
        barrer=args.sweep,
        legacy_cutoff=args.legacy_cutoff,
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    raise SystemExit(main())
