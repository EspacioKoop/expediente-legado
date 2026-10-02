#!/usr/bin/env python3
"""Detecta y revierte cambios de un agente fuera de su CLAIM.

El plan ya ha sido saneado por agent-autopilot.yml. Este módulo añade una
segunda frontera, independiente del proveedor: ningún cambio fuera de
`files` puede sobrevivir hasta el commit/push.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import subprocess


IGNORED_EXACT = {
    ".agent-task.md",
    ".agent-plan.json",
    # Los genera el propio worker (context packer y reviewer); sin ellos aquí,
    # toda implementación salía «fuera del CLAIM» y se replanificaba (#1657).
    ".agent-context.md",
    ".agent-task-packet.json",
    ".agent-worker-prompt.md",
    ".agent-b2b-inbox.md",
    ".agent-review-input.md",
    ".agent-memory.json",
    ".agent-history.json",
    ".agent-platino-sha",
}
IGNORED_PREFIXES = (
    ".agent-platino/",
    ".agent-wiki/",
    ".gemini/",
    ".qwen/",
    "gemini-artifacts/",
    "qwen-artifacts/",
)
IGNORED_GLOBS = ("gha-creds-",)


def _git(root: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=root,
        check=check,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def _normalizar_ruta(valor: str) -> str:
    ruta = valor.strip().replace("\\", "/")
    partes = ruta.split("/")
    if not ruta or ruta.startswith("/") or ".." in partes:
        raise ValueError(f"ruta inválida en plan: {valor!r}")
    return ruta


def cargar_plan(ruta: Path) -> set[str]:
    datos = json.loads(ruta.read_text(encoding="utf-8"))
    archivos = datos.get("files")
    if not isinstance(archivos, list):
        raise ValueError("el plan no contiene files[]")
    salida: set[str] = set()
    for valor in archivos:
        if not isinstance(valor, str):
            raise ValueError("files[] contiene una ruta no textual")
        salida.add(_normalizar_ruta(valor))
    return salida


def _se_ignora(ruta: str) -> bool:
    if ruta in IGNORED_EXACT:
        return True
    # Auxiliares que el propio worker crea en la raíz (.agent-result.json en
    # #1894): un plan nunca puede reservar .agent-*, así que no son contenido
    # del repo ni motivo de replan. validate_diff los borra antes del commit.
    if "/" not in ruta and ruta.startswith(".agent-"):
        return True
    if any(ruta.startswith(prefijo) for prefijo in IGNORED_PREFIXES):
        return True
    nombre = Path(ruta).name
    return any(nombre.startswith(prefijo) for prefijo in IGNORED_GLOBS)


def rutas_cambiadas(root: Path) -> set[str]:
    tracked_raw = subprocess.check_output(
        ["git", "diff", "--name-only", "-z", "HEAD"],
        cwd=root,
    )
    untracked_raw = subprocess.check_output(
        ["git", "ls-files", "--others", "--exclude-standard", "-z"],
        cwd=root,
    )
    rutas: set[str] = set()
    for bloque in (tracked_raw, untracked_raw):
        for valor in bloque.decode("utf-8", "surrogateescape").split("\0"):
            if valor:
                rutas.add(valor.replace("\\", "/"))
    return {ruta for ruta in rutas if not _se_ignora(ruta)}


def _es_trackeada(root: Path, ruta: str) -> bool:
    proc = subprocess.run(
        ["git", "ls-files", "--error-unmatch", "--", ruta],
        cwd=root,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return proc.returncode == 0


def _ruta_segura(root: Path, ruta: str) -> Path:
    """Valida la ruta sin seguir el symlink final.

    Resolver el destino completo haría que un symlink no trackeado que apunte
    fuera del repo se considerase una fuga antes de poder eliminarlo. Sí se
    resuelve el directorio padre para impedir escapar mediante componentes
    intermedios que sean symlinks.
    """

    raiz = root.resolve()
    candidata = root / ruta
    padre = candidata.parent.resolve(strict=False)
    try:
        padre.relative_to(raiz)
    except ValueError as exc:
        raise ValueError(f"ruta fuera del repositorio: {ruta}") from exc
    return candidata


def _podar_padres_vacios(root: Path, destino: Path) -> None:
    raiz = root.resolve()
    padre = destino.parent
    while padre != raiz:
        try:
            padre.rmdir()
        except OSError:
            break
        padre = padre.parent


def restaurar_fuera_del_claim(root: Path, fuera: list[str]) -> None:
    for ruta in fuera:
        _ruta_segura(root, ruta)
        if _es_trackeada(root, ruta):
            _git(root, "restore", "--source=HEAD", "--staged", "--worktree", "--", ruta)
            continue
        destino = root / ruta
        if destino.is_symlink() or destino.is_file():
            destino.unlink(missing_ok=True)
            _podar_padres_vacios(root, destino)
        elif destino.is_dir():
            shutil.rmtree(destino)
            _podar_padres_vacios(root, destino)


def _es_borrador(root: Path, ruta: str) -> bool:
    """Fichero nuevo, sin versionar, suelto en la raíz: basura del modelo.

    Medido en #2106: 10 de 12 replans del pool se debieron a `agent_result.json`,
    `result.txt`, `_tmp_*.py`… que el modelo dejó en la raíz, no a rutas que la
    implementación necesitara. Ningún corte legítimo crea un fichero suelto en
    la raíz sin reservarlo, así que se borra sin replanificar. Un fichero nuevo
    en un subdirectorio, o uno versionado de la raíz, sigue siendo desvío.
    """

    return "/" not in ruta and not _es_trackeada(root, ruta)


def ejecutar(root: Path, plan: Path, *, restaurar: bool) -> dict[str, object]:
    permitidas = cargar_plan(plan)
    cambiadas = rutas_cambiadas(root)
    candidatas = sorted(cambiadas - permitidas)
    borradores = [ruta for ruta in candidatas if _es_borrador(root, ruta)]
    fuera = [ruta for ruta in candidatas if ruta not in borradores]
    dentro = sorted(cambiadas & permitidas)

    if restaurar and candidatas:
        restaurar_fuera_del_claim(root, candidatas)
        restantes = sorted(rutas_cambiadas(root) - permitidas)
        if restantes:
            raise RuntimeError(
                "no se pudieron restaurar rutas fuera del CLAIM: " + ",".join(restantes)
            )

    return {
        "schema": 1,
        "allowed": sorted(permitidas),
        "changed_allowed": dentro,
        "outside": fuera,
        "scratch": borradores,
        "restored": bool(restaurar and fuera),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", type=Path, required=True)
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--restore", action="store_true")
    args = parser.parse_args()

    root = args.root.resolve()
    resultado = ejecutar(root, args.plan.resolve(), restaurar=args.restore)
    args.report.write_text(
        json.dumps(resultado, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(resultado, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
