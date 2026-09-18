#!/usr/bin/env python3
"""Registra el playtest físico de mando de los bolos de pasillo (#159)."""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


CHECKS = (
    "mando_detectado",
    "entrada_solo_mando",
    "stick_apunta",
    "cruceta_apunta",
    "sin_deriva",
    "boton_principal_lanza",
    "dos_lanzamientos",
    "boton_secundario_abandona",
    "oficina_restaurada",
    "repeticion_funciona",
    "sin_incidencia_reproducible",
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
    estado["listo_para_cerrar_mando"] = all(estado.values())
    return estado


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def _estado(valor: bool) -> str:
    return "CUMPLE" if valor else "PENDIENTE"


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    incidencia = str(datos.get("incidencia", "")).strip() or "Ninguna anotada."
    observaciones = str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."

    return f"""# Registro de playtest físico de mando · #159

- fecha: {datos['fecha']}
- participante: {datos['participante']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- mando: {datos['mando_modelo']}
- familia: {datos['mando_familia']}
- conexión: {datos['conexion']}
- controles remapeados: {_si_no(bool(datos['remapeado']))}

## Checks

- mando físico detectado: {_si_no(bool(datos['mando_detectado']))}
- entrada usando solo mando: {_si_no(bool(datos['entrada_solo_mando']))}
- stick izquierdo apunta en ambos sentidos: {_si_no(bool(datos['stick_apunta']))}
- cruceta apunta en ambos sentidos: {_si_no(bool(datos['cruceta_apunta']))}
- sin deriva apreciable en reposo: {_si_no(bool(datos['sin_deriva']))}
- botón principal carga y lanza: {_si_no(bool(datos['boton_principal_lanza']))}
- dos lanzamientos completados y resultado alcanzado: {_si_no(bool(datos['dos_lanzamientos']))}
- botón secundario abandona: {_si_no(bool(datos['boton_secundario_abandona']))}
- abandono restaura la oficina: {_si_no(bool(datos['oficina_restaurada']))}
- repetición con mando funciona: {_si_no(bool(datos['repeticion_funciona']))}
- sin incidencia reproducible bloqueante: {_si_no(bool(datos['sin_incidencia_reproducible']))}

## Resumen del gate

{chr(10).join(f"- {clave.replace('_', ' ')}: **{_estado(gate[clave])}**" for clave in CHECKS)}

- gate físico de mando de #159: **{'CUMPLE' if gate['listo_para_cerrar_mando'] else 'PENDIENTE'}**

El resumen deriva únicamente de los checks registrados. No simula un mando físico ni interpreta las observaciones.

## Incidencia reproducible

{incidencia}

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest #159 — usar mando físico y no teclado/ratón durante el pase.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "participante": preguntar("Alias del participante: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA (BUILD-INFO.txt): "),
        "mando_modelo": preguntar("Modelo/nombre detectado del mando: "),
        "mando_familia": preguntar("Familia (Xbox/PlayStation/Nintendo/otro): "),
        "conexion": preguntar("Conexión (cable/Bluetooth/otra): "),
        "remapeado": preguntar_si_no("¿Se usó un remapeo distinto de los controles por defecto?"),
    }

    preguntas = (
        ("mando_detectado", "¿El mando físico fue detectado?"),
        ("entrada_solo_mando", "¿Se pudo entrar en los bolos usando solo el mando?"),
        ("stick_apunta", "¿El stick izquierdo apuntó a izquierda y derecha?"),
        ("cruceta_apunta", "¿La cruceta apuntó a izquierda y derecha?"),
        ("sin_deriva", "¿El apuntado quedó estable con el mando en reposo?"),
        ("boton_principal_lanza", "¿Mantener/soltar el botón principal cargó y lanzó?"),
        ("dos_lanzamientos", "¿Se completaron dos lanzamientos y apareció el resultado?"),
        ("boton_secundario_abandona", "¿El botón secundario permitió abandonar?"),
        ("oficina_restaurada", "¿Abandonar devolvió correctamente a la oficina?"),
        ("repeticion_funciona", "¿Se pudo volver a entrar y jugar de nuevo con mando?"),
        (
            "sin_incidencia_reproducible",
            "¿No queda ninguna incidencia reproducible que bloquee completar el flujo?",
        ),
    )
    print("\n--- Checks del pase ---")
    for clave, pregunta in preguntas:
        datos[clave] = preguntar_si_no(pregunta)

    datos["incidencia"] = input("Detalle de incidencia (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra evidencia de playtest físico de mando para los bolos de #159."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown de salida. Por defecto: playtest-159-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-159-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
