#!/usr/bin/env python3
"""Registra el pase humano pendiente del archivado manual (#157).

No automatiza la experiencia ni sustituye un mando físico. Solo conserva
respuestas del tester y calcula el gate a partir de checks explícitos.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


CHECKS = (
    "dos_carpetas",
    "recogida_clara",
    "error_no_destruye",
    "correccion_funciona",
    "siguiente_carpeta",
    "abandono_persiste",
    "jornada_continua",
    "rehidratacion_comprensible",
    "precision_visible",
    "mando_fisico",
    "foco_mando",
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
    estado = {clave: bool(datos.get(clave, False)) for clave in CHECKS}
    estado["listo_para_cerrar_gate_humano"] = all(estado.values())
    return estado


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def _estado(valor: bool) -> str:
    return "CUMPLE" if valor else "PENDIENTE"


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    incidencia = str(datos.get("incidencia", "")).strip() or "Ninguna anotada."
    observaciones = str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."

    return f"""# Registro de playtest humano · archivado manual #157

- fecha: {datos['fecha']}
- participante: {datos['participante']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- mando: {datos['mando_modelo']}
- conexión: {datos['conexion']}

## Checks del recorrido

- bandeja con al menos dos carpetas conocidas: {_si_no(bool(datos['dos_carpetas']))}
- recoger la carpeta resulta comprensible: {_si_no(bool(datos['recogida_clara']))}
- un destino incorrecto no destruye la carpeta: {_si_no(bool(datos['error_no_destruye']))}
- corregir el destino funciona: {_si_no(bool(datos['correccion_funciona']))}
- aparece/continúa la siguiente carpeta: {_si_no(bool(datos['siguiente_carpeta']))}
- salir con pendiente persiste el abandono: {_si_no(bool(datos['abandono_persiste']))}
- la jornada continúa al trayecto sin bloqueo: {_si_no(bool(datos['jornada_continua']))}
- reconstruir la sesión del mismo día resulta comprensible: {_si_no(bool(datos['rehidratacion_comprensible']))}
- precisión/rango final se entiende sin sugerir recompensa: {_si_no(bool(datos['precision_visible']))}
- pase realizado con mando físico real: {_si_no(bool(datos['mando_fisico']))}
- recoger/colocar/salir conservan foco y navegación con mando: {_si_no(bool(datos['foco_mando']))}
- sin incidencia reproducible bloqueante: {_si_no(bool(datos['sin_incidencia_bloqueante']))}

## Resumen

{chr(10).join(f"- {clave.replace('_', ' ')}: **{_estado(gate[clave])}**" for clave in CHECKS)}

- gate humano de #157: **{'CUMPLE' if gate['listo_para_cerrar_gate_humano'] else 'PENDIENTE'}**

Este resultado deriva solo de respuestas del pase humano. CI y este script no
simulan comprensión, gamefeel ni hardware físico.

## Incidencia reproducible

{incidencia}

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest #157 — usar una build identificable y mando físico para el gate final.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "participante": preguntar("Alias del participante: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA (BUILD-INFO.txt): "),
        "mando_modelo": preguntar("Modelo/nombre detectado del mando: "),
        "conexion": preguntar("Conexión (cable/Bluetooth/otra): "),
    }
    preguntas = (
        ("dos_carpetas", "¿La bandeja contiene al menos dos carpetas conocidas?"),
        ("recogida_clara", "¿Se entiende cómo recoger la carpeta?"),
        ("error_no_destruye", "¿Un destino incorrecto mantiene la carpeta transportable?"),
        ("correccion_funciona", "¿Se puede corregir y colocar en el destino correcto?"),
        ("siguiente_carpeta", "¿La siguiente carpeta continúa el flujo correctamente?"),
        ("abandono_persiste", "¿Salir con una pendiente deja el abandono persistido?"),
        ("jornada_continua", "¿La jornada continúa al trayecto sin bloquearse?"),
        ("rehidratacion_comprensible", "¿Una sesión reconstruida conserva pendientes/intentos de forma comprensible?"),
        ("precision_visible", "¿El cierre comunica precisión/rango sin sugerir recompensa sistémica?"),
        ("mando_fisico", "¿El pase se realizó con un mando físico real?"),
        ("foco_mando", "¿Recoger, colocar y salir funcionan con foco/navegación de mando?"),
        ("sin_incidencia_bloqueante", "¿No queda una incidencia reproducible que bloquee completar el flujo?"),
    )
    print("\n--- Checks ---")
    for clave, pregunta in preguntas:
        datos[clave] = preguntar_si_no(pregunta)
    datos["incidencia"] = input("Detalle de incidencia (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra evidencia del pase humano pendiente de #157."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown. Por defecto: playtest-157-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-157-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
