#!/usr/bin/env python3
"""Registra el gate humano de onboarding inicial (#272).

Complementa el protocolo espacial de #126. No toca runtime ni interpreta las
respuestas: conserva texto literal y resume checks marcados por el facilitador.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


CHECKS = (
    "participante_nuevo",
    "espacio_identificado",
    "puesto_identificado",
    "primera_accion_identificada",
    "salida_encontrada",
    "tutorial_no_confundido",
    "sin_ayuda_externa",
    "sin_incidencia_bloqueante",
)


def preguntar(prompt: str) -> str:
    while True:
        valor = input(prompt).strip()
        if valor:
            return valor
        print("La respuesta no puede quedar vacía.")


def preguntar_si_no(prompt: str) -> bool:
    while True:
        valor = input(f"{prompt} [s/n]: ").strip().lower()
        if valor in {"s", "si", "sí"}:
            return True
        if valor in {"n", "no"}:
            return False
        print("Responde s o n.")


def evaluar_gate(datos: dict[str, object]) -> dict[str, bool]:
    estado = {
        "participante_nuevo": not bool(datos.get("conocimiento_previo", False)),
        "espacio_identificado": bool(datos.get("espacio_identificado", False)),
        "puesto_identificado": bool(datos.get("puesto_identificado", False)),
        "primera_accion_identificada": bool(datos.get("primera_accion_identificada", False)),
        "salida_encontrada": bool(datos.get("salida_encontrada", False)),
        "tutorial_no_confundido": bool(datos.get("tutorial_no_confundido", False)),
        "sin_ayuda_externa": not bool(datos.get("ayuda_externa", False)),
        "sin_incidencia_bloqueante": not bool(datos.get("incidencia_bloqueante", False)),
    }
    estado["issue_cerrable"] = all(estado[clave] for clave in CHECKS)
    return estado


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    incidencia = str(datos.get("incidencia", "")).strip() or "Ninguna anotada."
    observaciones = str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."
    return f"""# Registro de playtest · onboarding inicial #272

- fecha: {datos['fecha']}
- participante: {datos['participante']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- conocimiento previo: {_si_no(bool(datos['conocimiento_previo']))}

## Respuestas literales

**¿Dónde estás?**

> {datos['respuesta_espacio']}

**¿Cuál es tu puesto?**

> {datos['respuesta_puesto']}

**¿Qué harías primero?**

> {datos['respuesta_accion']}

**¿Por dónde saldrías después?**

> {datos['respuesta_salida']}

**¿El bloque OBJETIVO INICIAL te pareció una instrucción o diálogo de un personaje?**

> {datos['respuesta_tutorial']}

## Checks del facilitador

- identifica Archivo / planta 4 o equivalente: {_si_no(bool(datos['espacio_identificado']))}
- identifica puesto 4-B / SIGA-98: {_si_no(bool(datos['puesto_identificado']))}
- identifica acercarse/abrir SIGA como primera acción: {_si_no(bool(datos['primera_accion_identificada']))}
- encuentra la salida sin ayuda: {_si_no(bool(datos['salida_encontrada']))}
- no confunde tutorial con diálogo: {_si_no(bool(datos['tutorial_no_confundido']))}
- necesitó ayuda externa: {_si_no(bool(datos['ayuda_externa']))}
- incidencia bloqueante reproducible: {_si_no(bool(datos['incidencia_bloqueante']))}

## Resultado

- #272 cerrable con esta evidencia: **{'SÍ' if gate['issue_cerrable'] else 'NO'}**

Para lectura espacial detallada de la salida se conserva el protocolo de #126.
Este registro no sustituye el juicio humano ni convierte CI en evidencia perceptiva.

## Incidencia reproducible

{incidencia}

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest #272 — no explicar espacio, puesto, acción ni salida antes del pase.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "participante": preguntar("Alias del participante: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA (BUILD-INFO.txt): "),
        "conocimiento_previo": preguntar_si_no(
            "¿Conocía previamente el proyecto o este onboarding?"
        ),
    }
    print("\n--- Respuestas del participante ---")
    datos["respuesta_espacio"] = preguntar("¿Dónde estás? ")
    datos["respuesta_puesto"] = preguntar("¿Cuál es tu puesto? ")
    datos["respuesta_accion"] = preguntar("¿Qué harías primero? ")
    datos["respuesta_salida"] = preguntar("¿Por dónde saldrías después? ")
    datos["respuesta_tutorial"] = preguntar(
        "¿OBJETIVO INICIAL te pareció una instrucción o diálogo de un personaje? "
    )
    print("\n--- Checks del facilitador ---")
    datos["espacio_identificado"] = preguntar_si_no("¿Identificó Archivo / planta 4 o equivalente?")
    datos["puesto_identificado"] = preguntar_si_no("¿Identificó 4-B / SIGA-98 como su puesto?")
    datos["primera_accion_identificada"] = preguntar_si_no(
        "¿Identificó acercarse/abrir SIGA como primera acción?"
    )
    datos["salida_encontrada"] = preguntar_si_no("¿Encontró la salida sin ayuda?")
    datos["tutorial_no_confundido"] = preguntar_si_no(
        "¿Distinguió el tutorial de un diálogo normal?"
    )
    datos["ayuda_externa"] = preguntar_si_no("¿Necesitó pistas o explicación externa?")
    datos["incidencia_bloqueante"] = preguntar_si_no(
        "¿Queda una incidencia reproducible bloqueante?"
    )
    datos["incidencia"] = input("Detalle de incidencia (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Registra el gate humano de #272.")
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown. Por defecto: playtest-272-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-272-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
