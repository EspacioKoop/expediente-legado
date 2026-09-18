#!/usr/bin/env python3
"""Prepara una selección reproducible del Horror Texture Pack para #231.

No modifica godot/assets/procedencia.json ni crea punteros Git LFS. Copia PNG
verificados a una carpeta de staging/proyecto y emite un fragmento de
procedencia para revisión. Los binarios solo deben versionarse después mediante
Git LFS real.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import struct
import subprocess
import tempfile
from pathlib import Path
from typing import Iterable

MANIFIESTO_POR_DEFECTO = Path("docs/assets/horror-texture-pack.manifest.json")
PERFILES_POR_DEFECTO = (
    "sutil",
    "sueno_archivo",
    "sueno_escuela",
    "sueno_castillo",
    "sueno_desierto",
    "sueno_pesadilla",
)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for bloque in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(bloque)
    return h.hexdigest()


def leer_manifiesto(path: Path) -> dict[str, object]:
    datos = json.loads(path.read_text(encoding="utf-8"))
    for clave in ("fuente", "autor", "licencia", "archivos_fuente", "categorias", "perfiles"):
        if clave not in datos:
            raise ValueError(f"manifiesto incompleto: falta {clave}")
    return datos


def _png_info(path: Path) -> tuple[int, int, int]:
    with path.open("rb") as fh:
        cabecera = fh.read(26)
    if len(cabecera) < 26 or cabecera[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: PNG inválido")
    if cabecera[12:16] != b"IHDR":
        raise ValueError(f"{path}: PNG sin IHDR")
    ancho, alto = struct.unpack(">II", cabecera[16:24])
    tipo_color = cabecera[25]
    return ancho, alto, tipo_color


def _extractor() -> tuple[str, list[str]]:
    candidatos = (
        ("7z", ["7z", "x", "-y"]),
        ("unrar", ["unrar", "x", "-o+"]),
        ("unar", ["unar", "-f"]),
        ("bsdtar", ["bsdtar", "-xf"]),
    )
    for ejecutable, base in candidatos:
        if shutil.which(ejecutable):
            return ejecutable, base
    raise ValueError("no hay extractor RAR disponible (7z, unrar, unar o bsdtar)")


def extraer_rar(origen: Path, destino: Path) -> None:
    ejecutable, base = _extractor()
    if ejecutable == "7z":
        comando = [*base, str(origen), f"-o{destino}"]
    elif ejecutable == "unrar":
        comando = [*base, str(origen), str(destino) + "/"]
    elif ejecutable == "unar":
        comando = [*base, "-o", str(destino), str(origen)]
    else:
        comando = [*base, str(origen), "-C", str(destino)]
    subprocess.run(comando, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def _raiz_resolucion(origen: Path, resolucion: int) -> Path:
    nombre = f"{resolucion}x{resolucion}"
    if origen.name == nombre and origen.is_dir():
        return origen
    directa = origen / nombre
    if directa.is_dir():
        return directa
    candidatas = [p for p in origen.rglob(nombre) if p.is_dir()]
    if len(candidatas) != 1:
        raise ValueError(f"{origen}: no se encontró una única carpeta {nombre}")
    return candidatas[0]


def _archivo_de_id(raiz: Path, identificador: str, resolucion: int) -> Path:
    relativa = Path(identificador)
    nombre = f"{relativa.name}-{resolucion}x{resolucion}.png"
    return raiz / relativa.parent / nombre


def _seleccion(manifiesto: dict[str, object], perfiles: tuple[str, ...], todos: bool) -> list[str]:
    if todos:
        categorias = manifiesto["categorias"]
        assert isinstance(categorias, dict)
        seleccion: list[str] = []
        for categoria, cantidad in categorias.items():
            prefijo = "Stain" if categoria == "Stains" else str(categoria)
            for indice in range(1, int(cantidad) + 1):
                seleccion.append(f"{categoria}/Horror_{prefijo}_{indice:02d}")
        return seleccion

    catalogo = manifiesto["perfiles"]
    assert isinstance(catalogo, dict)
    seleccion = []
    for perfil in perfiles:
        if perfil not in catalogo:
            raise ValueError(f"perfil desconocido: {perfil}")
        elementos = catalogo[perfil]
        if not isinstance(elementos, list):
            raise ValueError(f"perfil inválido: {perfil}")
        seleccion.extend(str(item) for item in elementos)
    return sorted(set(seleccion))


def _validar_exclusiones(
    manifiesto: dict[str, object], seleccion: list[str], permitir_gore: bool
) -> None:
    excluidos = {str(item) for item in manifiesto.get("excluidos_automaticos", [])}
    encontrados = excluidos.intersection(seleccion)
    if encontrados and not permitir_gore:
        lista = ", ".join(sorted(encontrados))
        raise ValueError(f"la selección contiene manchas excluidas por defecto: {lista}")


def preparar_desde_carpeta(
    raiz: Path,
    resolucion: int,
    seleccion: list[str],
    destino_assets: Path,
    manifiesto: dict[str, object],
    paquete_sha256: str,
) -> dict[str, object]:
    destino_base = destino_assets / "texturas" / "horror_sbs" / f"{resolucion}x{resolucion}"
    procedencia: list[dict[str, str]] = []
    copiados: list[str] = []

    for identificador in seleccion:
        origen = _archivo_de_id(raiz, identificador, resolucion)
        if not origen.is_file():
            raise ValueError(f"falta asset seleccionado: {origen}")
        ancho, alto, tipo_color = _png_info(origen)
        if (ancho, alto) != (resolucion, resolucion):
            raise ValueError(f"{origen}: {ancho}x{alto}; se esperaba {resolucion}x{resolucion}")
        if identificador.startswith("Stains/") and tipo_color not in (4, 6):
            raise ValueError(f"{origen}: la mancha no conserva canal alfa")

        relativa = Path(identificador)
        destino = destino_base / relativa.parent / origen.name
        destino.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(origen, destino)
        digest = sha256(destino)
        ruta_rel = destino.relative_to(destino_assets).as_posix()
        copiados.append(ruta_rel)
        procedencia.append(
            {
                "ruta": ruta_rel,
                "titulo": f"Horror Texture Pack — {relativa.name}",
                "autor": str(manifiesto["autor"]),
                "licencia": str(manifiesto["licencia"]),
                "fuente": str(manifiesto["fuente"]),
                "sha256": digest,
                "archivo_origen": origen.relative_to(raiz.parent).as_posix(),
                "paquete_sha256": paquete_sha256,
            }
        )

    fragmento = {
        "pack": "SBS Horror Texture Pack",
        "resolucion": f"{resolucion}x{resolucion}",
        "paquete_sha256": paquete_sha256,
        "archivos": copiados,
        "procedencia": procedencia,
    }
    fragment_path = destino_base / "procedencia.fragment.json"
    fragment_path.parent.mkdir(parents=True, exist_ok=True)
    fragment_path.write_text(
        json.dumps(fragmento, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return fragmento


def preparar(
    origen: Path,
    resolucion: int,
    destino_assets: Path,
    manifiesto_path: Path,
    perfiles: tuple[str, ...] = PERFILES_POR_DEFECTO,
    todos: bool = False,
    permitir_gore: bool = False,
) -> dict[str, object]:
    manifiesto = leer_manifiesto(manifiesto_path)
    fuentes = manifiesto["archivos_fuente"]
    assert isinstance(fuentes, dict)
    fuente = fuentes.get(str(resolucion))
    if not isinstance(fuente, dict):
        raise ValueError(f"resolución no auditada: {resolucion}")
    esperado = str(fuente["sha256"])
    seleccion = _seleccion(manifiesto, perfiles, todos)
    _validar_exclusiones(manifiesto, seleccion, permitir_gore)

    if origen.is_dir():
        raiz = _raiz_resolucion(origen, resolucion)
        return preparar_desde_carpeta(
            raiz, resolucion, seleccion, destino_assets, manifiesto, esperado
        )
    if not origen.is_file() or origen.suffix.lower() != ".rar":
        raise ValueError("origen debe ser una carpeta extraída o un .rar")
    real = sha256(origen)
    if real != esperado:
        raise ValueError(f"RAR inesperado: sha256 {real}; esperado {esperado}")
    with tempfile.TemporaryDirectory(prefix="sbs-horror-") as temporal:
        destino_temporal = Path(temporal)
        extraer_rar(origen, destino_temporal)
        raiz = _raiz_resolucion(destino_temporal, resolucion)
        return preparar_desde_carpeta(
            raiz, resolucion, seleccion, destino_assets, manifiesto, real
        )


def construir_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Audita y prepara una selección del SBS Horror Texture Pack para #231."
    )
    parser.add_argument("origen", type=Path, help="RAR original o carpeta ya extraída")
    parser.add_argument("--resolucion", type=int, choices=(128, 256, 512), default=128)
    parser.add_argument(
        "--destino-assets", type=Path, default=Path("godot/assets"), help="raíz de assets"
    )
    parser.add_argument("--manifiesto", type=Path, default=MANIFIESTO_POR_DEFECTO)
    parser.add_argument(
        "--perfil",
        action="append",
        dest="perfiles",
        help="perfil a importar; repetible. Sin este flag usa todos los perfiles curados",
    )
    parser.add_argument(
        "--todos", action="store_true", help="prepara los 100 diseños de la resolución elegida"
    )
    parser.add_argument(
        "--permitir-gore",
        action="store_true",
        help="permite incluir los Stain 01-03 si una selección explícita los contiene",
    )
    return parser


def main(argv: Iterable[str] | None = None) -> int:
    args = construir_parser().parse_args(argv)
    perfiles = tuple(args.perfiles) if args.perfiles else PERFILES_POR_DEFECTO
    try:
        fragmento = preparar(
            origen=args.origen,
            resolucion=args.resolucion,
            destino_assets=args.destino_assets,
            manifiesto_path=args.manifiesto,
            perfiles=perfiles,
            todos=args.todos,
            permitir_gore=args.permitir_gore,
        )
    except (OSError, subprocess.CalledProcessError, ValueError) as exc:
        raise SystemExit(str(exc)) from exc
    print(json.dumps(fragmento, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
