#!/usr/bin/env python3
"""Prepara una cata reproducible de los ambientes originales de #119."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import math
import shutil
import subprocess
import tempfile
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
ORIGEN_PREDETERMINADO = RAIZ / "referencia" / "audio" / "ambientes_originales"
GENERADOR = RAIZ / "scripts" / "generar_ambientes_originales.py"
ORDEN = ("fluorescente", "teclado_oficina", "calle_noche", "sueno")
INTENCIONES = {
    "fluorescente": "Archivo: red eléctrica, balasto y aire de oficina.",
    "teclado_oficina": "Archivo: actividad discreta de teclado sobre ventilación tenue.",
    "calle_noche": "Trayecto: rumor urbano, lámpara y tráfico lejano.",
    "sueno": "Sueño: drone lento, batidos y respiración de ruido.",
}


def cargar_generador():
    spec = importlib.util.spec_from_file_location("ambientes_originales", GENERADOR)
    if spec is None or spec.loader is None:
        raise RuntimeError("no se puede cargar el generador de ambientes originales")
    modulo = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modulo)
    return modulo


def cargar_especificaciones(origen: Path) -> dict[str, tuple[Path, dict]]:
    encontradas: dict[str, tuple[Path, dict]] = {}
    for ruta in sorted(origen.glob("*.json")):
        cfg = json.loads(ruta.read_text(encoding="utf-8"))
        identificador = str(cfg["id"])
        encontradas[identificador] = (ruta, cfg)
    faltantes = [identificador for identificador in ORDEN if identificador not in encontradas]
    if faltantes:
        raise ValueError("faltan recetas para la cata: " + ", ".join(faltantes))
    return encontradas


def repetir(muestras: list[float], repeticiones: int) -> list[float]:
    if repeticiones < 2:
        raise ValueError("la cata necesita al menos dos repeticiones para oír el loop")
    return muestras * repeticiones


def metricas(muestras: list[float]) -> dict[str, float]:
    if len(muestras) < 2:
        raise ValueError("se necesitan al menos dos muestras")
    pico = max(abs(valor) for valor in muestras)
    rms = math.sqrt(sum(valor * valor for valor in muestras) / len(muestras))
    media = sum(muestras) / len(muestras)
    salto = abs(muestras[-1] - muestras[0])
    pendiente_inicio = muestras[1] - muestras[0]
    pendiente_fin = muestras[-1] - muestras[-2]
    salto_pendiente = abs(pendiente_fin - pendiente_inicio)

    def db(valor: float, referencia: float = 1.0) -> float:
        if valor <= 1e-12 or referencia <= 1e-12:
            return -120.0
        return max(-120.0, 20.0 * math.log10(valor / referencia))

    return {
        "pico": round(pico, 8),
        "rms": round(rms, 8),
        "rms_dbfs": round(db(rms), 3),
        "media_dc": round(media, 8),
        "salto_loop": round(salto, 8),
        "salto_loop_db_rel_pico": round(db(salto, max(pico, 1e-12)), 3),
        "salto_pendiente": round(salto_pendiente, 8),
    }


def sha256(ruta: Path) -> str:
    digest = hashlib.sha256()
    with ruta.open("rb") as fichero:
        for bloque in iter(lambda: fichero.read(1024 * 1024), b""):
            digest.update(bloque)
    return digest.hexdigest()


def ficha_revision(fuentes: list[dict]) -> str:
    filas = [
        "# Cata humana de ambientes — #119",
        "",
        "Este fichero es una plantilla de revisión. Las métricas del manifest ayudan a",
        "detectar anomalías técnicas, pero **no sustituyen la escucha humana**.",
        "",
        "Escuchar cada pista completa con auriculares y, si es posible, también con",
        "altavoces. El loop se repite sin crossfade para que cualquier costura sea audible.",
        "",
        "| Fuente | Identidad | Loop | Fatiga | Enmascara efectos/diálogo | Decisión | Notas |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for fuente in fuentes:
        filas.append(
            f"| {fuente['id']} | ☐ | ☐ | ☐ | ☐ | ☐ promover / ☐ iterar / ☐ descartar | |"
        )
    filas.extend(
        [
            "",
            "## Criterio mínimo",
            "",
            "- identidad reconocible respecto a las otras tres fuentes;",
            "- ninguna costura de loop claramente perceptible;",
            "- sin tono o patrón que fatigue en repetición;",
            "- suficiente margen para pasos, interacción, diálogo y música puntual;",
            "- la decisión se registra como observación humana, no como resultado de CI.",
            "",
        ]
    )
    return "\n".join(filas)


def preparar(origen: Path, destino: Path, repeticiones: int = 8) -> dict:
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        raise SystemExit("ffmpeg no está disponible; es necesario para preparar la cata")

    generador = cargar_generador()
    especificaciones = cargar_especificaciones(origen)
    destino.mkdir(parents=True, exist_ok=True)
    fuentes: list[dict] = []

    with tempfile.TemporaryDirectory(prefix="siga98-cata-audio-") as temporal:
        temporal_path = Path(temporal)
        for indice, identificador in enumerate(ORDEN, start=1):
            ruta_spec, cfg = especificaciones[identificador]
            muestras = generador.SINTESIS[cfg["tipo"]](cfg)
            muestras_cata = repetir(muestras, repeticiones)
            wav = temporal_path / f"{identificador}.wav"
            generador._wav(
                wav,
                muestras_cata,
                int(cfg["muestras_por_segundo"]),
                float(cfg["ganancia_objetivo"]),
            )
            salida = destino / f"{indice:02d}_{identificador}.ogg"
            subprocess.run(
                [
                    ffmpeg,
                    "-hide_banner",
                    "-loglevel",
                    "error",
                    "-y",
                    "-i",
                    str(wav),
                    "-c:a",
                    "libvorbis",
                    "-q:a",
                    "-1",
                    str(salida),
                ],
                check=True,
            )
            fuentes.append(
                {
                    "id": identificador,
                    "receta": ruta_spec.name,
                    "archivo": salida.name,
                    "intencion": INTENCIONES[identificador],
                    "duracion_base_s": float(cfg["duracion"]),
                    "repeticiones": repeticiones,
                    "duracion_cata_s": round(float(cfg["duracion"]) * repeticiones, 3),
                    "muestras_por_segundo": int(cfg["muestras_por_segundo"]),
                    "metricas_pcm_fuente": metricas(muestras),
                    "sha256_ogg_cata": sha256(salida),
                }
            )

    manifest = {
        "issue": 119,
        "origen": "fuentes procedurales originales de #826",
        "nota": (
            "Los hashes identifican este artifact de cata; no son hashes canónicos "
            "de procedencia y pueden variar con la versión de FFmpeg/Vorbis."
        ),
        "fuentes": fuentes,
    }
    (destino / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    playlist = ["#EXTM3U", *[fuente["archivo"] for fuente in fuentes]]
    (destino / "cata.m3u").write_text("\n".join(playlist) + "\n", encoding="utf-8")
    (destino / "REVISION.md").write_text(ficha_revision(fuentes), encoding="utf-8")
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--origen", type=Path, default=ORIGEN_PREDETERMINADO)
    parser.add_argument(
        "--destino",
        type=Path,
        default=RAIZ / "build" / "cata_ambientes_119",
    )
    parser.add_argument("--repeticiones", type=int, default=8)
    args = parser.parse_args()
    manifest = preparar(args.origen, args.destino, args.repeticiones)
    for fuente in manifest["fuentes"]:
        print(
            f"{fuente['archivo']}: {fuente['duracion_cata_s']:.1f}s "
            f"RMS={fuente['metricas_pcm_fuente']['rms_dbfs']:.1f} dBFS "
            f"salto={fuente['metricas_pcm_fuente']['salto_loop']:.6f}"
        )
    print(args.destino / "REVISION.md")


if __name__ == "__main__":
    main()
