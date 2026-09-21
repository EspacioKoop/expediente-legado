#!/usr/bin/env python3
"""Registra el gate visual humano final de tipografía de SIGA-98 (#780).

El script no inspecciona píxeles ni simula teclado/mando. Conserva checks
explícitos del tester y genera evidencia trazable a una build concreta.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path


VIEWPORT_CANONICO = "1920x1080"

PANTALLAS = (
    (
        "creador",
        "Creador de personaje",
        (
            ("texto_pequeno_legible", "texto pequeño legible y sin dentado evidente"),
            ("ui_consistente", "tipografía de interfaz consistente entre controles"),
            ("sin_recortes", "sin recortes, solapes ni desbordes por la fuente"),
        ),
    ),
    (
        "visor",
        "Visor de expedientes",
        (
            ("titulo_jerarquizado", "barra/título claramente jerarquizado en negrita"),
            ("cuerpo_documental_legible", "cuerpo documental legible y distinto del rol mono"),
            ("scroll_sin_recortes", "scroll completo sin recortes ni saltos de layout"),
        ),
    ),
    (
        "reconstruccion",
        "Reconstrucción",
        (
            ("titulo_jerarquizado", "barra de título claramente jerarquizada en negrita"),
            ("foco_teclado_ok", "foco y navegación con teclado intactos"),
            ("foco_mando_ok", "foco y navegación con mando físico intactos"),
        ),
    ),
    (
        "ventanilla",
        "Ventanilla",
        (
            ("titulo_jerarquizado", "barra de título claramente jerarquizada en negrita"),
            ("replica_mono_legible", "réplica mecanografiada mono legible y diferenciada"),
            ("foco_teclado_ok", "foco y navegación con teclado intactos"),
            ("foco_mando_ok", "foco y navegación con mando físico intactos"),
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
    pantallas = datos["pantallas"]
    assert isinstance(pantallas, dict)

    pantallas_ok = True
    capturas_ok = True
    for clave, _titulo, checks in PANTALLAS:
        registro = pantallas[clave]
        assert isinstance(registro, dict)
        pantallas_ok = pantallas_ok and all(bool(registro[nombre]) for nombre, _ in checks)
        capturas_ok = capturas_ok and bool(str(registro.get("captura", "")).strip())

    viewport_ok = _normalizar_viewport(str(datos["viewport"])) == VIEWPORT_CANONICO
    dispositivos_ok = bool(datos["teclado_real"]) and bool(datos["mando_fisico"])

    return {
        "viewport_ok": viewport_ok,
        "dispositivos_ok": dispositivos_ok,
        "pantallas_ok": pantallas_ok,
        "capturas_ok": capturas_ok,
        "listo_para_cerrar": all(
            (viewport_ok, dispositivos_ok, pantallas_ok, capturas_ok)
        ),
    }


def render_markdown(datos: dict[str, object]) -> str:
    gate = evaluar_gate(datos)
    pantallas = datos["pantallas"]
    assert isinstance(pantallas, dict)

    bloques: list[str] = []
    for clave, titulo, checks in PANTALLAS:
        registro = pantallas[clave]
        assert isinstance(registro, dict)
        lineas = [f"### {titulo}", ""]
        for nombre, descripcion in checks:
            lineas.append(f"- {descripcion}: {_si_no(bool(registro[nombre]))}")
        lineas.extend(
            [
                f"- captura/evidencia: {str(registro.get('captura', '')).strip() or 'No indicada.'}",
                f"- notas: {str(registro.get('notas', '')).strip() or 'Sin observaciones.'}",
                "",
            ]
        )
        bloques.append("\n".join(lineas))

    incidencias = str(datos.get("incidencias", "")).strip() or "Ninguna anotada."
    observaciones = (
        str(datos.get("observaciones", "")).strip() or "Sin observaciones adicionales."
    )

    return f"""# Registro de playtest tipográfico · #780

- fecha: {datos['fecha']}
- tester/facilitador: {datos['tester']}
- plataforma: {datos['plataforma']}
- build SHA: `{datos['build_sha']}`
- viewport: `{datos['viewport']}`
- teclado real probado: {_si_no(bool(datos['teclado_real']))}
- mando físico real probado: {_si_no(bool(datos['mando_fisico']))}
- modelo de mando: {datos['mando_modelo']}

## Pantallas

{''.join(bloques)}
## Resumen del gate

- viewport canónico `1920×1080`: **{_estado(gate['viewport_ok'])}**
- teclado + mando físico probados: **{_estado(gate['dispositivos_ok'])}**
- comprobaciones visuales y de foco: **{_estado(gate['pantallas_ok'])}**
- evidencia por las cuatro pantallas: **{_estado(gate['capturas_ok'])}**
- listo para valorar cierre de #780: **{'SÍ' if gate['listo_para_cerrar'] else 'NO'}**

El resultado deriva únicamente de checks introducidos durante una sesión humana.
No sustituye el playtest, no analiza capturas y no afirma calidad visual por pasar CI.

## Incidencias

{incidencias}

## Observaciones

{observaciones}
"""


def recoger_datos() -> dict[str, object]:
    print("Playtest tipográfico #780 — usar una build identificable.\n")
    datos: dict[str, object] = {
        "fecha": datetime.now().astimezone().isoformat(timespec="seconds"),
        "tester": preguntar("Tester/facilitador: "),
        "plataforma": preguntar("Plataforma (Linux/Windows/...): "),
        "build_sha": preguntar("Build SHA: "),
        "viewport": preguntar("Viewport (esperado 1920x1080): "),
        "teclado_real": preguntar_si_no("¿Se ha probado con teclado real?"),
        "mando_fisico": preguntar_si_no("¿Se ha probado con mando físico real?"),
        "mando_modelo": preguntar("Modelo de mando (o 'desconocido'): "),
        "pantallas": {},
    }

    pantallas: dict[str, dict[str, object]] = {}
    for clave, titulo, checks in PANTALLAS:
        print(f"\n--- {titulo} ---")
        registro: dict[str, object] = {}
        for nombre, descripcion in checks:
            registro[nombre] = preguntar_si_no(f"¿{descripcion.capitalize()}?")
        registro["captura"] = preguntar("Captura/evidencia (ruta o URL): ")
        registro["notas"] = input("Notas (opcional): ").strip()
        pantallas[clave] = registro
    datos["pantallas"] = pantallas

    print("\n--- Cierre ---")
    datos["incidencias"] = input("Incidencias reproducibles (opcional): ").strip()
    datos["observaciones"] = input("Observaciones adicionales (opcional): ").strip()
    return datos


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Registra evidencia del playtest humano final pendiente de #780."
    )
    parser.add_argument(
        "--salida",
        type=Path,
        help="Ruta Markdown de salida. Por defecto: playtest-780-<timestamp>.md",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    datos = recoger_datos()
    salida = args.salida or Path(
        f"playtest-780-{datetime.now().strftime('%Y%m%d-%H%M%S')}.md"
    )
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(render_markdown(datos), encoding="utf-8")
    print(f"\nRegistro guardado en: {salida}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
