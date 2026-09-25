#!/usr/bin/env python3
"""Registra el pase humano del sueño para #299/#281.

Conserva respuestas literales y evalúa únicamente checks explícitos introducidos
por el facilitador. No interpreta semánticamente las respuestas.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


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


def preguntar_entero(prompt: str, minimo: int = 0) -> int:
    while True:
        try:
            valor = int(input(prompt).strip())
        except ValueError:
            print("Introduce un número entero.")
            continue
        if valor < minimo:
            print(f"El valor mínimo es {minimo}.")
            continue
        return valor


def evaluar_gate(datos: dict[str, object]) -> dict[str, bool]:
    primero_menos_60 = 0 <= int(datos["segundos_primer_objetivo"]) < 60
    checks = {
        "participante_nuevo": not bool(datos["conocimiento_previo"]),
        "sin_ayuda_primer_objetivo": not bool(datos["ayuda_primer_objetivo"]),
        "primero_menos_60": primero_menos_60,
        "estado_0_2_legible": bool(datos["estado_0_2_legible"]),
        "feedback_1_2": bool(datos["feedback_1_2"]),
        "guia_pendiente_legible": bool(datos["guia_pendiente_legible"]),
        "sin_doble_conteo": bool(datos["sin_doble_conteo"]),
        "transicion_2_2": bool(datos["transicion_2_2"]),
        "transicion_unica": bool(datos["transicion_unica"]),
        "opcional_no_bloquea": bool(datos["opcional_no_bloquea"]),
        "temporizador_alternativo": bool(datos["temporizador_alternativo"]),
        "persistencia_ok": bool(datos["persistencia_ok"]),
        "sin_incidencia_invalidante": not bool(datos["incidencia_invalidante"]),
    }
    checks["listo_para_valorar_cierre"] = all(checks.values())
    return checks


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def _estado(valor: bool) -> str:
    return "CUMPLE" if valor else "PENDIENTE"


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    incidencia = str(datos.get("incidencia", "")).strip() or "Ninguna anotada."
    observaciones = str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."

    return f"""# Registro de playtest humano · #299

- fecha: {datos['fecha']}
- participante: {datos['participante']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- conocimiento previo del sueño: {_si_no(bool(datos['conocimiento_previo']))}

## Recorrido observado

> {datos['relato']}

Tiempo hasta el primer objetivo válido: **{datos['segundos_primer_objetivo']} s**

## Checks del facilitador

- hubo ayuda directa antes del primer objetivo: {_si_no(bool(datos['ayuda_primer_objetivo']))}
- 0/2 se percibió como progreso pendiente: {_si_no(bool(datos['estado_0_2_legible']))}
- feedback 1/2 fue claro: {_si_no(bool(datos['feedback_1_2']))}
- gato/señal ambiental orientó a contenido pendiente: {_si_no(bool(datos['guia_pendiente_legible']))}
- repetir/reentrar no sumó dos veces: {_si_no(bool(datos['sin_doble_conteo']))}
- segundo objetivo produjo 2/2 y transición automática: {_si_no(bool(datos['transicion_2_2']))}
- transición ocurrió una sola vez: {_si_no(bool(datos['transicion_unica']))}
- ruta opcional fallable no bloqueó: {_si_no(bool(datos['opcional_no_bloquea']))}
- temporizador se entendió como alternativa, no ruta normal: {_si_no(bool(datos['temporizador_alternativo']))}
- guardar/cerrar/reabrir mantuvo estado coherente: {_si_no(bool(datos['persistencia_ok']))}
- incidencia reproducible invalidante: {_si_no(bool(datos['incidencia_invalidante']))}
- detalle: {incidencia}

## Resumen del gate

- participante nuevo: **{_estado(gate['participante_nuevo'])}**
- primer objetivo sin ayuda: **{_estado(gate['sin_ayuda_primer_objetivo'])}**
- primer objetivo en <60 s: **{_estado(gate['primero_menos_60'])}**
- estado 0/2 legible: **{_estado(gate['estado_0_2_legible'])}**
- feedback 1/2 claro: **{_estado(gate['feedback_1_2'])}**
- guía hacia pendiente legible: **{_estado(gate['guia_pendiente_legible'])}**
- sin doble conteo: **{_estado(gate['sin_doble_conteo'])}**
- 2/2 resuelve automáticamente: **{_estado(gate['transicion_2_2'])}**
- transición única: **{_estado(gate['transicion_unica'])}**
- opcional no bloquea: **{_estado(gate['opcional_no_bloquea'])}**
- temporizador alternativo: **{_estado(gate['temporizador_alternativo'])}**
- persistencia posterior correcta: **{_estado(gate['persistencia_ok'])}**
- sin incidencia invalidante: **{_estado(gate['sin_incidencia_invalidante'])}**
- listo para valorar cierre de #299: **{'SÍ' if gate['listo_para_valorar_cierre'] else 'NO'}**

Este resumen deriva sólo de los datos/checks introducidos por el facilitador.

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest #299 — no explicar objetivos antes del primer progreso.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "participante": preguntar("Alias del participante: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA: "),
        "conocimiento_previo": preguntar_si_no(
            "¿Conocía previamente el sueño, su layout o qué acciones cuentan?"
        ),
    }
    datos["relato"] = preguntar(
        "Describe literalmente qué hizo/dijo el participante hasta terminar la noche: "
    )
    datos["segundos_primer_objetivo"] = preguntar_entero(
        "Segundos hasta el primer objetivo válido: "
    )
    datos["ayuda_primer_objetivo"] = preguntar_si_no(
        "¿Hubo ayuda directa antes de completar el primer objetivo?"
    )
    datos["estado_0_2_legible"] = preguntar_si_no(
        "¿El 0/2 se percibió como progreso pendiente?"
    )
    datos["feedback_1_2"] = preguntar_si_no("¿El feedback 1/2 fue claro?")
    datos["guia_pendiente_legible"] = preguntar_si_no(
        "¿Gato/señal ambiental orientó a contenido pendiente sin parecer una salida?"
    )
    datos["sin_doble_conteo"] = preguntar_si_no(
        "¿Repetir/reentrar el primer objetivo evitó sumar de nuevo?"
    )
    datos["transicion_2_2"] = preguntar_si_no(
        "¿El segundo objetivo produjo 2/2 y transición automática?"
    )
    datos["transicion_unica"] = preguntar_si_no(
        "¿La transición ocurrió una sola vez y sin softlock?"
    )
    datos["opcional_no_bloquea"] = preguntar_si_no(
        "¿Una ruta opcional fallable/abandonable dejó aún una salida válida?"
    )
    datos["temporizador_alternativo"] = preguntar_si_no(
        "¿El temporizador, si apareció, se entendió como alternativa y no ruta normal?"
    )
    datos["persistencia_ok"] = preguntar_si_no(
        "¿Guardar/cerrar/reabrir mantuvo un estado posterior al sueño coherente?"
    )
    datos["incidencia_invalidante"] = preguntar_si_no(
        "¿Queda una incidencia reproducible que invalide el pase?"
    )
    datos["incidencia"] = input("Detalle de incidencia (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra evidencia humana del gate de sueño #299."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown de salida. Por defecto: playtest-299-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-299-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
