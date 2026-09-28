#!/usr/bin/env python3
"""Mide variedad estructural del catálogo de expedientes de SIGA-98 (#91).

No decide cuántos casos ofrecer por vida laboral. Produce evidencia estable para
esa decisión usando únicamente forma editorial (tipos, conteos y flags), nunca
el texto visible ni ids internos de documentos/pistas.

También puede simular tamaños de subconjunto sin tocar runtime ni guardados. La
simulación enumera combinaciones del catálogo actual y expone por separado
similitud estructural, cobertura de tipos documentales y solape esperado entre
dos vidas; no mezcla esas señales en una puntuación arbitraria.
"""

from __future__ import annotations

import argparse
import json
from itertools import combinations
from pathlib import Path
from statistics import mean, median
from typing import Any, Iterable


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
            {key: value for key, value in item.items() if key != "id"},
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


def _similitud_media_subconjunto(perfiles: tuple[dict[str, Any], ...]) -> float:
    valores = [similitud(a, b) for a, b in combinations(perfiles, 2)]
    return mean(valores) if valores else 0.0


def _cobertura_tipos(
    perfiles: tuple[dict[str, Any], ...],
    tipos_totales: set[str],
) -> float:
    if not tipos_totales:
        return 1.0
    presentes = {
        tipo for item in perfiles for tipo in item.get("tipos_documento", [])
    }
    return len(presentes) / len(tipos_totales)


def _redondear(valor: float) -> float:
    return round(float(valor), 4)


def simular_subconjuntos(
    informe: dict[str, Any],
    tamanos: Iterable[int],
) -> list[dict[str, Any]]:
    perfiles = tuple(informe.get("perfiles", []))
    total = len(perfiles)
    if total < 2:
        raise ValueError("se necesitan al menos dos casos para simular subconjuntos")

    tamanos_limpios = sorted({int(tamano) for tamano in tamanos})
    if not tamanos_limpios:
        raise ValueError("indica al menos un tamaño de subconjunto")
    if any(tamano < 2 or tamano > total for tamano in tamanos_limpios):
        raise ValueError(f"cada tamaño debe estar entre 2 y {total}")

    tipos_totales = {
        tipo for item in perfiles for tipo in item.get("tipos_documento", [])
    }
    salida = []
    for tamano in tamanos_limpios:
        muestras = []
        for grupo in combinations(perfiles, tamano):
            ids = tuple(item["id"] for item in grupo)
            muestras.append(
                {
                    "ids": ids,
                    "similitud_media": _similitud_media_subconjunto(grupo),
                    "cobertura_tipos": _cobertura_tipos(grupo, tipos_totales),
                }
            )

        similitudes = sorted(item["similitud_media"] for item in muestras)
        coberturas = sorted(item["cobertura_tipos"] for item in muestras)
        menor_similitud = min(
            muestras,
            key=lambda item: (item["similitud_media"], item["ids"]),
        )
        mayor_cobertura = min(
            muestras,
            key=lambda item: (
                -item["cobertura_tipos"],
                item["similitud_media"],
                item["ids"],
            ),
        )

        salida.append(
            {
                "tamano": tamano,
                "combinaciones": len(muestras),
                "similitud_subconjunto_min": _redondear(similitudes[0]),
                "similitud_subconjunto_mediana": _redondear(median(similitudes)),
                "similitud_subconjunto_max": _redondear(similitudes[-1]),
                "cobertura_tipos_min": _redondear(coberturas[0]),
                "cobertura_tipos_mediana": _redondear(median(coberturas)),
                "cobertura_tipos_max": _redondear(coberturas[-1]),
                "subconjunto_menor_similitud": list(menor_similitud["ids"]),
                "subconjunto_mayor_cobertura": list(mayor_cobertura["ids"]),
                "solape_esperado_dos_vidas": _redondear(
                    (tamano * tamano) / total
                ),
                "fraccion_catalogo_repetida_esperada": _redondear(
                    tamano / total
                ),
            }
        )
    return salida


def cargar(ruta: Path) -> list[dict[str, Any]]:
    datos = json.loads(ruta.read_text(encoding="utf-8"))
    if not isinstance(datos, dict) or not isinstance(datos.get("casos"), list):
        raise ValueError("el catálogo debe contener una lista 'casos'")
    return datos["casos"]


def _parsear_tamanos(valor: str) -> list[int]:
    partes = [parte.strip() for parte in valor.split(",") if parte.strip()]
    if not partes:
        raise ValueError("indica tamaños separados por comas, por ejemplo 3,5,7")
    try:
        return [int(parte) for parte in partes]
    except ValueError as exc:
        raise ValueError("los tamaños deben ser enteros separados por comas") from exc


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

    subconjuntos = informe.get("subconjuntos", [])
    if subconjuntos:
        lineas.extend(
            [
                "",
                "## Simulación de tamaños por vida",
                "",
                "| Casos/vida | Combinaciones | Sim. mediana | "
                "Cobertura tipos mediana | Solape esperado | Fracción repetida |",
                "|---:|---:|---:|---:|---:|---:|",
            ]
        )
        for fila in subconjuntos:
            lineas.append(
                "| {tamano} | {combinaciones} | "
                "{similitud_subconjunto_mediana:.4f} | "
                "{cobertura_tipos_mediana:.4f} | "
                "{solape_esperado_dos_vidas:.4f} | "
                "{fraccion_catalogo_repetida_esperada:.4f} |".format(**fila)
            )

    lineas.extend(
        [
            "",
            "La métrica usa solo estructura editorial. No compara títulos, "
            "descripciones ni contenido traducible y no decide cuántos casos "
            "debe ofrecer una vida laboral.",
        ]
    )
    if subconjuntos:
        lineas.extend(
            [
                "La simulación tampoco propone un ganador: separa variedad, "
                "cobertura y repetición para que la política de selección se "
                "decida con esos compromisos visibles.",
            ]
        )
    return "\n".join(lineas) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalogo", type=Path, default=CATALOGO_POR_DEFECTO)
    parser.add_argument("--formato", choices=("json", "markdown"), default="json")
    parser.add_argument("--output", type=Path)
    parser.add_argument(
        "--tamanos",
        help="simula subconjuntos de esos tamaños, p. ej. 3,5,7,9",
    )
    args = parser.parse_args()

    informe = analizar(cargar(args.catalogo))
    if args.tamanos:
        informe["subconjuntos"] = simular_subconjuntos(
            informe,
            _parsear_tamanos(args.tamanos),
        )
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
