#!/usr/bin/env python3
"""Materializa el lote auditado de Chill Vibes Art Jam 4 (#220) con Git LFS real.

Por defecto solo valida y describe el cambio. Con ``--aplicar`` copia únicamente
los GLB permitidos, fusiona sus fichas en ``godot/assets/procedencia.json``, los
pasa por ``git add`` y comprueba que el índice contiene punteros LFS válidos.
No hace commit, push ni merge y no modifica escenas/runtime.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

try:
    from preparar_chill_vibes_cc0 import (
        MANIFIESTO_DEFECTO,
        ChillVibesImportError,
        cargar_manifiesto,
        resolver_raiz_extraida,
        seleccionar_assets,
        validar_archivo_fuente,
        validar_extraidos,
    )
except ImportError:  # Permite importarlo desde pruebas cargadas por spec.
    SCRIPTS = Path(__file__).resolve().parent
    if str(SCRIPTS) not in sys.path:
        sys.path.insert(0, str(SCRIPTS))
    from preparar_chill_vibes_cc0 import (  # type: ignore  # noqa: E402
        MANIFIESTO_DEFECTO,
        ChillVibesImportError,
        cargar_manifiesto,
        resolver_raiz_extraida,
        seleccionar_assets,
        validar_archivo_fuente,
        validar_extraidos,
    )

DESTINO_REL = Path("godot/assets/modelos/chill_vibes")
PROCEDENCIA_REL = Path("godot/assets/procedencia.json")
PUNTERO_LFS = "version https://git-lfs.github.com/spec/v1\n"


class MaterializacionError(RuntimeError):
    """El checkout no permite materializar el lote sin romper sus contratos."""


def sha256_fichero(ruta: Path) -> str:
    digest = hashlib.sha256()
    with ruta.open("rb") as fh:
        for bloque in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(bloque)
    return digest.hexdigest()


def entrada_procedencia(asset: dict, manifiesto: dict) -> dict:
    destino = DESTINO_REL / asset["destino_sugerido"]
    return {
        "ruta": destino.relative_to("godot/assets").as_posix(),
        "titulo": asset["titulo"],
        "autor": manifiesto["autor"],
        "licencia": manifiesto["licencia"],
        "fuente": manifiesto["fuente"],
        "sha256": asset["sha256"],
        "archivo_origen": asset["miembro_extraido"],
        "paquete_sha256": manifiesto["archivo_sha256"],
    }


def fusionar_procedencia(datos: dict, nuevas: list[dict]) -> tuple[dict, list[dict]]:
    if not isinstance(datos, dict) or not isinstance(datos.get("assets"), list):
        raise MaterializacionError("procedencia.json debe contener una lista 'assets'")

    existentes: dict[str, dict] = {}
    for entrada in datos["assets"]:
        if not isinstance(entrada, dict) or not isinstance(entrada.get("ruta"), str):
            raise MaterializacionError("procedencia.json contiene una ficha sin ruta válida")
        ruta = entrada["ruta"]
        if ruta in existentes:
            raise MaterializacionError(f"procedencia.json contiene ruta duplicada: {ruta}")
        existentes[ruta] = entrada

    añadidas: list[dict] = []
    campos = (
        "ruta",
        "titulo",
        "autor",
        "licencia",
        "fuente",
        "sha256",
        "archivo_origen",
        "paquete_sha256",
    )
    for nueva in nuevas:
        ruta = nueva["ruta"]
        anterior = existentes.get(ruta)
        if anterior is None:
            datos["assets"].append(nueva)
            existentes[ruta] = nueva
            añadidas.append(nueva)
            continue
        if any(anterior.get(campo) != nueva.get(campo) for campo in campos):
            raise MaterializacionError(
                f"La ruta {ruta} ya existe con una ficha distinta; no se sobrescribe automáticamente"
            )
    return datos, añadidas


def ejecutar_git(repo: Path, argumentos: list[str], *, binario: bool = False):
    resultado = subprocess.run(
        ["git", "-C", str(repo), *argumentos],
        check=False,
        capture_output=True,
        text=not binario,
    )
    if resultado.returncode != 0:
        stderr = resultado.stderr
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", "replace")
        raise MaterializacionError(
            f"git {' '.join(argumentos)} falló: {(stderr or '').strip()}"
        )
    return resultado.stdout


def validar_checkout(repo: Path, destinos: list[Path], *, exigir_lfs: bool) -> None:
    if not repo.is_dir():
        raise MaterializacionError(f"No existe el checkout: {repo}")
    raiz = ejecutar_git(repo, ["rev-parse", "--show-toplevel"]).strip()
    if Path(raiz).resolve() != repo.resolve():
        raise MaterializacionError(
            f"--repo debe apuntar a la raíz del checkout; Git devuelve {raiz}"
        )
    if not (repo / PROCEDENCIA_REL).is_file():
        raise MaterializacionError(f"Falta {PROCEDENCIA_REL.as_posix()}")
    if not (repo / ".gitattributes").is_file():
        raise MaterializacionError("Falta .gitattributes")

    if exigir_lfs:
        ejecutar_git(repo, ["lfs", "version"])
        ejecutar_git(repo, ["lfs", "install", "--local"])
    for destino in destinos:
        salida = ejecutar_git(repo, ["check-attr", "filter", "--", destino.as_posix()])
        if not salida.strip().endswith("filter: lfs"):
            raise MaterializacionError(
                f"{destino.as_posix()} no está cubierto por filter=lfs en .gitattributes"
            )


def validar_rutas_limpias(repo: Path, rutas: list[Path]) -> None:
    salida = ejecutar_git(repo, ["status", "--porcelain", "--", *(p.as_posix() for p in rutas)])
    if salida.strip():
        raise MaterializacionError(
            "Hay cambios locales o staged en rutas que #220 necesita modificar; "
            "guárdalos o intégralos antes de aplicar el lote:\n" + salida.strip()
        )


def validar_destinos(repo: Path, seleccion: list[dict]) -> None:
    for asset in seleccion:
        destino = repo / DESTINO_REL / asset["destino_sugerido"]
        if destino.exists() and sha256_fichero(destino) != asset["sha256"]:
            raise MaterializacionError(
                f"Ya existe {destino.relative_to(repo)} con contenido distinto"
            )


def puntero_lfs_correcto(contenido: bytes, asset: dict) -> bool:
    try:
        texto = contenido.decode("ascii")
    except UnicodeDecodeError:
        return False
    return (
        texto.startswith(PUNTERO_LFS)
        and f"oid sha256:{asset['sha256']}\n" in texto
        and f"size {asset['bytes']}\n" in texto
    )


def verificar_indice_lfs(repo: Path, seleccion: list[dict]) -> None:
    for asset in seleccion:
        relativo = DESTINO_REL / asset["destino_sugerido"]
        contenido = ejecutar_git(repo, ["show", f":{relativo.as_posix()}"], binario=True)
        if not puntero_lfs_correcto(contenido, asset):
            raise MaterializacionError(
                f"El índice no contiene un puntero LFS válido para {relativo.as_posix()}"
            )


def planificar(repo: Path, manifiesto: dict, seleccion: list[dict]) -> tuple[dict, list[dict]]:
    datos = json.loads((repo / PROCEDENCIA_REL).read_text(encoding="utf-8"))
    nuevas = [entrada_procedencia(asset, manifiesto) for asset in seleccion]
    return fusionar_procedencia(datos, nuevas)


def materializar(
    repo: Path,
    manifiesto: dict,
    seleccion: list[dict],
    encontrados: dict[str, Path],
) -> tuple[list[Path], list[dict]]:
    destinos = [DESTINO_REL / asset["destino_sugerido"] for asset in seleccion]
    validar_checkout(repo, destinos, exigir_lfs=True)
    validar_destinos(repo, seleccion)
    procedencia_nueva, añadidas = planificar(repo, manifiesto, seleccion)

    ruta_procedencia = repo / PROCEDENCIA_REL
    procedencia_original = ruta_procedencia.read_bytes()
    previos: dict[Path, bytes | None] = {}
    rutas_stage = [*destinos, PROCEDENCIA_REL]
    validar_rutas_limpias(repo, rutas_stage)

    try:
        (repo / DESTINO_REL).mkdir(parents=True, exist_ok=True)
        for asset, relativo in zip(seleccion, destinos):
            absoluto = repo / relativo
            previos[relativo] = absoluto.read_bytes() if absoluto.exists() else None
            shutil.copyfile(encontrados[asset["id"]], absoluto)
            if sha256_fichero(absoluto) != asset["sha256"]:
                raise MaterializacionError(f"Hash post-copia incorrecto: {relativo.as_posix()}")

        ruta_procedencia.write_text(
            json.dumps(procedencia_nueva, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        ejecutar_git(repo, ["add", "--", *(p.as_posix() for p in rutas_stage)])
        verificar_indice_lfs(repo, seleccion)
        return rutas_stage, añadidas
    except Exception:
        try:
            ejecutar_git(repo, ["reset", "-q", "--", *(p.as_posix() for p in rutas_stage)])
        except Exception:
            pass
        ruta_procedencia.write_bytes(procedencia_original)
        for relativo, previo in previos.items():
            absoluto = repo / relativo
            if previo is None:
                absoluto.unlink(missing_ok=True)
            else:
                absoluto.write_bytes(previo)
        raise


def ejecutar(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("extraido", type=Path, help="Directorio extraído del .7z auditado")
    parser.add_argument("--archivo", type=Path, help=".7z original; si se indica, valida su SHA-256")
    parser.add_argument("--repo", type=Path, default=Path.cwd(), help="Raíz del checkout Git")
    parser.add_argument("--manifest", type=Path, default=MANIFIESTO_DEFECTO)
    parser.add_argument(
        "--lote",
        action="append",
        dest="lotes",
        help="Lote a materializar; repetible. Por defecto: dressing_servicio.",
    )
    parser.add_argument(
        "--aplicar",
        action="store_true",
        help="Escribe, fusiona procedencia y deja los cambios staged tras verificar LFS.",
    )
    args = parser.parse_args(argv)

    try:
        repo = args.repo.resolve()
        manifiesto = cargar_manifiesto(args.manifest)
        validar_archivo_fuente(args.archivo, manifiesto)
        raiz = resolver_raiz_extraida(args.extraido)
        seleccion = seleccionar_assets(manifiesto, args.lotes or ["dressing_servicio"])
        encontrados = validar_extraidos(raiz, seleccion)

        destinos = [DESTINO_REL / asset["destino_sugerido"] for asset in seleccion]
        validar_checkout(repo, destinos, exigir_lfs=args.aplicar)
        validar_destinos(repo, seleccion)
        _, añadidas = planificar(repo, manifiesto, seleccion)

        if not args.aplicar:
            for asset, destino in zip(seleccion, destinos):
                print(f"{asset['id']:20s} -> {destino.as_posix()} sha256={asset['sha256']}")
            print(
                f"OK dry-run: {len(seleccion)} GLB válidos; "
                f"{len(añadidas)} fichas de procedencia nuevas; no se escribió nada."
            )
            return 0

        staged, añadidas = materializar(repo, manifiesto, seleccion, encontrados)
        print(f"OK: {len(seleccion)} GLB materializados y verificados como LFS real.")
        print(f"Procedencia: {len(añadidas)} fichas nuevas; operación idempotente.")
        print("Staged:")
        for ruta in staged:
            print(f"  {ruta.as_posix()}")
        print("Revisa `git diff --cached` y ejecuta las pruebas canónicas antes de commit/push.")
        return 0
    except (OSError, json.JSONDecodeError, ChillVibesImportError, MaterializacionError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(ejecutar())
