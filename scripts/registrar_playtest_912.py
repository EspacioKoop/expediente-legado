#!/usr/bin/env python3
"""Registra la matriz humana de balance/game feel del Juicio (#912).

No simula combates ni decide balance a partir de números. Conserva medidas y
juicios explícitos del tester, ligados a una build y a evidencia concreta.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


VIEWPORT_CANONICO = "1920x1080"

ENCUENTROS = (
    ("base", "Combate base · sin ritual"),
    ("luna_minotauro", "Luna + Minotauro · Laberinto lunar"),
    ("justicia_duat", "Justicia + Duat · Balanza del Duat"),
    ("fuerza_aquiles", "Fuerza + Aquiles · Talón de la Fuerza"),
    ("sol_maui", "Sol + Māui · Robo del Sol"),
    ("colgado_anansi", "Colgado + Anansi · Nudo suspendido"),
    ("muerte_hidra", "Muerte + Hidra · Retorno de la Hidra"),
)

METRICAS_ENTERAS = (
    ("duracion_segundos", "duración aproximada en segundos"),
    ("determinacion_perdida_jugador", "determinación perdida por el jugador"),
    ("determinacion_perdida_rival", "determinación perdida por el rival"),
    ("ligeros_conectados", "golpes ligeros conectados"),
    ("fuertes_conectados", "golpes fuertes conectados"),
    ("esquivas_utiles", "esquivas útiles"),
    ("interrupciones_contraataques", "interrupciones/contraataques activados"),
)

CHECKS_ENCUENTRO = (
    ("ligero_tiene_funcion", "el ataque ligero conserva una función reconocible"),
    ("fuerte_tiene_funcion", "el ataque fuerte conserva una función reconocible"),
    ("esquiva_legible", "la ventana de esquiva resulta entendible"),
    ("telegraph_legible", "el telegráfico se entiende sin leer código"),
    ("sin_bloqueo_camara", "no hay bloqueo reproducible de cámara/alcance"),
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


def preguntar_entero(prompt: str) -> int:
    while True:
        valor = input(f"{prompt}: ").strip()
        try:
            numero = int(valor)
        except ValueError:
            numero = -1
        if numero >= 0:
            return numero
        print("Introduce un entero mayor o igual que cero.")


def _si_no(valor: bool) -> str:
    return "sí" if valor else "no"


def _estado(valor: bool) -> str:
    return "CUMPLE" if valor else "PENDIENTE"


def _normalizar_viewport(valor: str) -> str:
    return valor.lower().replace("×", "x").replace(" ", "")


def evaluar_registro(datos: dict[str, object]) -> dict[str, bool]:
    encuentros = datos["encuentros"]
    assert isinstance(encuentros, dict)

    matriz_completa = True
    evidencias_ok = True
    checks_ok = True
    for clave, _titulo in ENCUENTROS:
        registro = encuentros.get(clave, {})
        if not isinstance(registro, dict):
            matriz_completa = False
            evidencias_ok = False
            checks_ok = False
            continue
        matriz_completa = matriz_completa and all(
            isinstance(registro.get(nombre), int) and int(registro[nombre]) >= 0
            for nombre, _descripcion in METRICAS_ENTERAS
        )
        evidencias_ok = evidencias_ok and bool(str(registro.get("evidencia", "")).strip())
        checks_ok = checks_ok and all(
            bool(registro.get(nombre, False)) for nombre, _descripcion in CHECKS_ENCUENTRO
        )

    viewport_ok = _normalizar_viewport(str(datos["viewport"])) == VIEWPORT_CANONICO
    teclado_ok = bool(datos["matriz_teclado_completa"])
    mando_ok = bool(datos["muestra_mando_fisico"])
    reduccion_ok = bool(datos["reduccion_movimiento_equivalente"])
    balance_humano_ok = bool(datos["sin_ritual_dominante_o_inutil"])
    funciones_ok = bool(datos["acciones_diferenciadas"])

    return {
        "viewport_ok": viewport_ok,
        "matriz_completa": matriz_completa,
        "evidencias_ok": evidencias_ok,
        "checks_ok": checks_ok,
        "teclado_ok": teclado_ok,
        "mando_ok": mando_ok,
        "reduccion_ok": reduccion_ok,
        "balance_humano_ok": balance_humano_ok,
        "funciones_ok": funciones_ok,
        "listo_para_valorar_cierre": all(
            (
                viewport_ok,
                matriz_completa,
                evidencias_ok,
                checks_ok,
                teclado_ok,
                mando_ok,
                reduccion_ok,
                balance_humano_ok,
                funciones_ok,
            )
        ),
    }


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_registro(datos)
    encuentros = datos["encuentros"]
    assert isinstance(encuentros, dict)

    bloques: list[str] = []
    for clave, titulo in ENCUENTROS:
        registro = encuentros[clave]
        assert isinstance(registro, dict)
        lineas = [f"### {titulo}", ""]
        for nombre, descripcion in METRICAS_ENTERAS:
            lineas.append(f"- {descripcion}: {int(registro[nombre])}")
        if clave != "base":
            lineas.append(
                "- el ritual cambió una decisión real: "
                + _si_no(bool(registro.get("ritual_cambio_decision", False)))
            )
        for nombre, descripcion in CHECKS_ENCUENTRO:
            lineas.append(f"- {descripcion}: {_si_no(bool(registro[nombre]))}")
        lineas.extend(
            [
                f"- evidencia: {str(registro['evidencia']).strip()}",
                (
                    "- incidencias: "
                    + (str(registro.get("incidencias", "")).strip() or "Ninguna anotada.")
                ),
                "",
            ]
        )
        bloques.append("\n".join(lineas))

    return f"""# Registro de playtest · Juicio por Combate #912

- fecha: {datos['fecha']}
- tester/facilitador: {datos['tester']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- viewport: `{datos['viewport']}`
- matriz completa con teclado: {_si_no(bool(datos['matriz_teclado_completa']))}
- muestra repetida con mando físico: {_si_no(bool(datos['muestra_mando_fisico']))}
- modelo de mando: {datos['mando_modelo']}

## Matriz

{''.join(bloques)}
## Juicios humanos transversales

- ningún ritual resulta claramente dominante o inútil:
  **{_si_no(bool(datos['sin_ritual_dominante_o_inutil']))}**
- ligero, fuerte y esquiva conservan funciones diferenciadas:
  **{_si_no(bool(datos['acciones_diferenciadas']))}**
- reducción de movimiento conserva la información jugable:
  **{_si_no(bool(datos['reduccion_movimiento_equivalente']))}**

## Resumen del gate

- viewport canónico `1920×1080`: **{_estado(gate['viewport_ok'])}**
- siete variantes medidas: **{_estado(gate['matriz_completa'])}**
- evidencia por variante: **{_estado(gate['evidencias_ok'])}**
- checks de legibilidad/función: **{_estado(gate['checks_ok'])}**
- matriz con teclado: **{_estado(gate['teclado_ok'])}**
- muestra con mando físico: **{_estado(gate['mando_ok'])}**
- reducción de movimiento equivalente: **{_estado(gate['reduccion_ok'])}**
- balance revisado por una persona: **{_estado(gate['balance_humano_ok'])}**
- acciones diferenciadas: **{_estado(gate['funciones_ok'])}**
- listo para valorar cierre de #912:
  **{'SÍ' if gate['listo_para_valorar_cierre'] else 'NO'}**

Los números son observaciones de la sesión, no una puntuación automática. El
script no declara un ritual mejor que otro y no sustituye la revisión humana.

## Observaciones

{str(datos.get('observaciones', '')).strip() or 'Sin observaciones adicionales.'}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest Juicio #912 — usar una build identificable.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "tester": preguntar("Tester/facilitador: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA: "),
        "viewport": preguntar("Viewport (esperado 1920x1080): "),
        "encuentros": {},
    }

    encuentros: dict[str, dict[str, object]] = {}
    for clave, titulo in ENCUENTROS:
        print(f"\n--- {titulo} ---")
        registro: dict[str, object] = {}
        for nombre, descripcion in METRICAS_ENTERAS:
            registro[nombre] = preguntar_entero(descripcion.capitalize())
        if clave != "base":
            registro["ritual_cambio_decision"] = preguntar_si_no(
                "¿El ritual cambió una decisión real durante el combate?"
            )
        for nombre, descripcion in CHECKS_ENCUENTRO:
            registro[nombre] = preguntar_si_no(f"¿{descripcion.capitalize()}?")
        registro["evidencia"] = preguntar("Captura/vídeo/log de evidencia (ruta o URL): ")
        registro["incidencias"] = input("Incidencias reproducibles (opcional): ").strip()
        encuentros[clave] = registro
    datos["encuentros"] = encuentros

    print("\n--- Cierre transversal ---")
    datos["matriz_teclado_completa"] = preguntar_si_no(
        "¿Se completó toda la matriz con teclado?"
    )
    datos["muestra_mando_fisico"] = preguntar_si_no(
        "¿Se repitió al menos una muestra con mando físico?"
    )
    datos["mando_modelo"] = preguntar("Modelo de mando (o 'desconocido'): ")
    datos["reduccion_movimiento_equivalente"] = preguntar_si_no(
        "¿Reducción de movimiento conservó toda la información jugable?"
    )
    datos["sin_ritual_dominante_o_inutil"] = preguntar_si_no(
        "¿La revisión humana descarta un ritual claramente dominante o inútil?"
    )
    datos["acciones_diferenciadas"] = preguntar_si_no(
        "¿Ligero, fuerte y esquiva conservaron funciones diferenciadas?"
    )
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra la matriz humana de balance/game feel pendiente de #912."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown de salida. Por defecto: playtest-912-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-912-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
