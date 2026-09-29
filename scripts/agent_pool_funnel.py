#!/usr/bin/env python3
"""Embudo real del pool de agentes: hasta dónde llega cada worker (#1636).

Sin esta medida no se puede decir si el nivel 3 avanza: el volumen de runs
verdes engaña, porque un worker que no reserva nada también termina en
`success`. Cada job `worker` de agent-pool.yml se clasifica por la fase más
avanzada que completó, a partir de la conclusión de sus pasos.

Uso:
    python3 scripts/agent_pool_funnel.py --runs 40            # consulta GitHub con gh
    python3 scripts/agent_pool_funnel.py --jobs-json jobs.json  # datos ya descargados
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import re
import subprocess
import sys
from typing import Any

# (fase, pasos de agent-worker.yml que la acreditan si alguno terminó en success)
FASES: list[tuple[str, tuple[str, ...]]] = [
    ("arranca", ("Materializar contexto del issue",)),
    # Termina en success también con files=[] (sin corte seguro): la reserva
    # es la que confirma que el plan era útil.
    # Termina en success también con files=[] (sin corte seguro): la reserva
    # es la que confirma que el plan era útil.
    ("plan_parseado", ("Validar plan y reservar rutas",)),
    # Solo se ejecuta con reserved == 'true': la reserva no chocó en #182.
    ("reserva", ("Afinar contexto y memoria por rutas",)),
    ("implementa", ("Implementar con Qwen", "Implementar con Gemini")),
    ("preflight", ("Validar diff y preflight",)),
    ("pr_draft", ("Publicar PR draft y lanzar CI canonica",)),
]
NOMBRES_FASE = [nombre for nombre, _ in FASES]
PASO_PLAN_DELEGADO = "Buscar plan delegado por el nivel 2"
PASOS_PLANIFICADOR = ("Plan Qwen", "Plan Gemini")
JOB_WORKER_RE = re.compile(r"^run \((?P<issue>\d+), (?P<provider>[^,]+), (?P<worker>[^)]+)\) / worker$")


def fase_alcanzada(job: dict[str, Any]) -> str | None:
    """Fase más avanzada completada por un job worker, o None si no arrancó."""

    exitos = {
        str(paso.get("name", ""))
        for paso in job.get("steps", []) or []
        if isinstance(paso, dict) and paso.get("conclusion") == "success"
    }
    alcanzada = None
    for nombre, pasos in FASES:
        if not exitos.intersection(pasos):
            break
        alcanzada = nombre
    # Un replan significa que la implementación salió del CLAIM y se descartó.
    replan = any(
        isinstance(paso, dict)
        and paso.get("name") == "Replanificar pool tras desvio de CLAIM"
        and paso.get("conclusion") == "success"
        for paso in job.get("steps", []) or []
    )
    if replan and alcanzada == "implementa":
        return "implementa_fuera_de_claim"
    return alcanzada


def _pasos_por_nombre(job: dict[str, Any]) -> dict[str, str]:
    """Conclusión de cada paso, por nombre (el último gana si hay repetidos)."""

    conclusiones: dict[str, str] = {}
    for paso in job.get("steps", []) or []:
        if isinstance(paso, dict) and paso.get("name"):
            conclusiones[str(paso["name"])] = str(paso.get("conclusion", ""))
    return conclusiones


def origen_plan(job: dict[str, Any]) -> str | None:
    """Origen del plan que ejecutó el worker: delegado, generado o None."""

    conclusiones = _pasos_por_nombre(job)
    planificado = [
        conclusion for paso, conclusion in conclusiones.items()
        if paso in PASOS_PLANIFICADOR
    ]
    if not planificado and PASO_PLAN_DELEGADO not in conclusiones:
        return None
    if any(conclusion != "skipped" for conclusion in planificado):
        return "generado"
    # Planificador omitido solo puede significar plan delegado si la búsqueda
    # del nivel 2 terminó bien; si no, el job no llegó a planificar de verdad.
    if conclusiones.get(PASO_PLAN_DELEGADO) == "success":
        return "delegado"
    return None


def embudo(jobs: list[dict[str, Any]]) -> dict[str, Any]:
    """Cuenta, para cada fase, cuántos workers llegaron al menos hasta ella."""

    alcanzadas: Counter[str] = Counter()
    por_worker: dict[str, Counter[str]] = defaultdict(Counter)
    total = 0
    for job in jobs:
        match = JOB_WORKER_RE.match(str(job.get("name", "")))
        if not match:
            continue
        total += 1
        fase = fase_alcanzada(job)
        alcanzadas[fase or "no_arranca"] += 1
        por_worker[match.group("worker")][fase or "no_arranca"] += 1

    def acumulado(conteo: Counter[str]) -> dict[str, int]:
        salida = {}
        for indice, nombre in enumerate(NOMBRES_FASE):
            llegan = sum(conteo[f] for f in NOMBRES_FASE[indice:])
            if indice <= NOMBRES_FASE.index("implementa"):
                llegan += conteo["implementa_fuera_de_claim"]
            salida[nombre] = llegan
        return salida

    acumulado_total = acumulado(alcanzadas)
    # Origen del plan: delegado por el nivel 2 vs generado por el pool (#1894).
    por_origen_contadores: dict[str, Counter[str]] = defaultdict(Counter)
    por_origen_workers: Counter[str] = Counter()
    for job in jobs:
        match = JOB_WORKER_RE.match(str(job.get("name", "")))
        if not match:
            continue
        origen = origen_plan(job)
        if origen is None:
            continue
        por_origen_workers[origen] += 1
        por_origen_contadores[origen][fase_alcanzada(job) or "no_arranca"] += 1
    por_origen = {
        origen: acumulado(por_origen_contadores[origen]) | {"workers": por_origen_workers[origen]}
        for origen in sorted(por_origen_workers)
    }
    # Tasas sobre el total de workers para distinguir capacidad de actividad real:
    # con 0 workers las tasas son 0.0 en vez de dividir por cero.
    tasas = {
        "reservation_rate": acumulado_total["reserva"] / total if total else 0.0,
        "implementation_rate": acumulado_total["implementa"] / total if total else 0.0,
        "pr_rate": acumulado_total["pr_draft"] / total if total else 0.0,
    }
    return {
        "workers": total,
        "embudo": acumulado_total,
        **tasas,
        "implementa_fuera_de_claim": alcanzadas["implementa_fuera_de_claim"],
        "por_origen": por_origen,
        "por_worker": {w: acumulado(c) | {"workers": sum(c.values())} for w, c in sorted(por_worker.items())},
    }


def tabla(resultado: dict[str, Any]) -> str:
    total = resultado["workers"] or 1
    lineas = ["| Fase | Workers | % |", "|---|---:|---:|"]
    for nombre in NOMBRES_FASE:
        n = resultado["embudo"][nombre]
        lineas.append(f"| {nombre} | {n} | {100 * n / total:.0f}% |")
    lineas.append(f"\nPR/worker: {resultado['pr_rate']:.0%}. "
                  f"Workers analizados: {resultado['workers']}. "
                  f"Implementaciones descartadas por salir del CLAIM: {resultado['implementa_fuera_de_claim']}.")
    for origen in sorted(resultado.get("por_origen", {})):
        datos = resultado["por_origen"][origen]
        lineas.append(f"Plan {origen}: {datos['workers']} workers, "
                      f"{datos['pr_draft']} PR ({100 * datos['pr_draft'] / (datos['workers'] or 1):.0f}%).")
    return "\n".join(lineas)


def _gh_json(ruta: str) -> Any:
    salida = subprocess.run(["gh", "api", ruta], check=True, capture_output=True, text=True)
    return json.loads(salida.stdout)


def descargar_jobs(repo: str, runs: int) -> list[dict[str, Any]]:
    datos = _gh_json(f"repos/{repo}/actions/workflows/agent-pool.yml/runs?per_page={runs}")
    jobs: list[dict[str, Any]] = []
    for run in datos.get("workflow_runs", []):
        jobs.extend(_gh_json(f"repos/{repo}/actions/runs/{run['id']}/jobs?per_page=100").get("jobs", []))
    return jobs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--repo", default="EspacioKoop/expediente-legado")
    parser.add_argument("--runs", type=int, default=40, help="últimos runs de agent-pool.yml")
    parser.add_argument("--jobs-json", type=Path, help="lista JSON de jobs ya descargada")
    parser.add_argument("--json", action="store_true", help="salida JSON en vez de tabla")
    args = parser.parse_args()

    if args.jobs_json:
        jobs = json.loads(args.jobs_json.read_text(encoding="utf-8"))
    else:
        jobs = descargar_jobs(args.repo, args.runs)
    resultado = embudo(jobs)
    if args.json:
        json.dump(resultado, sys.stdout, ensure_ascii=False, indent=2)
        print()
    else:
        print(tabla(resultado))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
