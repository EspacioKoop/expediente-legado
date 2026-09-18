#!/usr/bin/env python3
"""Materializa Crowbar/Flashlight de Street Furniture (#680) con Git LFS real.

El pack de Kkryy solo trae FBX/PNG. Este script no convierte: valida el ZIP y
los pares fuente extraídos, valida GLB2 autocontenidos ya preparados siguiendo
el patrón de #679, fusiona procedencia y deja los binarios staged bajo LFS.

Por defecto hace dry-run. Con --aplicar exige el ZIP original verificado.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys

FUENTE = "https://kkryy.itch.io/streetfurniture"
AUTOR = "Kkryy"
LICENCIA = "CC0-1.0"
ARCHIVO_SHA256 = "f0750ab44a7edc705ff351509c74065f103a6abeddd3974ceb44f660e971d7e3"

DESTINO_REL = Path("godot/assets/modelos/street_furniture")
PROCEDENCIA_REL = Path("godot/assets/procedencia.json")
PUNTERO_LFS = "version https://git-lfs.github.com/spec/v1\n"

ASSETS = {
    "crowbar": {
        "titulo": "Crowbar",
        "fbx": Path("Crowbar/Crowbar.fbx"),
        "png_fuente": Path("Crowbar/Crowbar.png"),
        "glb": "Crowbar.glb",
        "png": "Crowbar_Crowbar_albedo.png",
    },
    "flashlight": {
        "titulo": "Flashlight",
        "fbx": Path("Flashlight/Flashlight.fbx"),
        "png_fuente": Path("Flashlight/Flashlight.png"),
        "glb": "Flashlight.glb",
        "png": "Flashlight_Flashlight_albedo.png",
    },
}


class MaterializacionError(RuntimeError):
    """El lote no se puede materializar sin romper sus contratos."""


def sha256_fichero(ruta: Path) -> str:
    digest = hashlib.sha256()
    with ruta.open("rb") as fh:
        for bloque in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(bloque)
    return digest.hexdigest()


def seleccionar(ids: list[str] | None) -> list[tuple[str, dict]]:
    elegidos = ids or ["crowbar", "flashlight"]
    desconocidos = sorted({asset_id for asset_id in elegidos if asset_id not in ASSETS})
    if desconocidos:
        raise MaterializacionError("Assets desconocidos: " + ", ".join(desconocidos))
    salida: list[tuple[str, dict]] = []
    vistos: set[str] = set()
    for asset_id in elegidos:
        if asset_id in vistos:
            continue
        salida.append((asset_id, ASSETS[asset_id]))
        vistos.add(asset_id)
    return salida


def validar_archivo_fuente(archivo: Path | None, *, obligatorio: bool) -> None:
    if archivo is None:
        if obligatorio:
            raise MaterializacionError("--aplicar exige --archivo con Street Furniture.zip")
        return
    if not archivo.is_file():
        raise MaterializacionError(f"No existe el ZIP fuente: {archivo}")
    actual = sha256_fichero(archivo)
    if actual != ARCHIVO_SHA256:
        raise MaterializacionError(
            f"SHA-256 del ZIP incorrecto: {actual}; esperado {ARCHIVO_SHA256}"
        )


def validar_fuentes_extraidas(extraido: Path, seleccion: list[tuple[str, dict]]) -> None:
    if not extraido.is_dir():
        raise MaterializacionError(f"No existe el directorio extraído: {extraido}")
    for _asset_id, asset in seleccion:
        for campo in ("fbx", "png_fuente"):
            ruta = extraido / asset[campo]
            if not ruta.is_file():
                raise MaterializacionError(f"Falta fuente esperada: {asset[campo].as_posix()}")


def _json_glb(ruta: Path) -> dict:
    datos = ruta.read_bytes()
    if len(datos) < 20 or datos[:4] != b"glTF":
        raise MaterializacionError(f"{ruta.name} no es un GLB")
    version, total = struct.unpack_from("<II", datos, 4)
    if version != 2:
        raise MaterializacionError(f"{ruta.name} debe ser glTF 2; versión encontrada: {version}")
    if total != len(datos):
        raise MaterializacionError(f"{ruta.name} declara tamaño GLB inconsistente")
    largo_json, tipo_json = struct.unpack_from("<II", datos, 12)
    if tipo_json != 0x4E4F534A:
        raise MaterializacionError(f"{ruta.name} no empieza por chunk JSON")
    fin = 20 + largo_json
    if fin > len(datos):
        raise MaterializacionError(f"{ruta.name} tiene chunk JSON truncado")
    try:
        return json.loads(datos[20:fin].rstrip(b" \t\r\n\x00").decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise MaterializacionError(f"{ruta.name} contiene JSON glTF inválido") from exc


def validar_glb_autocontenido(ruta: Path) -> None:
    gltf = _json_glb(ruta)
    for buffer in gltf.get("buffers", []):
        if isinstance(buffer, dict) and buffer.get("uri"):
            raise MaterializacionError(f"{ruta.name} referencia un buffer externo")
    for image in gltf.get("images", []):
        if isinstance(image, dict) and image.get("uri"):
            raise MaterializacionError(f"{ruta.name} referencia una imagen externa")


def validar_png(ruta: Path) -> None:
    if not ruta.is_file() or ruta.read_bytes()[:8] != b"\x89PNG\r\n\x1a\n":
        raise MaterializacionError(f"{ruta.name} no es un PNG válido")


def validar_preparados(preparado: Path, seleccion: list[tuple[str, dict]]) -> dict[str, dict]:
    if not preparado.is_dir():
        raise MaterializacionError(f"No existe el directorio preparado: {preparado}")
    salida: dict[str, dict] = {}
    for asset_id, asset in seleccion:
        glb = preparado / asset["glb"]
        png = preparado / asset["png"]
        if not glb.is_file():
            raise MaterializacionError(f"Falta GLB preparado: {asset['glb']}")
        validar_glb_autocontenido(glb)
        validar_png(png)
        salida[asset_id] = {
            "glb": glb,
            "png": png,
            "glb_sha256": sha256_fichero(glb),
            "png_sha256": sha256_fichero(png),
            "glb_bytes": glb.stat().st_size,
            "png_bytes": png.stat().st_size,
        }
    return salida


def entradas_procedencia(
    seleccion: list[tuple[str, dict]], preparados: dict[str, dict]
) -> list[dict]:
    entradas: list[dict] = []
    for asset_id, asset in seleccion:
        preparado = preparados[asset_id]
        entradas.extend(
            [
                {
                    "ruta": (Path("modelos/street_furniture") / asset["glb"]).as_posix(),
                    "titulo": (
                        f"{asset['titulo']} (Street Furniture, "
                        f"{asset['fbx'].as_posix()} + {asset['png_fuente'].name} convertido a GLB)"
                    ),
                    "autor": AUTOR,
                    "licencia": LICENCIA,
                    "fuente": FUENTE,
                    "sha256": preparado["glb_sha256"],
                    "archivo_origen": (
                        f"{asset['fbx'].as_posix()} + {asset['png_fuente'].as_posix()}"
                    ),
                    "paquete_sha256": ARCHIVO_SHA256,
                },
                {
                    "ruta": (Path("modelos/street_furniture") / asset["png"]).as_posix(),
                    "titulo": f"Textura embebida extraída por Godot de {asset['glb']}",
                    "autor": AUTOR,
                    "licencia": LICENCIA,
                    "fuente": FUENTE,
                    "sha256": preparado["png_sha256"],
                    "archivo_origen": asset["png_fuente"].as_posix(),
                    "paquete_sha256": ARCHIVO_SHA256,
                },
            ]
        )
    return entradas


def fusionar_procedencia(datos: dict, nuevas: list[dict]) -> tuple[dict, list[dict]]:
    if not isinstance(datos, dict) or not isinstance(datos.get("assets"), list):
        raise MaterializacionError("procedencia.json debe contener una lista 'assets'")
    por_ruta: dict[str, dict] = {}
    for entrada in datos["assets"]:
        if not isinstance(entrada, dict) or not isinstance(entrada.get("ruta"), str):
            raise MaterializacionError("procedencia.json contiene una ficha sin ruta válida")
        if entrada["ruta"] in por_ruta:
            raise MaterializacionError(f"procedencia.json duplica {entrada['ruta']}")
        por_ruta[entrada["ruta"]] = entrada

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
        anterior = por_ruta.get(nueva["ruta"])
        if anterior is None:
            datos["assets"].append(nueva)
            por_ruta[nueva["ruta"]] = nueva
            añadidas.append(nueva)
            continue
        if any(anterior.get(campo) != nueva.get(campo) for campo in campos):
            raise MaterializacionError(
                f"{nueva['ruta']} ya existe con procedencia/contenido distinto"
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


def rutas_destino(seleccion: list[tuple[str, dict]]) -> list[Path]:
    salida: list[Path] = []
    for _asset_id, asset in seleccion:
        salida.extend([DESTINO_REL / asset["glb"], DESTINO_REL / asset["png"]])
    return salida


def validar_checkout(repo: Path, destinos: list[Path], *, exigir_lfs: bool) -> None:
    if not repo.is_dir():
        raise MaterializacionError(f"No existe el checkout: {repo}")
    raiz = Path(ejecutar_git(repo, ["rev-parse", "--show-toplevel"]).strip())
    if raiz.resolve() != repo.resolve():
        raise MaterializacionError("--repo debe apuntar a la raíz del checkout")
    if not (repo / PROCEDENCIA_REL).is_file():
        raise MaterializacionError(f"Falta {PROCEDENCIA_REL.as_posix()}")
    if exigir_lfs:
        ejecutar_git(repo, ["lfs", "version"])
        ejecutar_git(repo, ["lfs", "install", "--local"])
    for destino in destinos:
        salida = ejecutar_git(repo, ["check-attr", "filter", "--", destino.as_posix()])
        if not salida.strip().endswith("filter: lfs"):
            raise MaterializacionError(f"{destino.as_posix()} no está cubierto por Git LFS")


def validar_rutas_limpias(repo: Path, rutas: list[Path]) -> None:
    salida = ejecutar_git(repo, ["status", "--porcelain", "--", *(p.as_posix() for p in rutas)])
    if salida.strip():
        raise MaterializacionError("Hay cambios locales/staged en las rutas objetivo:\n" + salida.strip())


def puntero_lfs_correcto(contenido: bytes, sha256: str, tamano: int) -> bool:
    try:
        texto = contenido.decode("ascii")
    except UnicodeDecodeError:
        return False
    return (
        texto.startswith(PUNTERO_LFS)
        and f"oid sha256:{sha256}\n" in texto
        and f"size {tamano}\n" in texto
    )


def verificar_indice_lfs(
    repo: Path,
    seleccion: list[tuple[str, dict]],
    preparados: dict[str, dict],
) -> None:
    for asset_id, asset in seleccion:
        for tipo, nombre, sha_key, bytes_key in (
            ("GLB", asset["glb"], "glb_sha256", "glb_bytes"),
            ("PNG", asset["png"], "png_sha256", "png_bytes"),
        ):
            relativo = DESTINO_REL / nombre
            contenido = ejecutar_git(repo, ["show", f":{relativo.as_posix()}"], binario=True)
            info = preparados[asset_id]
            if not puntero_lfs_correcto(contenido, info[sha_key], info[bytes_key]):
                raise MaterializacionError(
                    f"El índice no contiene puntero LFS válido para {tipo} {relativo.as_posix()}"
                )


def validar_destinos(
    repo: Path,
    seleccion: list[tuple[str, dict]],
    preparados: dict[str, dict],
) -> None:
    for asset_id, asset in seleccion:
        info = preparados[asset_id]
        for nombre, sha_key in (
            (asset["glb"], "glb_sha256"),
            (asset["png"], "png_sha256"),
        ):
            destino = repo / DESTINO_REL / nombre
            if destino.exists() and sha256_fichero(destino) != info[sha_key]:
                raise MaterializacionError(
                    f"Ya existe {destino.relative_to(repo)} con contenido distinto"
                )


def materializar(
    repo: Path,
    seleccion: list[tuple[str, dict]],
    preparados: dict[str, dict],
) -> tuple[list[Path], list[dict]]:
    destinos = rutas_destino(seleccion)
    rutas_stage = [*destinos, PROCEDENCIA_REL]
    validar_checkout(repo, destinos, exigir_lfs=True)
    validar_destinos(repo, seleccion, preparados)
    validar_rutas_limpias(repo, rutas_stage)

    ruta_procedencia = repo / PROCEDENCIA_REL
    original_procedencia = ruta_procedencia.read_bytes()
    previos: dict[Path, bytes | None] = {}
    datos = json.loads(original_procedencia.decode("utf-8"))
    procedencia, añadidas = fusionar_procedencia(
        datos, entradas_procedencia(seleccion, preparados)
    )

    try:
        (repo / DESTINO_REL).mkdir(parents=True, exist_ok=True)
        for asset_id, asset in seleccion:
            for clave, nombre in (("glb", asset["glb"]), ("png", asset["png"])):
                relativo = DESTINO_REL / nombre
                absoluto = repo / relativo
                previos[relativo] = absoluto.read_bytes() if absoluto.exists() else None
                absoluto.write_bytes(preparados[asset_id][clave].read_bytes())

        ruta_procedencia.write_text(
            json.dumps(procedencia, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        ejecutar_git(repo, ["add", "--", *(p.as_posix() for p in rutas_stage)])
        verificar_indice_lfs(repo, seleccion, preparados)
        return rutas_stage, añadidas
    except Exception:
        try:
            ejecutar_git(repo, ["reset", "-q", "--", *(p.as_posix() for p in rutas_stage)])
        except Exception:
            pass
        ruta_procedencia.write_bytes(original_procedencia)
        for relativo, previo in previos.items():
            absoluto = repo / relativo
            if previo is None:
                absoluto.unlink(missing_ok=True)
            else:
                absoluto.write_bytes(previo)
        raise


def ejecutar(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("extraido", type=Path, help="Directorio extraído de Street Furniture.zip")
    parser.add_argument("preparado", type=Path, help="Directorio con GLB/PNG preparados")
    parser.add_argument("--archivo", type=Path, help="Street Furniture.zip original")
    parser.add_argument("--repo", type=Path, default=Path.cwd(), help="Raíz del checkout Git")
    parser.add_argument("--asset", action="append", dest="assets", help="crowbar o flashlight; repetible")
    parser.add_argument("--aplicar", action="store_true", help="Copia y deja staged tras verificar LFS")
    args = parser.parse_args(argv)

    try:
        seleccion = seleccionar(args.assets)
        validar_archivo_fuente(args.archivo, obligatorio=args.aplicar)
        validar_fuentes_extraidas(args.extraido, seleccion)
        preparados = validar_preparados(args.preparado, seleccion)
        repo = args.repo.resolve()
        destinos = rutas_destino(seleccion)
        validar_checkout(repo, destinos, exigir_lfs=args.aplicar)
        validar_destinos(repo, seleccion, preparados)

        datos = json.loads((repo / PROCEDENCIA_REL).read_text(encoding="utf-8"))
        _, añadidas = fusionar_procedencia(
            datos, entradas_procedencia(seleccion, preparados)
        )

        if not args.aplicar:
            for asset_id, asset in seleccion:
                info = preparados[asset_id]
                print(
                    f"{asset_id:10s} -> {asset['glb']} "
                    f"sha256={info['glb_sha256']} + {asset['png']}"
                )
            print(
                f"OK dry-run: {len(seleccion)} props; "
                f"{len(añadidas)} fichas nuevas; no se escribió nada."
            )
            return 0

        staged, añadidas = materializar(repo, seleccion, preparados)
        print(f"OK: {len(seleccion)} props materializados y verificados bajo Git LFS.")
        print(f"Procedencia: {len(añadidas)} fichas nuevas.")
        print("Staged:")
        for ruta in staged:
            print(f"  {ruta.as_posix()}")
        return 0
    except (OSError, json.JSONDecodeError, MaterializacionError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(ejecutar())
