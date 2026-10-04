#!/usr/bin/env python3
"""Registrador humano del playtest de doctrinas (#921 / #2293).

Valida completitud y genera un informe Markdown. No interpreta las respuestas
como aprobación de balance ni emite PASS automático.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any


CASOS_OBLIGATORIOS = ("A0", "A1", "A2", "A3", "A4", "R1", "R2", "M1")
CASO_MANDO = "G1"
DOCTRINAS_FIJAS = {
    "A0": "ninguna",
    "A1": "Asamblea",
    "A2": "Mesa de diálogo",
    "A3": "Comisión de seguimiento",
    "A4": "Externalizar",
}
CAMPOS_HUMANOS = (
    "comprension",
    "decision_tactica",
    "coste_ventana",
    "utilidad",
    "frecuencia",
    "dominante",
    "feedback",
    "incidencias",
)
ESCALAS = ("comprension", "decision_tactica", "coste_ventana", "utilidad")


def plantilla() -> dict[str, Any]:
    casos: dict[str, Any] = {}
    for caso in (*CASOS_OBLIGATORIOS, CASO_MANDO):
        casos[caso] = {
            "doctrina": DOCTRINAS_FIJAS.get(caso, ""),
            "ritual_tag": "",
            "reduccion_movimiento": caso == "M1",
            "entrada": "mando" if caso == CASO_MANDO else "teclado/ratón",
            "comprension": None,
            "decision_tactica": None,
            "coste_ventana": None,
            "utilidad": None,
            "frecuencia": "",
            "dominante": "",
            "feedback": "",
            "incidencias": "",
            "comentario": "",
        }
    return {
        "sesion": {
            "fecha": "",
            "build_sha": "",
            "plataforma": "",
            "resolucion": "",
            "probador": "",
            "mando_disponible": False,
            "motivo_sin_mando": "",
        },
        "casos": casos,
    }


def _texto(valor: Any) -> bool:
    return isinstance(valor, str) and bool(valor.strip())


def _escala(valor: Any) -> bool:
    return isinstance(valor, int) and not isinstance(valor, bool) and 1 <= valor <= 5


def _validar_caso(codigo: str, caso: Any) -> list[str]:
    errores: list[str] = []
    if not isinstance(caso, dict):
        return [f"{codigo}: falta objeto de observación"]

    for campo in ESCALAS:
        if not _escala(caso.get(campo)):
            errores.append(f"{codigo}.{campo}: debe ser entero 1..5")
    for campo in set(CAMPOS_HUMANOS) - set(ESCALAS):
        if not _texto(caso.get(campo)):
            errores.append(f"{codigo}.{campo}: requiere respuesta humana")

    doctrina_fija = DOCTRINAS_FIJAS.get(codigo)
    if doctrina_fija and str(caso.get("doctrina", "")).strip() != doctrina_fija:
        errores.append(f"{codigo}.doctrina: debe ser {doctrina_fija!r}")
    if codigo == "M1" and caso.get("reduccion_movimiento") is not True:
        errores.append("M1.reduccion_movimiento: debe ser true")
    if codigo in ("R1", "R2") and not _texto(caso.get("ritual_tag")):
        errores.append(f"{codigo}.ritual_tag: debe identificar el tag común probado")
    return errores


def evaluar(registro: Any) -> dict[str, Any]:
    errores: list[str] = []
    if not isinstance(registro, dict):
        return {"estado": "pendiente_datos", "errores": ["raíz: debe ser objeto JSON"]}

    sesion = registro.get("sesion")
    if not isinstance(sesion, dict):
        errores.append("sesion: falta objeto")
        sesion = {}
    for campo in ("fecha", "build_sha", "plataforma", "resolucion", "probador"):
        if not _texto(sesion.get(campo)):
            errores.append(f"sesion.{campo}: obligatorio")

    casos = registro.get("casos")
    if not isinstance(casos, dict):
        errores.append("casos: falta objeto")
        casos = {}

    for codigo in CASOS_OBLIGATORIOS:
        errores.extend(_validar_caso(codigo, casos.get(codigo)))

    tags = []
    for codigo in ("R1", "R2"):
        caso = casos.get(codigo)
        if isinstance(caso, dict) and _texto(caso.get("ritual_tag")):
            tags.append(str(caso["ritual_tag"]).strip())
    if len(tags) == 2 and tags[0] == tags[1]:
        errores.append("R1/R2: deben cubrir dos tags rituales distintos")

    mando_disponible = sesion.get("mando_disponible") is True
    if mando_disponible:
        errores.extend(_validar_caso(CASO_MANDO, casos.get(CASO_MANDO)))
        g1 = casos.get(CASO_MANDO)
        if isinstance(g1, dict) and "mando" not in str(g1.get("entrada", "")).lower():
            errores.append("G1.entrada: debe registrar mando físico")
    elif not _texto(sesion.get("motivo_sin_mando")):
        errores.append(
            "sesion.motivo_sin_mando: obligatorio cuando G1 no se ejecuta"
        )

    return {
        "estado": "completo" if not errores else "pendiente_datos",
        "errores": errores,
        "casos_obligatorios": list(CASOS_OBLIGATORIOS),
        "mando_requerido": mando_disponible,
    }


def generar_markdown(registro: dict[str, Any], evaluacion: dict[str, Any]) -> str:
    sesion = registro.get("sesion", {})
    casos = registro.get("casos", {})
    lineas = [
        "# Registro de playtest de doctrinas · #921",
        "",
        f"- Fecha: {sesion.get('fecha', '')}",
        f"- Build/SHA: {sesion.get('build_sha', '')}",
        f"- Plataforma: {sesion.get('plataforma', '')}",
        f"- Resolución: {sesion.get('resolucion', '')}",
        f"- Probador: {sesion.get('probador', '')}",
        f"- Estado de completitud: **{evaluacion.get('estado', 'pendiente_datos')}**",
        "",
        "> Este estado solo indica completitud del registro humano; no aprueba balance.",
        "",
        "| Caso | Doctrina | Ritual/tag | Red. movimiento | Entrada | Comprensión | Decisión | Coste | Utilidad |",
        "| --- | --- | --- | --- | --- | ---: | ---: | ---: | ---: |",
    ]
    codigos = list(CASOS_OBLIGATORIOS)
    if sesion.get("mando_disponible") is True:
        codigos.append(CASO_MANDO)
    for codigo in codigos:
        caso = casos.get(codigo, {})
        lineas.append(
            "| {codigo} | {doctrina} | {tag} | {rm} | {entrada} | {comprension} | "
            "{decision} | {coste} | {utilidad} |".format(
                codigo=codigo,
                doctrina=caso.get("doctrina", ""),
                tag=caso.get("ritual_tag", ""),
                rm="sí" if caso.get("reduccion_movimiento") else "no",
                entrada=caso.get("entrada", ""),
                comprension=caso.get("comprension", ""),
                decision=caso.get("decision_tactica", ""),
                coste=caso.get("coste_ventana", ""),
                utilidad=caso.get("utilidad", ""),
            )
        )

    lineas.extend(["", "## Observaciones humanas", ""])
    for codigo in codigos:
        caso = casos.get(codigo, {})
        lineas.extend(
            [
                f"### {codigo} · {caso.get('doctrina', '')}",
                "",
                f"- Frecuencia: {caso.get('frecuencia', '')}",
                f"- Dominancia: {caso.get('dominante', '')}",
                f"- Feedback: {caso.get('feedback', '')}",
                f"- Incidencias: {caso.get('incidencias', '')}",
                f"- Comentario: {caso.get('comentario', '')}",
                "",
            ]
        )

    if sesion.get("mando_disponible") is not True:
        lineas.extend(
            [
                "## Mando físico",
                "",
                "G1 no ejecutado.",
                f"Motivo: {sesion.get('motivo_sin_mando', '')}",
                "",
            ]
        )

    errores = evaluacion.get("errores", [])
    if errores:
        lineas.extend(["## Datos pendientes", ""])
        lineas.extend(f"- {error}" for error in errores)
        lineas.append("")
    return "\n".join(lineas).rstrip() + "\n"


def _leer(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as fichero:
        contenido = json.load(fichero)
    if not isinstance(contenido, dict):
        raise ValueError("la raíz del registro debe ser un objeto JSON")
    return contenido


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("registro", nargs="?", type=Path)
    parser.add_argument("--salida", type=Path, help="guardar informe Markdown")
    parser.add_argument(
        "--plantilla",
        action="store_true",
        help="emitir una plantilla JSON vacía y salir",
    )
    args = parser.parse_args(argv)

    if args.plantilla:
        print(json.dumps(plantilla(), ensure_ascii=False, indent=2))
        return 0
    if args.registro is None:
        parser.error("indica un registro JSON o usa --plantilla")

    try:
        registro = _leer(args.registro)
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"registro inválido: {exc}", file=sys.stderr)
        return 2

    evaluacion = evaluar(registro)
    informe = generar_markdown(registro, evaluacion)
    if args.salida:
        args.salida.write_text(informe, encoding="utf-8")
    else:
        print(informe, end="")

    if evaluacion["errores"]:
        print(
            f"{len(evaluacion['errores'])} dato(s) pendiente(s); no se emite aprobación automática.",
            file=sys.stderr,
        )
        return 2
    print(
        "Registro humano completo; la decisión de balance sigue siendo manual.",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
