#!/usr/bin/env python3
"""Entregas reales del pool: PRs abiertas, fusionadas y cerradas (#1895).

El embudo operativo mide hasta dónde llega cada worker; este informe mide el
resultado final observable en GitHub a partir de las ramas publicadas por el
pool. Solo cuentan ramas con el patrón canónico agent/(qwen|gemini)-N-RUN.

Uso:
    python3 scripts/agent_pool_entregas.py --dias 7
    python3 scripts/agent_pool_entregas.py --prs-json prs.json --json
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import re
import subprocess
import sys
from typing import Any


PR_POOL_RE = re.compile(r"^agent/(qwen|gemini)-\d+-\d+$")
WORKER_RE = re.compile(
    r"Implementaci[oó]n autonoma mediante worker `(?P<worker>[A-Za-z0-9._-]+)`",
    re.IGNORECASE,
)
ESTADOS = ("OPEN", "MERGED", "CLOSED")


def es_pr_del_pool(pr: dict[str, Any]) -> bool:
    """True solo para PRs publicadas por ramas canónicas del pool."""

    return PR_POOL_RE.fullmatch(str(pr.get("headRefName", ""))) is not None


def worker_de(pr: dict[str, Any]) -> str:
    """Extrae el worker declarado en el cuerpo de la PR."""

    match = WORKER_RE.search(str(pr.get("body", "") or ""))
    return match.group("worker") if match else "desconocido"


def _fecha_utc(valor: Any) -> datetime | None:
    if not isinstance(valor, str) or not valor.strip():
        return None
    try:
        fecha = datetime.fromisoformat(valor.replace("Z", "+00:00"))
    except ValueError:
        return None
    if fecha.tzinfo is None:
        fecha = fecha.replace(tzinfo=timezone.utc)
    return fecha.astimezone(timezone.utc)


def resumen(
    prs: list[dict[str, Any]],
    desde: datetime | None = None,
) -> dict[str, Any]:
    """Resume estados y tasa de fusión de las PRs reales del pool."""

    if desde is not None:
        if desde.tzinfo is None:
            desde = desde.replace(tzinfo=timezone.utc)
        else:
            desde = desde.astimezone(timezone.utc)

    por_estado = {estado: 0 for estado in ESTADOS}
    por_worker: dict[str, dict[str, int]] = defaultdict(
        lambda: {"total": 0, "MERGED": 0}
    )
    total = 0

    for pr in prs:
        if not es_pr_del_pool(pr):
            continue
        creada = _fecha_utc(pr.get("createdAt"))
        if desde is not None and (creada is None or creada < desde):
            continue

        estado = str(pr.get("state", "")).upper()
        if estado not in por_estado:
            continue

        total += 1
        por_estado[estado] += 1
        worker = worker_de(pr)
        por_worker[worker]["total"] += 1
        if estado == "MERGED":
            por_worker[worker]["MERGED"] += 1

    fusionadas = por_estado["MERGED"]
    return {
        "total": total,
        "por_estado": por_estado,
        "tasa_fusion": fusionadas / total if total else 0.0,
        "por_worker": {worker: datos for worker, datos in sorted(por_worker.items())},
    }


def tabla(resultado: dict[str, Any]) -> str:
    """Renderiza una tabla Markdown compacta por worker."""

    lineas = [
        "| Worker | PRs | Fusionadas |",
        "|---|---:|---:|",
    ]
    for worker, datos in resultado["por_worker"].items():
        lineas.append(f"| {worker} | {datos['total']} | {datos['MERGED']} |")

    total = int(resultado["total"])
    fusionadas = int(resultado["por_estado"]["MERGED"])
    tasa = float(resultado["tasa_fusion"])
    lineas.append("")
    lineas.append(f"Total: {total} PRs, {fusionadas} fusionadas ({tasa:.0%}).")
    return "\n".join(lineas)


def descargar_prs(repo: str) -> list[dict[str, Any]]:
    """Consulta las PRs candidatas mediante gh sin interpretar el cuerpo."""

    comando = [
        "gh",
        "pr",
        "list",
        "--repo",
        repo,
        "--state",
        "all",
        "--search",
        "head:agent/",
        "--limit",
        "200",
        "--json",
        "number,headRefName,state,body,createdAt,mergedAt",
    ]
    salida = subprocess.run(comando, check=True, capture_output=True, text=True)
    datos = json.loads(salida.stdout)
    if not isinstance(datos, list):
        raise ValueError("gh pr list no devolvió una lista")
    return datos


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--repo", default="EspacioKoop/expediente-legado")
    parser.add_argument("--prs-json", type=Path, help="lista JSON de PRs ya descargada")
    parser.add_argument("--dias", type=int, help="limitar a PRs creadas en los últimos N días")
    parser.add_argument("--json", action="store_true", help="salida JSON en vez de tabla")
    args = parser.parse_args(argv)

    if args.dias is not None and args.dias < 0:
        parser.error("--dias no puede ser negativo")

    if args.prs_json:
        datos = json.loads(args.prs_json.read_text(encoding="utf-8"))
        if not isinstance(datos, list):
            raise ValueError("--prs-json debe contener una lista")
        prs = datos
    else:
        prs = descargar_prs(args.repo)

    desde = None
    if args.dias is not None:
        desde = datetime.now(timezone.utc) - timedelta(days=args.dias)

    resultado = resumen(prs, desde)
    if args.json:
        json.dump(resultado, sys.stdout, ensure_ascii=False, indent=2)
        print()
    else:
        print(tabla(resultado))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
