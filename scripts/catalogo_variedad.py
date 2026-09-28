#!/usr/bin/env python3
"""Mide variedad estructural del catálogo de expedientes de SIGA-98 (#91).

No decide cuántos casos ofrecer por vida laboral. Produce evidencia estable para
esa decisión usando únicamente forma editorial (tipos, conteos y flags), nunca
el texto visible ni ids internos de documentos/pistas.
"""

from __future__ import annotations

import argparse
import json
from itertools import combinations
from pathlib import Path
from statistics import mean
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CATALOGO_POR_DEFECTO = ROOT / "godot" / "datos" / "casos.json"


def _bucket(cantidad: int) -> str:
    if cantidad <= 0:
        return "0"
    if cantidad == 1:
        return "1"
    if cantidad <= 3:
        return "2-3"
    if cantidad <= 5:
        return "4-5"
    return "6+"


def perfil(caso: dict[str, Any]) -> dict[str, Any]:
    registros = caso.get("registros", [])
    pistas = caso.get("pistas", [])
    sospechosos = caso.get("sospechosos", [])
    if not isinstance(registros, list):
        registros = []
    if not isinstance(pistas, list):
        pistas = []
    if not isinstance(sospechosos, list):
        sospechosos = []

    tipos = sorted(
        {
            str(registro.get("tipo", "")).strip()
            for registro in registros
            if isinstance(registro, dict) and str(registro.get("tipo", "")).strip()
        }
    )
    relaciones = sum(
        1
        for pista in pistas
        if isinstance(pista, dict) and bool(str(pista.get("registroOrigen2", "")).strip())
    )
    gatillos = sum(
        1
        for pista in pistas
        if isinstance(pista, dict) and bool(str(pista.get("fraseGatillo", "")).strip())
    )

    return {
        "id": str(caso.get("id", "")).strip(),
        "tipos_documento": tipos,
        "registros": len(registros),
        "pistas": len(pistas),
        "relaciones": relaciones,
        "gatillos": gatillos,
        "sospechosos": len(sospechosos),
        "confidencial": bool(caso.get("confidencial", False)),
        "principal": bool(caso.get("principal", True)),
    }


def rasgos(un_perfil: dict[str, Any]) -> set[str]:
    salida = {f"tipo:{tipo}" for tipo in un_perfil["tipos_documento"]}
    salida.update(
        {
            f"registros:{_bucket(int(un_perfil['registros']))}",
            f"pistas:{_bucket(int(un_perfil['pistas']))}",
            f"relaciones:{_bucket(int(un_perfil['relaciones']))}",
            f"gatillos:{_bucket(int(un_perfil['gatillos']))}",
            f"sospechosos:{_bucket(int(un_perfil['sospechosos']))}",
            f"confidencial:{int(bool(un_perfil['confidencial']))}",
            f"principal:{int(bool(un_perfil['principal']))}",
        }
    )
    return salida


def similitud(a: dict[str, Any], b: dict[str, Any]) -> float:
    ra = rasgos(a)
    rb = rasgos(b)
    union = ra | rb
    if not union:
        return 1.0
    return len(ra & rb) / len(union)


def analizar(casos: list[dict[str, Any]]) -> dict[str, Any]:
    perfiles = sorted((perfil(caso) for caso in casos), key=lambda item: item["id"])
    ids = [item["id"] for item in perfiles]
    if any(not case_id for case_id in ids):
        raise ValueError("todos los casos deben tener id")
    if len(set(ids)) != len(ids):
        raise ValueError("hay ids de caso duplicados")

    pares = []
    for a, b in combinations(perfiles, 2):
        pares.append(
            {
                "a": a["id"],
                "b": b["id"],
                "similitud": round(similitud(a, b), 4),
            }
        )
    pares.sort(key=lambda item: (-item["similitud"], item["a"], item["b"]))

    firmas = {
        json.dumps(
            {
                key: value
                for key, value in item.items()
                if key != "id"
            },
            ensure_ascii=False,
            sort_keys=True,
        )
        for item in perfiles
    }
    tipos = sorted({tipo for item in perfiles for tipo in item["tipos_documento"]})
    valores = [item["similitud"] for item in pares]

    return {
        "schema": 1,
        "casos": len(perfiles),
        "perfiles_unicos": len(firmas),
        "tipos_documento_unicos": len(tipos),
        "tipos_documento": tipos,
        "similitud_media": round(mean(valores), 4) if valores else 0.0,
        "similitud_maxima": pares[0]["similitud"] if pares else 0.0,
        "pares_mas_similares": pares[:5],
        "perfiles": perfiles,
    }


def cargar(ruta: Path) -> list[dict[str, Any]]:
    datos = json.loads(ruta.read_text(encoding="utf-8"))
    if not isinstance(datos, dict) or not isinstance(datos.get("casos"), list):
        raise ValueError("el catálogo debe contener una lista 'casos'")
    return datos["casos"]


def markdown(informe: dict[str, Any]) -> str:
    lineas = [
        "# Variedad estructural del catálogo",
        "",
        f"- Casos: {informe['casos']}",
        f"- Perfiles estructurales únicos: {informe['perfiles_unicos']}",
        f"- Tipos documentales únicos: {informe['tipos_documento_unicos']}",
        f"- Similitud media: {informe['similitud_media']:.4f}",
        f"- Similitud máxima: {informe['similitud_maxima']:.4f}",
        "",
        "## Pares más similares",
        "",
        "| Caso A | Caso B | Similitud |",
        "|---|---|---:|",
    ]
    for par in informe["pares_mas_similares"]:
        lineas.append(f"| {par['a']} | {par['b']} | {par['similitud']:.4f} |")
    lineas.extend(
        [
            "",
            "La métrica usa solo estructura editorial. No compara títulos, "
            "descripciones ni contenido traducible y no decide cuántos casos "
            "debe ofrecer una vida laboral.",
        ]
    )
    return "\n".join(lineas) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalogo", type=Path, default=CATALOGO_POR_DEFECTO)
    parser.add_argument("--formato", choices=("json", "markdown"), default="json")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    informe = analizar(cargar(args.catalogo))
    if args.formato == "markdown":
        salida = markdown(informe)
    else:
        salida = json.dumps(informe, ensure_ascii=False, indent=2, sort_keys=True) + "\n"

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(salida, encoding="utf-8")
    print(salida, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
