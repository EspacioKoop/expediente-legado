#!/usr/bin/env python3
"""Materializa Kubasta para #298 en un checkout real con Git LFS.

El ZIP auditado se valida por SHA-256 y por el hash/tamaño del TTF exacto.
Por defecto solo hace dry-run. Con ``--aplicar`` escribe Kubasta.ttf, fusiona
su ficha en ``godot/assets/procedencia.json``, hace ``git add`` y comprueba que
el índice contiene un puntero Git LFS canónico con el mismo OID y tamaño.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

DESTINO_REL = Path("godot/assets/fonts/Kubasta.ttf")
PROCEDENCIA_REL = Path("godot/assets/procedencia.json")
MIEMBRO_TTF = "Kubasta/Kubasta.ttf"
FUENTE = "https://zichy.itch.io/kubasta"
AUTOR = "studio zichy"
LICENCIA = "CC0-1.0"
PAQUETE_SHA256 = "e2d4c74fbec43a9c5b9d1b818fb943976144be2980bd504e83b0f4f21a8a288c"
FUENTE_SHA256 = "73febb398631f45a0763e275dcb8c4d60fe74ac9e00e74edb21b176f7b4d6824"
FUENTE_BYTES = 150820
PUNTERO_LFS = "version https://git-lfs.github.com/spec/v1\n"


class MaterializacionError(RuntimeError):
    """El paquete o checkout no cumple el contrato de importación de #298."""


def sha256_bytes(contenido: bytes) -> str:
    return hashlib.sha256(contenido).hexdigest()


def sha256_fichero(ruta: Path) -> str:
    digest = hashlib.sha256()
    with ruta.open("rb") as fh:
        for bloque in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(bloque)
    return digest.hexdigest()


def validar_zip(ruta: Path, *, aceptar_reempaquetado: bool = False) -> tuple[bytes, str]:
    if not ruta.is_file():
        raise MaterializacionError(f"No existe el ZIP: {ruta}")
    paquete_sha = sha256_fichero(ruta)
    if paquete_sha != PAQUETE_SHA256 and not aceptar_reempaquetado:
        raise MaterializacionError(
            "SHA-256 del ZIP distinto al paquete auditado de #298: "
            f"{paquete_sha}; esperado {PAQUETE_SHA256}"
        )
    try:
        with zipfile.ZipFile(ruta) as zf:
            try:
                contenido = zf.read(MIEMBRO_TTF)
            except KeyError as exc:
                raise MaterializacionError(f"Falta {MIEMBRO_TTF} en el ZIP") from exc
    except zipfile.BadZipFile as exc:
        raise MaterializacionError("El fichero no es un ZIP válido") from exc

    if len(contenido) != FUENTE_BYTES:
        raise MaterializacionError(
            f"Kubasta.ttf mide {len(contenido)} bytes; esperados {FUENTE_BYTES}"
        )
    hash_fuente = sha256_bytes(contenido)
    if hash_fuente != FUENTE_SHA256:
        raise MaterializacionError(
            f"SHA-256 de Kubasta.ttf incorrecto: {hash_fuente}; esperado {FUENTE_SHA256}"
        )
    return contenido, paquete_sha


def entrada_procedencia(paquete_sha: str) -> dict:
    return {
        "ruta": "fonts/Kubasta.ttf",
        "titulo": "Kubasta Regular",
        "autor": AUTOR,
        "licencia": LICENCIA,
        "fuente": FUENTE,
        "sha256": FUENTE_SHA256,
        "archivo_origen": MIEMBRO_TTF,
        "paquete_sha256": paquete_sha,
    }


def fusionar_procedencia(datos: dict, nueva: dict) -> tuple[dict, bool]:
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

    anterior = existentes.get(nueva["ruta"])
    if anterior is None:
        datos["assets"].append(nueva)
        return datos, True

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
    if any(anterior.get(campo) != nueva.get(campo) for campo in campos):
        raise MaterializacionError(
            f"La ruta {nueva['ruta']} ya existe con una ficha distinta; no se sobrescribe automáticamente"
        )
    return datos, False


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


def validar_checkout(repo: Path, *, exigir_lfs: bool) -> None:
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
    salida = ejecutar_git(repo, ["check-attr", "filter", "--", DESTINO_REL.as_posix()])
    if not salida.strip().endswith("filter: lfs"):
        raise MaterializacionError(
            f"{DESTINO_REL.as_posix()} no está cubierto por filter=lfs en .gitattributes"
        )


def validar_rutas_limpias(repo: Path) -> None:
    salida = ejecutar_git(
        repo,
        ["status", "--porcelain", "--", DESTINO_REL.as_posix(), PROCEDENCIA_REL.as_posix()],
    )
    if salida.strip():
        raise MaterializacionError(
            "Hay cambios locales o staged en las rutas que #298 necesita modificar; "
            "intégralos antes de aplicar Kubasta:\n" + salida.strip()
        )


def puntero_lfs_correcto(contenido: bytes) -> bool:
    esperado = (
        PUNTERO_LFS
        + f"oid sha256:{FUENTE_SHA256}\n"
        + f"size {FUENTE_BYTES}\n"
    ).encode("ascii")
    return contenido == esperado


def verificar_indice_lfs(repo: Path) -> None:
    contenido = ejecutar_git(repo, ["show", f":{DESTINO_REL.as_posix()}"], binario=True)
    if not puntero_lfs_correcto(contenido):
        raise MaterializacionError(
            f"El índice no contiene un puntero LFS canónico para {DESTINO_REL.as_posix()}"
        )


def planificar(repo: Path, paquete_sha: str) -> tuple[dict, bool]:
    datos = json.loads((repo / PROCEDENCIA_REL).read_text(encoding="utf-8"))
    return fusionar_procedencia(datos, entrada_procedencia(paquete_sha))


def materializar(repo: Path, contenido: bytes, paquete_sha: str) -> bool:
    validar_checkout(repo, exigir_lfs=True)
    validar_rutas_limpias(repo)
    destino = repo / DESTINO_REL
    if destino.exists() and sha256_fichero(destino) != FUENTE_SHA256:
        raise MaterializacionError(f"Ya existe {DESTINO_REL} con contenido distinto")
    procedencia_nueva, añadida = planificar(repo, paquete_sha)

    ruta_procedencia = repo / PROCEDENCIA_REL
    procedencia_original = ruta_procedencia.read_bytes()
    fuente_original = destino.read_bytes() if destino.exists() else None
    try:
        destino.parent.mkdir(parents=True, exist_ok=True)
        destino.write_bytes(contenido)
        if sha256_fichero(destino) != FUENTE_SHA256:
            raise MaterializacionError("Hash post-copia incorrecto para Kubasta.ttf")
        ruta_procedencia.write_text(
            json.dumps(procedencia_nueva, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        ejecutar_git(
            repo,
            ["add", "--", DESTINO_REL.as_posix(), PROCEDENCIA_REL.as_posix()],
        )
        verificar_indice_lfs(repo)
        return añadida
    except Exception:
        try:
            ejecutar_git(
                repo,
                ["reset", "-q", "--", DESTINO_REL.as_posix(), PROCEDENCIA_REL.as_posix()],
            )
        except Exception:
            pass
        ruta_procedencia.write_bytes(procedencia_original)
        if fuente_original is None:
            destino.unlink(missing_ok=True)
        else:
            destino.write_bytes(fuente_original)
        raise


def ejecutar(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip", type=Path, help="Kubasta.zip auditado")
    parser.add_argument("--repo", type=Path, default=Path.cwd(), help="Raíz del checkout Git")
    parser.add_argument(
        "--aceptar-reempaquetado",
        action="store_true",
        help="Acepta otro contenedor ZIP solo si Kubasta.ttf coincide byte a byte por hash/tamaño.",
    )
    parser.add_argument(
        "--aplicar",
        action="store_true",
        help="Escribe el TTF, fusiona procedencia y deja ambos cambios staged tras verificar LFS.",
    )
    args = parser.parse_args(argv)

    try:
        repo = args.repo.resolve()
        contenido, paquete_sha = validar_zip(
            args.zip, aceptar_reempaquetado=args.aceptar_reempaquetado
        )
        validar_checkout(repo, exigir_lfs=args.aplicar)
        _, añadida = planificar(repo, paquete_sha)
        if not args.aplicar:
            print(f"ZIP sha256={paquete_sha}")
            print(
                f"{MIEMBRO_TTF} -> {DESTINO_REL.as_posix()} "
                f"bytes={FUENTE_BYTES} sha256={FUENTE_SHA256}"
            )
            print(
                "OK dry-run: Kubasta coincide con el TTF auditado; "
                f"procedencia={'nueva' if añadida else 'ya registrada'}; no se escribió nada."
            )
            return 0

        añadida = materializar(repo, contenido, paquete_sha)
        print("OK: Kubasta.ttf materializada y verificada como Git LFS real.")
        print(f"Procedencia: {'ficha añadida' if añadida else 'ficha ya existente e idéntica'}.")
        print("Staged:")
        print(f"  {DESTINO_REL.as_posix()}")
        print(f"  {PROCEDENCIA_REL.as_posix()}")
        print("Revisa `git diff --cached` y ejecuta las pruebas canónicas antes de commit/push.")
        return 0
    except (OSError, json.JSONDecodeError, MaterializacionError) as exc:
        print(f"ERROR: {exc}")
        return 2


if __name__ == "__main__":
    raise SystemExit(ejecutar())
