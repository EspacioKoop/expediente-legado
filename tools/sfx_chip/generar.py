#!/usr/bin/env python3
"""Generador reproducible de foley chip SIGA-98 (#1813).

Sintetiza PCM mono a 44,1 kHz usando solo biblioteca estándar. Los OGG runtime
se codifican después con ffmpeg/libvorbis; el hash canónico de autoría es el
WAV intermedio, porque el contenedor Ogg puede variar entre codificadores.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import math
from pathlib import Path
import random
import shutil
import struct
import subprocess
import wave

SAMPLE_RATE = 44_100
FADE_SECONDS = 0.004

RECETAS = {
    "archivador_abrir_01": {
        "seed": 181301, "duration": 0.24, "tone_hz": (95, 180), "decay": 1.3,
        "tone_mix": 0.40, "pulse_mix": 0.15, "pulse_threshold": 0.2,
        "noise_mix": 0.55, "noise_lp": 0.08, "drive": 1.4, "gain": 0.72,
        "clacks": ((0.035, 0.28, 0.010), (0.18, 0.18, 0.014)),
        "wav_sha256": "f2ffeb6b5bdf3f7bb34e108755ec561688af9ed368f4baf7656db7b84112fdc5",
    },
    "archivador_abrir_02": {
        "seed": 181302, "duration": 0.27, "tone_hz": (82, 155), "decay": 1.5,
        "tone_mix": 0.38, "pulse_mix": 0.12, "pulse_threshold": -0.1,
        "noise_mix": 0.62, "noise_lp": 0.06, "drive": 1.35, "gain": 0.70,
        "clacks": ((0.028, 0.25, 0.008), (0.20, 0.22, 0.018)),
        "wav_sha256": "955612e51f50cfee151f61be36faadc441bc55b5013580d491d364a85af70024",
    },
    "archivador_abrir_03": {
        "seed": 181303, "duration": 0.22, "tone_hz": (110, 205), "decay": 1.15,
        "tone_mix": 0.44, "pulse_mix": 0.10, "pulse_threshold": 0.35,
        "noise_mix": 0.50, "noise_lp": 0.10, "drive": 1.5, "gain": 0.68,
        "clacks": ((0.045, 0.30, 0.009), (0.16, 0.15, 0.010)),
        "wav_sha256": "1a1ac4635f0f5c3607b8a2c133dcb9fe6d052a410608d0f67c072963805e3be0",
    },
    "archivador_cerrar_01": {
        "seed": 181311, "duration": 0.16, "tone_hz": (135, 72), "decay": 1.9,
        "tone_mix": 0.46, "pulse_mix": 0.18, "pulse_threshold": 0.15,
        "noise_mix": 0.46, "noise_lp": 0.12, "drive": 1.6, "gain": 0.76,
        "clacks": ((0.025, 0.38, 0.008), (0.095, 0.22, 0.010)),
        "wav_sha256": "8d820839175e0b2e2f411027845875323e7a38873ae08ad18e85dd175ee3d935",
    },
    "archivador_cerrar_02": {
        "seed": 181312, "duration": 0.18, "tone_hz": (150, 68), "decay": 1.7,
        "tone_mix": 0.42, "pulse_mix": 0.21, "pulse_threshold": -0.25,
        "noise_mix": 0.44, "noise_lp": 0.09, "drive": 1.7, "gain": 0.73,
        "clacks": ((0.022, 0.42, 0.007), (0.11, 0.18, 0.011)),
        "wav_sha256": "b52f5bfe6a0654577b45b0f51ce29f76e7f54fcaed53bed65ec879e2f0b35b3d",
    },
    "archivador_cerrar_03": {
        "seed": 181313, "duration": 0.15, "tone_hz": (120, 58), "decay": 2.1,
        "tone_mix": 0.50, "pulse_mix": 0.14, "pulse_threshold": 0.05,
        "noise_mix": 0.43, "noise_lp": 0.14, "drive": 1.55, "gain": 0.75,
        "clacks": ((0.030, 0.35, 0.009), (0.082, 0.25, 0.008)),
        "wav_sha256": "7c6650547bbb11dfaf72afb931bf014f3686eeb19f69c583d6ada42a17898dfe",
    },
}


def sintetizar(receta: dict) -> list[int]:
    duracion = float(receta["duration"])
    cantidad = round(SAMPLE_RATE * duracion)
    rng = random.Random(int(receta["seed"]))
    muestras: list[float] = []
    ruido_lp = 0.0

    for indice in range(cantidad):
        t = indice / SAMPLE_RATE
        x = t / duracion
        ataque = min(1.0, t / 0.004)
        salida = min(1.0, max(0.0, (duracion - t) / 0.012))
        envolvente = ataque * salida * ((1.0 - x) ** float(receta["decay"]))

        f0, f1 = receta["tone_hz"]
        fase = 2.0 * math.pi * (f0 * t + 0.5 * (f1 - f0) * t * t / duracion)
        triangulo = 2.0 / math.pi * math.asin(math.sin(fase))
        pulso = 1.0 if math.sin(fase * 0.5 + 0.3) > receta["pulse_threshold"] else -1.0

        blanco = rng.uniform(-1.0, 1.0)
        ruido_lp += float(receta["noise_lp"]) * (blanco - ruido_lp)

        golpe = 0.0
        for posicion, amplitud, ancho in receta["clacks"]:
            distancia = abs(t - posicion)
            if distancia < ancho:
                golpe += amplitud * (1.0 - distancia / ancho) * rng.uniform(-1.0, 1.0)

        muestra = envolvente * (
            receta["tone_mix"] * triangulo
            + receta["pulse_mix"] * pulso
            + receta["noise_mix"] * ruido_lp
        ) + golpe
        drive = float(receta["drive"])
        muestra = math.tanh(muestra * drive) / math.tanh(drive)
        muestras.append(max(-0.98, min(0.98, muestra)) * float(receta["gain"]))

    media = sum(muestras) / len(muestras)
    muestras = [muestra - media for muestra in muestras]

    fade = round(SAMPLE_RATE * FADE_SECONDS)
    for indice in range(min(fade, len(muestras))):
        factor = indice / fade
        muestras[indice] *= factor
        muestras[-1 - indice] *= factor

    return [round(max(-1.0, min(1.0, muestra)) * 32767) for muestra in muestras]


def wav_bytes(muestras: list[int]) -> bytes:
    salida = io.BytesIO()
    with wave.open(salida, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(struct.pack("<" + "h" * len(muestras), *muestras))
    return salida.getvalue()


def sha256(datos: bytes) -> str:
    return hashlib.sha256(datos).hexdigest()


def verificar() -> None:
    for nombre, receta in RECETAS.items():
        real = sha256(wav_bytes(sintetizar(receta)))
        esperado = receta["wav_sha256"]
        if real != esperado:
            raise SystemExit(f"{nombre}: WAV {real} != {esperado}")


def generar(destino: Path, ogg: bool) -> None:
    destino.mkdir(parents=True, exist_ok=True)
    ffmpeg = shutil.which("ffmpeg") if ogg else None
    if ogg and not ffmpeg:
        raise SystemExit("ffmpeg no está disponible para codificar OGG")

    for nombre, receta in RECETAS.items():
        wav = destino / f"{nombre}.wav"
        wav.write_bytes(wav_bytes(sintetizar(receta)))
        if not ogg:
            continue
        subprocess.run(
            [
                ffmpeg, "-y", "-hide_banner", "-loglevel", "error",
                "-i", str(wav), "-c:a", "libvorbis", "-q:a", "3",
                "-map_metadata", "-1", str(destino / f"{nombre}.ogg"),
            ],
            check=True,
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--verificar", action="store_true")
    parser.add_argument("--salida", type=Path)
    parser.add_argument("--ogg", action="store_true")
    args = parser.parse_args()

    if args.verificar:
        verificar()
    if args.salida:
        generar(args.salida, args.ogg)
    if not args.verificar and args.salida is None:
        parser.error("usa --verificar y/o --salida")


if __name__ == "__main__":
    main()
