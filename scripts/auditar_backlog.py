#!/usr/bin/env python3
"""Auditor de higiene del backlog de GitHub (#2310).

No muta issues. Resume señales de acumulación y puede devolver código 2 cuando
hay violaciones duras: WIP técnico por encima del límite o issues abiertos
marcados como duplicado/sustituido.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
from typing import Any
from urllib.error import HTTPError
from urllib.request import Request, urlopen


GATES_HUMANOS = {9, 113, 398, 399, 431}
LIMITE_WIP = 15
LABEL_VALIDACION = "estado:validacion-humana"
LABEL_BLOQUEADO = "estado:bloqueado"
LABEL_PARCIAL = "estado:parcial"
LABEL_DUPLICADO = "duplicado-o-sustituido"
PRIORIDADES_ACTIVAS = {"prioridad:P0", "prioridad:P1"}


def _labels(issue: dict[str, Any]) -> set[str]:
    return {
        str(label.get("name", ""))
        for label in issue.get("labels", [])
        if isinstance(label, dict)
    }


def _es_issue(issue: dict[str, Any]) -> bool:
    return "pull_request" not in issue


def _es_wip_activo(numero: int, labels: set[str]) -> bool:
    if numero in GATES_HUMANOS:
        return False
    if LABEL_VALIDACION in labels or LABEL_BLOQUEADO in labels:
        return False
    return bool(
        labels.intersection(PRIORIDADES_ACTIVAS)
        or LABEL_PARCIAL in labels
        or any(label.startswith("agent:") for label in labels)
        or "jules" in labels
    )


def analizar_issues(issues: list[dict[str, Any]]) -> dict[str, Any]:
    abiertos = [issue for issue in issues if _es_issue(issue)]
    wip: list[dict[str, Any]] = []
    validacion_fuera_gate: list[dict[str, Any]] = []
    duplicados: list[dict[str, Any]] = []
    parciales_sin_corte: list[dict[str, Any]] = []
    bloqueados_sin_condicion: list[dict[str, Any]] = []

    for issue in abiertos:
        numero = int(issue["number"])
        labels = _labels(issue)
        body = str(issue.get("body") or "")
        body_lower = body.lower()

        if _es_wip_activo(numero, labels):
            wip.append(issue)

        if LABEL_VALIDACION in labels and numero not in GATES_HUMANOS:
            validacion_fuera_gate.append(issue)

        if LABEL_DUPLICADO in labels:
            duplicados.append(issue)

        if LABEL_PARCIAL in labels and "siguiente corte" not in body_lower:
            parciales_sin_corte.append(issue)

        if LABEL_BLOQUEADO in labels:
            marcas = ("desbloque", "depende", "dependencia", "bloqueo")
            if not any(marca in body_lower for marca in marcas):
                bloqueados_sin_condicion.append(issue)

    return {
        "open_count": len(abiertos),
        "wip": wip,
        "wip_count": len(wip),
        "human_candidates": validacion_fuera_gate,
        "human_candidates_count": len(validacion_fuera_gate),
        "duplicates": duplicados,
        "duplicates_count": len(duplicados),
        "partial_without_next_cut": parciales_sin_corte,
        "blocked_without_condition": bloqueados_sin_condicion,
        "hard_alert": len(wip) > LIMITE_WIP or bool(duplicados),
    }


def _fila(issue: dict[str, Any]) -> str:
    return f"- #{issue['number']} — {issue.get('title', '')}"


def render_markdown(resultado: dict[str, Any]) -> str:
    lineas = [
        "# Auditoría de backlog",
        "",
        f"- Issues abiertos: **{resultado['open_count']}**",
        f"- WIP técnico ejecutable: **{resultado['wip_count']} / {LIMITE_WIP}**",
        (
            "- Features con `estado:validacion-humana` fuera de gates canónicos: "
            f"**{resultado['human_candidates_count']}**"
        ),
        f"- `duplicado-o-sustituido` aún abiertos: **{resultado['duplicates_count']}**",
        "",
    ]

    secciones = [
        ("WIP técnico", resultado["wip"]),
        ("Validación humana fuera de gates", resultado["human_candidates"]),
        ("Duplicados/sustituidos abiertos", resultado["duplicates"]),
        ("Parciales sin «Siguiente corte»", resultado["partial_without_next_cut"]),
        ("Bloqueados sin condición explícita", resultado["blocked_without_condition"]),
    ]
    for titulo, items in secciones:
        lineas.extend([f"## {titulo}", ""])
        if not items:
            lineas.append("- Ninguno.")
        else:
            for issue in items[:30]:
                lineas.append(_fila(issue))
            if len(items) > 30:
                lineas.append(f"- … y {len(items) - 30} más.")
        lineas.append("")

    if resultado["hard_alert"]:
        lineas.extend(
            [
                "## Acción requerida",
                "",
                "Reducir WIP/cerrar duplicados antes de preparar más trabajo.",
                "",
            ]
        )
    return "\n".join(lineas)


def _leer_api(repo: str, token: str) -> list[dict[str, Any]]:
    pagina = 1
    issues: list[dict[str, Any]] = []
    while True:
        url = f"https://api.github.com/repos/{repo}/issues?state=open&per_page=100&page={pagina}"
        request = Request(
            url,
            headers={
                "Accept": "application/vnd.github+json",
                "Authorization": f"Bearer {token}",
                "X-GitHub-Api-Version": "2022-11-28",
                "User-Agent": "expediente-legado-backlog-audit",
            },
        )
        try:
            with urlopen(request, timeout=30) as response:
                lote = json.load(response)
        except HTTPError as exc:
            raise SystemExit(f"GitHub API {exc.code}: {exc.reason}") from exc
        if not lote:
            break
        issues.extend(lote)
        if len(lote) < 100:
            break
        pagina += 1
    return issues


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY", ""))
    parser.add_argument("--json-in", type=Path)
    parser.add_argument("--markdown-out", type=Path)
    parser.add_argument("--fail-on-hard", action="store_true")
    args = parser.parse_args(argv)

    if args.json_in:
        issues = json.loads(args.json_in.read_text(encoding="utf-8"))
    else:
        token = os.environ.get("GITHUB_TOKEN", "")
        if not args.repo or not token:
            parser.error("--repo/GITHUB_REPOSITORY y GITHUB_TOKEN son obligatorios sin --json-in")
        issues = _leer_api(args.repo, token)

    resultado = analizar_issues(issues)
    markdown = render_markdown(resultado)
    print(markdown)
    if args.markdown_out:
        args.markdown_out.write_text(markdown + "\n", encoding="utf-8")

    if args.fail_on_hard and resultado["hard_alert"]:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
