#!/usr/bin/env python3
"""Registra un playtest humano reproducible para el gate de cinemáticas #395.

El script no intenta interpretar semánticamente las respuestas. Conserva el texto
literal del participante y resume únicamente checks explícitos del facilitador.
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


def preguntar_opcion(prompt: str, opciones: tuple[str, ...]) -> str:
    etiquetas = "/".join(opciones)
    while True:
        valor = input(f"{prompt} [{etiquetas}]: ").strip().lower()
        if valor in opciones:
            return valor
        print(f"Elige una de: {', '.join(opciones)}")


def evaluar_gate(datos: dict[str, object]) -> dict[str, bool]:
    comprension_entrada = all(
        bool(datos[clave])
        for clave in (
            "entrada_lugar_correcto",
            "entrada_rol_correcto",
            "entrada_tarea_correcta",
        )
    )
    comprension_trayecto = bool(datos["trayecto_continuidad_correcta"])
    comprension_sueno = bool(datos["sueno_causa_correcta"])
    participante_nuevo = not bool(datos["conocimiento_previo"])
    ritmo_sin_bloqueo = not bool(datos["problema_reproducible"])

    return {
        "participante_nuevo": participante_nuevo,
        "comprension_entrada": comprension_entrada,
        "comprension_trayecto": comprension_trayecto,
        "comprension_sueno": comprension_sueno,
        "ritmo_sin_bloqueo": ritmo_sin_bloqueo,
        "listo_para_valorar_cierre": all(
            (
                participante_nuevo,
                comprension_entrada,
                comprension_trayecto,
                comprension_sueno,
                ritmo_sin_bloqueo,
            )
        ),
    }


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def _estado(valor: bool) -> str:
    return "CUMPLE" if valor else "PENDIENTE"


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    incidencia = str(datos.get("incidencia", "")).strip() or "Ninguna anotada."
    observaciones = str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."

    return f"""# Registro de playtest humano · #395

- fecha: {datos['fecha']}
- participante: {datos['participante']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- conocimiento previo del proyecto/respuestas: {_si_no(bool(datos['conocimiento_previo']))}

## Entrada / oficina

**¿Dónde crees que estás?**

> {datos['entrada_lugar_respuesta']}

**¿Quién eres o qué papel tienes aquí?**

> {datos['entrada_rol_respuesta']}

**¿Qué crees que se espera que hagas ahora?**

> {datos['entrada_tarea_respuesta']}

Checks del facilitador:

- lugar comprendido: {_si_no(bool(datos['entrada_lugar_correcto']))}
- rol comprendido: {_si_no(bool(datos['entrada_rol_correcto']))}
- tarea inmediata comprendida: {_si_no(bool(datos['entrada_tarea_correcta']))}
- ritmo percibido: {datos['entrada_ritmo']}

## Oficina → trayecto

**¿De dónde vienes y a dónde crees que te está llevando esta transición?**

> {datos['trayecto_continuidad_respuesta']}

Checks del facilitador:

- continuidad archivo/oficina → salida/trayecto comprendida: {_si_no(bool(datos['trayecto_continuidad_correcta']))}
- ritmo percibido: {datos['trayecto_ritmo']}
- sincronía audiovisual percibida: {datos['trayecto_sincronia']}

## Casa → sueño

**¿Qué acción acaba de provocar este cambio de espacio?**

> {datos['sueno_causa_respuesta']}

Checks del facilitador:

- relación cama/dormir → sueño comprendida: {_si_no(bool(datos['sueno_causa_correcta']))}
- ritmo percibido: {datos['sueno_ritmo']}

## Incidencias

- problema reproducible de ritmo/confusión: {_si_no(bool(datos['problema_reproducible']))}
- detalle: {incidencia}

## Resumen del gate

- participante nuevo: **{_estado(gate['participante_nuevo'])}**
- comprensión entrada/oficina: **{_estado(gate['comprension_entrada'])}**
- comprensión oficina → trayecto: **{_estado(gate['comprension_trayecto'])}**
- comprensión casa → sueño: **{_estado(gate['comprension_sueno'])}**
- sin bloqueo reproducible de ritmo/confusión: **{_estado(gate['ritmo_sin_bloqueo'])}**
- listo para valorar cierre de #395: **{'SÍ' if gate['listo_para_valorar_cierre'] else 'NO'}**

Este resumen no interpreta las respuestas por IA: deriva únicamente de los checks introducidos por el facilitador.

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest #395 — registrar respuestas literales antes de explicar nada al tester.\n")

    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "participante": preguntar("Alias del participante: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA (BUILD-INFO.txt): "),
        "conocimiento_previo": preguntar_si_no(
            "¿Conocía previamente el proyecto o las respuestas esperadas?"
        ),
    }

    print("\n--- Entrada / oficina ---")
    datos["entrada_lugar_respuesta"] = preguntar("¿Dónde crees que estás? ")
    datos["entrada_rol_respuesta"] = preguntar("¿Quién eres o qué papel tienes aquí? ")
    datos["entrada_tarea_respuesta"] = preguntar(
        "¿Qué crees que se espera que hagas ahora? "
    )
    datos["entrada_ritmo"] = preguntar_opcion(
        "Ritmo de entrada/oficina",
        ("bien", "rapida", "larga", "confusa"),
    )

    print("\nChecks del facilitador (después de registrar las respuestas):")
    datos["entrada_lugar_correcto"] = preguntar_si_no("¿Comprendió el lugar?")
    datos["entrada_rol_correcto"] = preguntar_si_no("¿Comprendió el rol?")
    datos["entrada_tarea_correcta"] = preguntar_si_no("¿Comprendió la tarea inmediata?")

    print("\n--- Oficina → trayecto ---")
    datos["trayecto_continuidad_respuesta"] = preguntar(
        "¿De dónde vienes y a dónde crees que te está llevando esta transición? "
    )
    datos["trayecto_ritmo"] = preguntar_opcion(
        "Ritmo de oficina→trayecto",
        ("bien", "rapida", "larga", "confusa"),
    )
    datos["trayecto_sincronia"] = preguntar_opcion(
        "Sincronía audiovisual de oficina→trayecto",
        ("bien", "desfasada", "confusa"),
    )
    datos["trayecto_continuidad_correcta"] = preguntar_si_no(
        "¿Comprendió la continuidad archivo/oficina → salida/trayecto?"
    )

    print("\n--- Casa → sueño ---")
    datos["sueno_causa_respuesta"] = preguntar(
        "¿Qué acción acaba de provocar este cambio de espacio? "
    )
    datos["sueno_ritmo"] = preguntar_opcion(
        "Ritmo de casa→sueño",
        ("bien", "rapida", "larga", "confusa"),
    )
    datos["sueno_causa_correcta"] = preguntar_si_no(
        "¿Comprendió la relación cama/dormir → sueño?"
    )

    print("\n--- Cierre ---")
    datos["problema_reproducible"] = preguntar_si_no(
        "¿Queda un problema reproducible de ritmo o confusión?"
    )
    datos["incidencia"] = input("Detalle de incidencia (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra evidencia humana del gate de cinemáticas #395."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown de salida. Por defecto: playtest-395-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-395-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
