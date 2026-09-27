#!/usr/bin/env python3
"""Registra el playtest humano pendiente de #936.

No puntúa religiones ni decide balance automáticamente. Conserva observaciones
humanas sobre claridad, coste y utilidad contextual de las reglas ya implementadas.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path

ESCENARIOS = (
    ("base", "Combate base · sin compromiso religioso"),
    ("no_iniciar", "Compromiso · no iniciar agresión"),
    ("tregua", "Compromiso · tregua mutua"),
)

CHECKS_COMUNES = (
    ("hud_legible", "el HUD permite entender el estado activo"),
    ("combate_completo", "el combate conserva sus reglas base fuera de la restricción"),
)

CHECKS_COMPROMISO = (
    ("claridad", "se entiende por qué la acción ofensiva está limitada"),
    ("coste", "se percibe un coste o limitación real"),
    ("cambio_decision", "la regla cambia una decisión táctica real"),
    ("utilidad_contextual", "la utilidad depende del contexto y no parece un bonus pasivo"),
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


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def _estado(valor: bool) -> str:
    return "CUMPLE" if valor else "PENDIENTE"


def evaluar_registro(datos: dict[str, object]) -> dict[str, bool]:
    escenarios = datos.get("escenarios", {})
    if not isinstance(escenarios, dict):
        escenarios = {}

    matriz_completa = True
    evidencias_ok = True
    comunes_ok = True
    compromisos_ok = True

    for clave, _titulo in ESCENARIOS:
        registro = escenarios.get(clave, {})
        if not isinstance(registro, dict):
            matriz_completa = evidencias_ok = comunes_ok = compromisos_ok = False
            continue
        evidencias_ok = evidencias_ok and bool(str(registro.get("evidencia", "")).strip())
        comunes_ok = comunes_ok and all(
            bool(registro.get(nombre, False)) for nombre, _ in CHECKS_COMUNES
        )
        if clave != "base":
            compromisos_ok = compromisos_ok and all(
                bool(registro.get(nombre, False)) for nombre, _ in CHECKS_COMPROMISO
            )

    teclado_ok = bool(datos.get("matriz_teclado_completa", False))
    reduccion_ok = bool(datos.get("reduccion_movimiento_equivalente", False))
    matriz_completa = matriz_completa and len(escenarios) >= len(ESCENARIOS)

    return {
        "matriz_completa": matriz_completa,
        "evidencias_ok": evidencias_ok,
        "comunes_ok": comunes_ok,
        "compromisos_ok": compromisos_ok,
        "teclado_ok": teclado_ok,
        "reduccion_ok": reduccion_ok,
        "listo_para_valorar_cierre": all(
            (
                matriz_completa,
                evidencias_ok,
                comunes_ok,
                compromisos_ok,
                teclado_ok,
                reduccion_ok,
            )
        ),
    }


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_registro(datos)
    escenarios = datos["escenarios"]
    assert isinstance(escenarios, dict)

    bloques: list[str] = []
    for clave, titulo in ESCENARIOS:
        registro = escenarios[clave]
        assert isinstance(registro, dict)
        lineas = [f"### {titulo}", ""]
        for nombre, descripcion in CHECKS_COMUNES:
            lineas.append(f"- {descripcion}: {_si_no(bool(registro[nombre]))}")
        if clave != "base":
            for nombre, descripcion in CHECKS_COMPROMISO:
                lineas.append(f"- {descripcion}: {_si_no(bool(registro[nombre]))}")
        lineas.extend(
            [
                f"- evidencia: {str(registro['evidencia']).strip()}",
                "- observaciones: "
                + (str(registro.get("observaciones", "")).strip() or "Ninguna anotada."),
                "",
            ]
        )
        bloques.append("\n".join(lineas))

    return f"""# Registro de playtest · religión y conflicto #936

- fecha: {datos['fecha']}
- tester/facilitador: {datos['tester']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- matriz completa con teclado: {_si_no(bool(datos['matriz_teclado_completa']))}
- reducción de movimiento equivalente: {_si_no(bool(datos['reduccion_movimiento_equivalente']))}
- muestra adicional con mando físico: {_si_no(bool(datos.get('muestra_mando_fisico', False)))}

## Matriz

{''.join(bloques)}
## Gate humano

- tres escenarios registrados: **{_estado(gate['matriz_completa'])}**
- evidencia por escenario: **{_estado(gate['evidencias_ok'])}**
- HUD y combate base legibles: **{_estado(gate['comunes_ok'])}**
- claridad, coste y utilidad contextual: **{_estado(gate['compromisos_ok'])}**
- matriz con teclado: **{_estado(gate['teclado_ok'])}**
- reducción de movimiento equivalente: **{_estado(gate['reduccion_ok'])}**
- listo para valorar cierre de #936:
  **{'SÍ' if gate['listo_para_valorar_cierre'] else 'NO'}**

Este gate comprueba completitud de observaciones humanas. No puntúa tradiciones,
no compara credos y no declara automáticamente que una regla esté bien balanceada.

## Observaciones generales

{str(datos.get('observaciones_generales', '')).strip() or 'Sin observaciones adicionales.'}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest #936 — usar una build identificable.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "tester": preguntar("Tester/facilitador: "),
        "plataforma": preguntar("Plataforma: "),
        "build_sha": preguntar("Build SHA: "),
        "escenarios": {},
    }

    escenarios: dict[str, dict[str, object]] = {}
    for clave, titulo in ESCENARIOS:
        print(f"\n--- {titulo} ---")
        registro: dict[str, object] = {}
        for nombre, descripcion in CHECKS_COMUNES:
            registro[nombre] = preguntar_si_no(f"¿{descripcion.capitalize()}?")
        if clave != "base":
            for nombre, descripcion in CHECKS_COMPROMISO:
                registro[nombre] = preguntar_si_no(f"¿{descripcion.capitalize()}?")
        registro["evidencia"] = preguntar("Captura/vídeo/log de evidencia (ruta o URL): ")
        registro["observaciones"] = input("Observaciones reproducibles (opcional): ").strip()
        escenarios[clave] = registro
    datos["escenarios"] = escenarios

    print("\n--- Cierre transversal ---")
    datos["matriz_teclado_completa"] = preguntar_si_no(
        "¿Se completaron los tres escenarios con teclado?"
    )
    datos["reduccion_movimiento_equivalente"] = preguntar_si_no(
        "¿Se repitió una muestra con reducción de movimiento sin perder información?"
    )
    datos["muestra_mando_fisico"] = preguntar_si_no(
        "¿Se hizo además alguna muestra con mando físico?"
    )
    datos["observaciones_generales"] = input(
        "Observaciones generales (opcional): "
    ).strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra el playtest humano de claridad/coste/utilidad pendiente de #936."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown de salida. Por defecto: playtest-936-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-936-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
