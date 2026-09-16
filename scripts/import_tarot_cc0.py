#!/usr/bin/env python3
"""Prepara y valida el lote CC0 de 22 Arcanos Mayores para Expediente Legado.

El script no descarga nada y nunca escribe directamente en ``godot/assets``.
Acepta una carpeta extraída o el ZIP original de OpenGameArt y genera un
staging con nombres canónicos, hashes y manifiesto para una revisión posterior.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import struct
import sys
import unicodedata
import zipfile

FUENTE = "https://opengameart.org/content/tarot-cards-major-arcana"
ARCHIVO_FUENTE = "tarot_de_marseilles_major_arcana.zip"
LICENCIA = "CC0-1.0"
DIMENSIONES = (200, 375)
EXTENSIONES = {".png", ".jpg", ".jpeg"}


class TarotImportError(RuntimeError):
    """Error de validación del lote de tarot."""


@dataclass(frozen=True)
class Arcano:
    numero: int
    carta_id: str
    nombre_fuente: str
    aliases: tuple[str, ...]


# El lote fuente es Tarot de Marseille: VIII = Justice y XI = Strength.
# No usar el orden de prometeo.json para deducir numeración: allí La Fuerza
# aparece antes por motivos del modelo de juego y se cruzarían dos frontales.
ARCANOS: tuple[Arcano, ...] = (
    Arcano(0, "el-loco", "The Fool", ("fool", "fol", "fou", "mat")),
    Arcano(1, "el-mago", "The Magician", ("magician", "bateleur")),
    Arcano(2, "la-sacerdotisa", "The High Priestess", ("high priestess", "priestess", "papesse")),
    Arcano(3, "la-emperatriz", "The Empress", ("empress", "imperatrice")),
    Arcano(4, "el-emperador", "The Emperor", ("emperor", "empereur")),
    Arcano(5, "el-hierofante", "The Pope", ("pope", "hierophant", "pape")),
    Arcano(6, "los-enamorados", "The Lovers", ("lovers", "lover", "amoureux")),
    Arcano(7, "el-carro", "The Chariot", ("chariot", "char")),
    Arcano(8, "la-justicia", "Justice", ("justice", "iustice")),
    Arcano(9, "el-ermitanio", "The Hermit", ("hermit", "ermite")),
    Arcano(10, "la-rueda", "The Wheel of Fortune", ("wheel of fortune", "wheel", "roue")),
    Arcano(11, "la-fuerza", "Strength", ("strength", "force")),
    Arcano(12, "el-colgado", "The Hanged Man", ("hanged man", "hanged", "pendu", "pandu")),
    Arcano(13, "la-muerte", "Death", ("death", "mort", "unnamed")),
    Arcano(14, "la-templanza", "Temperance", ("temperance",)),
    Arcano(15, "el-diablo", "The Devil", ("devil", "diable")),
    Arcano(16, "la-torre", "The Tower", ("tower", "maison dieu", "maison diev")),
    Arcano(17, "la-estrella", "The Star", ("star", "etoile", "toille")),
    Arcano(18, "la-luna", "The Moon", ("moon", "lune")),
    Arcano(19, "el-sol", "The Sun", ("sun", "soleil")),
    Arcano(20, "el-juicio", "The Judgment", ("judgment", "judgement", "jugement", "iugement")),
    Arcano(21, "el-mundo", "The World", ("world", "monde")),
)

POR_NUMERO = {arcano.numero: arcano for arcano in ARCANOS}
POR_ID = {arcano.carta_id: arcano for arcano in ARCANOS}

_ROMANOS = {
    1: "i", 2: "ii", 3: "iii", 4: "iv", 5: "v", 6: "vi", 7: "vii",
    8: "viii", 9: "ix", 10: "x", 11: "xi", 12: "xii", 13: "xiii",
    14: "xiv", 15: "xv", 16: "xvi", 17: "xvii", 18: "xviii",
    19: "xix", 20: "xx", 21: "xxi",
}
ROMANO_A_NUMERO = {valor: clave for clave, valor in _ROMANOS.items()}


def _ascii(texto: str) -> str:
    return unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode("ascii").lower()


def _colapsar(texto: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", _ascii(texto))


def _tokens(texto: str) -> list[str]:
    return [token for token in re.split(r"[^a-z0-9]+", _ascii(texto)) if token]


def _coincidencias_alias(nombre: str) -> list[Arcano]:
    colapsado = _colapsar(Path(nombre).stem)
    coincidencias: list[Arcano] = []
    for arcano in ARCANOS:
        aliases = (arcano.nombre_fuente, *arcano.aliases)
        if any(_colapsar(alias) and _colapsar(alias) in colapsado for alias in aliases):
            coincidencias.append(arcano)
    return coincidencias


def resolver_arcano(nombre: str) -> Arcano:
    """Resuelve un fichero fuente a un arcano sin depender del orden del ZIP."""
    coincidencias = _coincidencias_alias(nombre)
    if len(coincidencias) == 1:
        return coincidencias[0]
    if len(coincidencias) > 1:
        ids = ", ".join(a.carta_id for a in coincidencias)
        raise TarotImportError(f"Nombre ambiguo {nombre!r}: coincide con {ids}")

    tokens = _tokens(Path(nombre).stem)
    numeros = {int(token) for token in tokens if token.isdigit() and 0 <= int(token) <= 21}
    romanos = {ROMANO_A_NUMERO[token] for token in tokens if token in ROMANO_A_NUMERO}
    candidatos = numeros | romanos
    if len(candidatos) == 1:
        return POR_NUMERO[candidatos.pop()]
    if len(candidatos) > 1:
        raise TarotImportError(f"Numeración ambigua en {nombre!r}: {sorted(candidatos)}")
    raise TarotImportError(f"No se reconoce el arcano de {nombre!r}")


def _dimensiones_png(datos: bytes) -> tuple[int, int]:
    if len(datos) < 24 or datos[:8] != b"\x89PNG\r\n\x1a\n" or datos[12:16] != b"IHDR":
        raise TarotImportError("PNG inválido o sin cabecera IHDR")
    return struct.unpack(">II", datos[16:24])


def _dimensiones_jpeg(datos: bytes) -> tuple[int, int]:
    if len(datos) < 4 or datos[:2] != b"\xff\xd8":
        raise TarotImportError("JPEG inválido")
    stream = io.BytesIO(datos)
    stream.seek(2)
    sof = {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF}
    while True:
        prefijo = stream.read(1)
        if not prefijo:
            break
        if prefijo != b"\xff":
            continue
        marcador = stream.read(1)
        while marcador == b"\xff":
            marcador = stream.read(1)
        if not marcador:
            break
        codigo = marcador[0]
        if codigo in {0xD8, 0xD9}:
            continue
        longitud_raw = stream.read(2)
        if len(longitud_raw) != 2:
            break
        longitud = struct.unpack(">H", longitud_raw)[0]
        if longitud < 2:
            raise TarotImportError("Segmento JPEG inválido")
        if codigo in sof:
            bloque = stream.read(longitud - 2)
            if len(bloque) < 5:
                break
            alto, ancho = struct.unpack(">HH", bloque[1:5])
            return ancho, alto
        stream.seek(longitud - 2, io.SEEK_CUR)
    raise TarotImportError("JPEG sin marcador SOF de dimensiones")


def dimensiones_imagen(nombre: str, datos: bytes) -> tuple[int, int]:
    extension = Path(nombre).suffix.lower()
    if extension == ".png":
        return _dimensiones_png(datos)
    if extension in {".jpg", ".jpeg"}:
        return _dimensiones_jpeg(datos)
    raise TarotImportError(f"Formato no admitido: {nombre}")


@dataclass(frozen=True)
class ImagenFuente:
    nombre: str
    datos: bytes


def leer_fuente(ruta: Path) -> list[ImagenFuente]:
    if ruta.is_dir():
        imagenes = []
        for fichero in sorted(ruta.rglob("*")):
            if fichero.is_file() and fichero.suffix.lower() in EXTENSIONES:
                imagenes.append(ImagenFuente(fichero.relative_to(ruta).as_posix(), fichero.read_bytes()))
        return imagenes
    if ruta.is_file() and ruta.suffix.lower() == ".zip":
        with zipfile.ZipFile(ruta) as archivo:
            return [
                ImagenFuente(nombre, archivo.read(nombre))
                for nombre in sorted(archivo.namelist())
                if not nombre.endswith("/") and PurePosixPath(nombre).suffix.lower() in EXTENSIONES
            ]
    raise TarotImportError("La fuente debe ser una carpeta extraída o un fichero .zip")


def descubrir_cartas(imagenes: list[ImagenFuente]) -> dict[str, ImagenFuente]:
    if len(imagenes) != len(ARCANOS):
        raise TarotImportError(f"Se esperaban 22 imágenes y se encontraron {len(imagenes)}")

    por_id: dict[str, ImagenFuente] = {}
    for imagen in imagenes:
        arcano = resolver_arcano(imagen.nombre)
        if arcano.carta_id in por_id:
            anterior = por_id[arcano.carta_id].nombre
            raise TarotImportError(
                f"Arcano duplicado {arcano.carta_id}: {anterior!r} y {imagen.nombre!r}"
            )
        medidas = dimensiones_imagen(imagen.nombre, imagen.datos)
        if medidas != DIMENSIONES:
            raise TarotImportError(
                f"{imagen.nombre}: dimensiones {medidas[0]}x{medidas[1]}, "
                f"se esperaban {DIMENSIONES[0]}x{DIMENSIONES[1]}"
            )
        por_id[arcano.carta_id] = imagen

    faltan = sorted(set(POR_ID) - set(por_id))
    if faltan:
        raise TarotImportError(f"Faltan arcanos: {', '.join(faltan)}")
    return por_id


def validar_ids_proyecto(ruta_prometeo: Path) -> None:
    datos = json.loads(ruta_prometeo.read_text(encoding="utf-8"))
    tarot = datos.get("tarot")
    if not isinstance(tarot, list):
        raise TarotImportError(f"{ruta_prometeo} no contiene una lista 'tarot'")
    ids = [carta.get("id") for carta in tarot if isinstance(carta, dict)]
    if len(ids) != len(set(ids)):
        raise TarotImportError("prometeo.json contiene IDs de tarot duplicados")
    esperados = set(POR_ID)
    reales = set(ids)
    if reales != esperados:
        faltan = sorted(esperados - reales)
        sobran = sorted(reales - esperados)
        detalle = []
        if faltan:
            detalle.append("faltan=" + ",".join(faltan))
        if sobran:
            detalle.append("sobran=" + ",".join(sobran))
        raise TarotImportError("Los IDs del proyecto no coinciden con el mapa canónico: " + "; ".join(detalle))


def _a_png(imagen: ImagenFuente) -> tuple[bytes, str | None]:
    extension = Path(imagen.nombre).suffix.lower()
    if extension == ".png":
        return imagen.datos, None
    try:
        from PIL import Image  # type: ignore
    except ImportError as exc:
        raise TarotImportError(
            f"{imagen.nombre} es JPEG. Instala Pillow para convertirlo a PNG o usa una fuente PNG."
        ) from exc
    origen = Image.open(io.BytesIO(imagen.datos))
    salida = io.BytesIO()
    origen.save(salida, format="PNG", optimize=False)
    return salida.getvalue(), "conversión JPEG→PNG sin redimensionado"


def preparar_staging(por_id: dict[str, ImagenFuente], salida: Path) -> dict:
    generados = {f"{arcano.carta_id}.png" for arcano in ARCANOS} | {"tarot-cc0-manifest.json"}
    if salida.exists():
        desconocidos = sorted(
            fichero.name for fichero in salida.iterdir() if fichero.name not in generados
        )
        if desconocidos:
            raise TarotImportError(
                f"El staging {salida} contiene ficheros ajenos: {', '.join(desconocidos)}"
            )
        for nombre in generados:
            fichero = salida / nombre
            if fichero.exists():
                fichero.unlink()
    salida.mkdir(parents=True, exist_ok=True)
    entradas = []
    for arcano in ARCANOS:
        imagen = por_id[arcano.carta_id]
        datos_png, transformacion = _a_png(imagen)
        destino = salida / f"{arcano.carta_id}.png"
        destino.write_bytes(datos_png)
        entrada = {
            "numero_marsella": arcano.numero,
            "id": arcano.carta_id,
            "nombre_fuente": arcano.nombre_fuente,
            "fichero_fuente": imagen.nombre,
            "fichero_destino": destino.name,
            "sha256": hashlib.sha256(datos_png).hexdigest(),
            "dimensiones": list(DIMENSIONES),
        }
        if transformacion:
            entrada["transformacion"] = transformacion
        entradas.append(entrada)

    manifiesto = {
        "fuente": FUENTE,
        "archivo_fuente": ARCHIVO_FUENTE,
        "licencia": LICENCIA,
        "cantidad": len(entradas),
        "cartas": entradas,
    }
    (salida / "tarot-cc0-manifest.json").write_text(
        json.dumps(manifiesto, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return manifiesto


def _ruta_prometeo(repo: Path) -> Path:
    return repo / "godot" / "datos" / "prometeo.json"


def ejecutar(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("fuente", type=Path, help="Carpeta extraída o ZIP de OpenGameArt")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("dist/.cache/tarot-cc0"),
        help="Directorio de staging (por defecto: dist/.cache/tarot-cc0)",
    )
    parser.add_argument("--repo", type=Path, default=Path.cwd(), help="Raíz del repositorio")
    parser.add_argument("--dry-run", action="store_true", help="Valida y muestra el mapeo sin escribir")
    args = parser.parse_args(argv)

    try:
        validar_ids_proyecto(_ruta_prometeo(args.repo))
        cartas = descubrir_cartas(leer_fuente(args.fuente))
        if args.dry_run:
            for arcano in ARCANOS:
                print(f"{arcano.numero:02d} {arcano.carta_id:18s} <- {cartas[arcano.carta_id].nombre}")
            print("OK: 22 cartas, IDs y dimensiones válidos; no se escribió ningún fichero.")
            return 0
        manifiesto = preparar_staging(cartas, args.output)
        print(f"OK: {manifiesto['cantidad']} cartas preparadas en {args.output}")
        print(f"Manifiesto: {args.output / 'tarot-cc0-manifest.json'}")
        return 0
    except (OSError, json.JSONDecodeError, zipfile.BadZipFile, TarotImportError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(ejecutar())
