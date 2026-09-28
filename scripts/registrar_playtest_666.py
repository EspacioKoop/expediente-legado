#!/usr/bin/env python3
"""Registra el gate humano pendiente del chat corporativo OS98 (#666).

No simula input, percepción ni eventos de Jornada. Conserva resultados
explícitos de una sesión humana sobre una build identificable.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


VIEWPORT_CANONICO = "1920x1080"

ESCENARIOS = (
    (
        "apertura",
        "Apertura y presencia",
        (
            ("descubrible", "Mensajería interna se encuentra desde el shell sin consola"),
            ("presencia_legible", "canal, nicks y estados de presencia se distinguen con claridad"),
            ("foco_inicial", "al abrir la aplicación existe un foco útil y visible"),
        ),
    ),
    (
        "navegacion",
        "Canales y navegación",
        (
            ("teclado_ok", "se recorren canales, mensajes y acciones con teclado"),
            ("mando_ok", "se recorre el mismo flujo con mando físico"),
            ("cancelar_ok", "volver/cancelar no deja el foco atrapado"),
            ("escala_ok", "el contenido sigue legible al recorrer historial y canales"),
        ),
    ),
    (
        "respuestas",
        "Respuestas cerradas y persistencia",
        (
            ("sin_texto_libre", "no aparece entrada de texto libre"),
            ("respuesta_clara", "una respuesta cerrada se entiende y confirma sin ambigüedad"),
            ("persiste", "cerrar/reabrir conserva la respuesta elegida para la misma partida"),
            ("ignorar_no_bloquea", "ignorar el chat no bloquea el recorrido principal"),
        ),
    ),
    (
        "incidencia",
        "Canal temporal de impresora",
        (
            ("evento_real", "impresora_atascada fue publicado por una Jornada real de la build"),
            ("canal_aparece", "el canal temporal aparece únicamente después de ese evento"),
            ("mensajes_legibles", "la conversación de incidencia resulta legible y diferenciada"),
            ("sin_progreso_paralelo", "la incidencia no concede ni bloquea progreso de campaña"),
        ),
    ),
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


def _normalizar_viewport(valor: str) -> str:
    return valor.lower().replace("×", "x").replace(" ", "")


def evaluar_gate(datos: dict[str, object]) -> dict[str, bool]:
    escenarios = datos["escenarios"]
    assert isinstance(escenarios, dict)

    escenarios_ok = True
    evidencias_ok = True
    for clave, _titulo, checks in ESCENARIOS:
        registro = escenarios[clave]
        assert isinstance(registro, dict)
        escenarios_ok = escenarios_ok and all(
            bool(registro[nombre]) for nombre, _descripcion in checks
        )
        evidencias_ok = evidencias_ok and bool(str(registro.get("evidencia", "")).strip())

    viewport_ok = _normalizar_viewport(str(datos["viewport"])) == VIEWPORT_CANONICO
    dispositivos_ok = bool(datos["teclado_real"]) and bool(datos["mando_fisico"])
    reduccion_ok = bool(datos["reduccion_movimiento_probada"])

    return {
        "viewport_ok": viewport_ok,
        "dispositivos_ok": dispositivos_ok,
        "reduccion_ok": reduccion_ok,
        "escenarios_ok": escenarios_ok,
        "evidencias_ok": evidencias_ok,
        "listo_para_cerrar": all(
            (viewport_ok, dispositivos_ok, reduccion_ok, escenarios_ok, evidencias_ok)
        ),
    }


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    escenarios = datos["escenarios"]
    assert isinstance(escenarios, dict)

    bloques: list[str] = []
    for clave, titulo, checks in ESCENARIOS:
        registro = escenarios[clave]
        assert isinstance(registro, dict)
        lineas = [f"### {titulo}", ""]
        for nombre, descripcion in checks:
            lineas.append(f"- {descripcion}: {_si_no(bool(registro[nombre]))}")
        lineas.extend(
            [
                "- evidencia: "
                + (str(registro.get("evidencia", "")).strip() or "No indicada."),
                "- notas: "
                + (str(registro.get("notas", "")).strip() or "Sin observaciones."),
                "",
            ]
        )
        bloques.append("\n".join(lineas))

    incidencias = str(datos.get("incidencias", "")).strip() or "Ninguna anotada."
    observaciones = (
        str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."
    )

    return f"""# Registro de playtest de Mensajería interna · #666

- fecha: {datos['fecha']}
- tester/facilitador: {datos['tester']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- viewport: `{datos['viewport']}`
- teclado real probado: {_si_no(bool(datos['teclado_real']))}
- mando físico real probado: {_si_no(bool(datos['mando_fisico']))}
- modelo de mando: {datos['mando_modelo']}
- reducción de movimiento probada: {_si_no(bool(datos['reduccion_movimiento_probada']))}

## Escenarios

{''.join(bloques)}## Resumen del gate

- viewport canónico `1920×1080`: **{_estado(gate['viewport_ok'])}**
- teclado + mando físico probados: **{_estado(gate['dispositivos_ok'])}**
- reducción de movimiento probada: **{_estado(gate['reduccion_ok'])}**
- recorrido funcional y perceptivo completo: **{_estado(gate['escenarios_ok'])}**
- evidencia por los cuatro escenarios: **{_estado(gate['evidencias_ok'])}**
- listo para valorar cierre de #666: **{'SÍ' if gate['listo_para_cerrar'] else 'NO'}**

El resultado deriva solo de checks introducidos durante una sesión humana.
En particular, el canal de impresora no puede darse por probado con un fixture:
`impresora_atascada` debe proceder de una Jornada real de esta build.

## Incidencias

{incidencias}

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest Mensajería interna #666 — usar una build identificable.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "tester": preguntar("Tester/facilitador: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA: "),
        "viewport": preguntar("Viewport (esperado 1920x1080): "),
        "teclado_real": preguntar_si_no("¿Se ha probado con teclado real?"),
        "mando_fisico": preguntar_si_no("¿Se ha probado con mando físico real?"),
        "mando_modelo": preguntar("Modelo de mando (o 'desconocido'): "),
        "reduccion_movimiento_probada": preguntar_si_no(
            "¿Se repitió el recorrido con reducción de movimiento?"
        ),
        "escenarios": {},
    }

    escenarios: dict[str, dict[str, object]] = {}
    for clave, titulo, checks in ESCENARIOS:
        print(f"\n--- {titulo} ---")
        registro: dict[str, object] = {}
        for nombre, descripcion in checks:
            registro[nombre] = preguntar_si_no(f"¿{descripcion.capitalize()}?")
        registro["evidencia"] = preguntar("Evidencia (captura, vídeo, ruta o URL): ")
        registro["notas"] = input("Notas (opcional): ").strip()
        escenarios[clave] = registro
    datos["escenarios"] = escenarios

    print("\n--- Cierre ---")
    datos["incidencias"] = input("Incidencias reproducibles (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra evidencia del gate humano pendiente de #666."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown de salida. Por defecto: playtest-666-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-666-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
