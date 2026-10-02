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
    "papel_coger_01": {
        "seed": 180601, "duration": 0.13, "tone_hz": (300, 450), "decay": 2.8,
        "tone_mix": 0.05, "pulse_mix": 0.02, "pulse_threshold": 0.5,
        "noise_mix": 0.75, "noise_lp": 0.25, "drive": 1.1, "gain": 0.55,
        "clacks": ((0.02, 0.20, 0.006),),
        "wav_sha256": "c3e72e31939d6e119f5bbe44cbc9fb60d1030d007e7ca7b63528637f82396fef",
    },
    "papel_pasar_01": {
        "seed": 180602, "duration": 0.26, "tone_hz": (180, 520), "decay": 0.9,
        "tone_mix": 0.10, "pulse_mix": 0.05, "pulse_threshold": 0.2,
        "noise_mix": 0.70, "noise_lp": 0.15, "drive": 1.2, "gain": 0.60,
        "clacks": ((0.04, 0.12, 0.012), (0.16, 0.15, 0.015)),
        "wav_sha256": "385db0698398b6aa0172b6914aa25dde9f98e0e912b74dc3ea9be136fb997605",
    },
    "papel_manojo_01": {
        "seed": 180603, "duration": 0.22, "tone_hz": (120, 220), "decay": 1.4,
        "tone_mix": 0.15, "pulse_mix": 0.08, "pulse_threshold": 0.1,
        "noise_mix": 0.60, "noise_lp": 0.08, "drive": 1.3, "gain": 0.65,
        "clacks": ((0.025, 0.28, 0.007), (0.070, 0.22, 0.008), (0.115, 0.32, 0.009), (0.160, 0.20, 0.007)),
        "wav_sha256": "0138dae3be8487bd7d9099f676e2a7284d1b678073fa1c556907d524fa09a6b6",
    },
    "teclado_tecla_01": {
        "seed": 180611, "duration": 0.14, "tone_hz": (450, 280), "decay": 2.5,
        "tone_mix": 0.35, "pulse_mix": 0.30, "pulse_threshold": 0.0,
        "noise_mix": 0.25, "noise_lp": 0.30, "drive": 1.5, "gain": 0.68,
        "clacks": ((0.018, 0.45, 0.005),),
        "wav_sha256": "a0e2c6542eaccc88789c627ee42bfd9818317aeb736e2e9d71666878878be65e",
    },
    "teclado_tecla_02": {
        "seed": 180614, "duration": 0.12, "tone_hz": (520, 340), "decay": 3.1,
        "tone_mix": 0.28, "pulse_mix": 0.36, "pulse_threshold": 0.18,
        "noise_mix": 0.22, "noise_lp": 0.36, "drive": 1.65, "gain": 0.64,
        "clacks": ((0.014, 0.50, 0.004), (0.041, 0.12, 0.004)),
        "wav_sha256": "ae134c46503ed02b2ebac51bfc22f6f16309cb8593d345df876a7015c2a000a5",
    },
    "teclado_tecla_03": {
        "seed": 180615, "duration": 0.16, "tone_hz": (360, 205), "decay": 2.0,
        "tone_mix": 0.42, "pulse_mix": 0.18, "pulse_threshold": -0.20,
        "noise_mix": 0.32, "noise_lp": 0.24, "drive": 1.35, "gain": 0.69,
        "clacks": ((0.022, 0.34, 0.007), (0.073, 0.18, 0.006)),
        "wav_sha256": "3f932625c3e94d2c447bad2d6a9312bbeebfa9c5059eba01a3edae40574bc50c",
    },
    "teclado_enter_01": {
        "seed": 180612, "duration": 0.18, "tone_hz": (220, 110), "decay": 2.0,
        "tone_mix": 0.45, "pulse_mix": 0.25, "pulse_threshold": -0.1,
        "noise_mix": 0.30, "noise_lp": 0.18, "drive": 1.7, "gain": 0.74,
        "clacks": ((0.020, 0.60, 0.008), (0.055, 0.25, 0.006)),
        "wav_sha256": "6d07c656d5ccffdb48d009afe91c885936f1e2755d3c8f3d1c549f7a702adfb0",
    },
    "teclado_rafaga_01": {
        "seed": 180613, "duration": 0.28, "tone_hz": (380, 320), "decay": 0.8,
        "tone_mix": 0.30, "pulse_mix": 0.25, "pulse_threshold": 0.1,
        "noise_mix": 0.30, "noise_lp": 0.22, "drive": 1.4, "gain": 0.70,
        "clacks": ((0.02, 0.40, 0.005), (0.07, 0.38, 0.005), (0.12, 0.42, 0.005), (0.18, 0.39, 0.005), (0.23, 0.35, 0.005)),
        "wav_sha256": "f46839830706b008cd2724eb3b141d1160d414c6ecbadc164bc1a07bcd6b4da6",
    },
    # Presupuesto canónico de SFX cortos: duración máxima de 0,30 s.
    "teclado_rafaga_02": {
        "seed": 180616, "duration": 0.30, "tone_hz": (430, 250), "decay": 1.05,
        "tone_mix": 0.24, "pulse_mix": 0.31, "pulse_threshold": 0.28,
        "noise_mix": 0.34, "noise_lp": 0.18, "drive": 1.55, "gain": 0.67,
        "clacks": ((0.018, 0.46, 0.004), (0.052, 0.30, 0.005), (0.104, 0.43, 0.004), (0.154, 0.33, 0.006), (0.216, 0.45, 0.004), (0.278, 0.29, 0.005)),
        "wav_sha256": "9cd00a914bc9c49c5dd972714bea5164ad157146913f304cd6f213091b217721",
    },
    "teclado_rafaga_03": {
        "seed": 180617, "duration": 0.24, "tone_hz": (310, 410), "decay": 0.65,
        "tone_mix": 0.34, "pulse_mix": 0.20, "pulse_threshold": -0.05,
        "noise_mix": 0.38, "noise_lp": 0.27, "drive": 1.30, "gain": 0.71,
        "clacks": ((0.016, 0.35, 0.006), (0.083, 0.48, 0.004), (0.126, 0.25, 0.007), (0.195, 0.42, 0.005)),
        "wav_sha256": "23ecf17365f8abca9a7c3002b3a83738ef5908f0ce68b2f1c78f1c5c95fac6c9",
    },
    "ui_pulsar_01": {
        "seed": 181321, "duration": 0.12, "tone_hz": (780, 420), "decay": 3.0,
        "tone_mix": 0.28, "pulse_mix": 0.42, "pulse_threshold": 0.22,
        "noise_mix": 0.12, "noise_lp": 0.38, "drive": 1.7, "gain": 0.58,
        "clacks": ((0.014, 0.44, 0.004),),
        "wav_sha256": "4cc6b98939f341a7a8197e52407984a68b68ef97357c7f7098a65a1363f6c811",
    },
    "ui_marcar_01": {
        "seed": 181322, "duration": 0.14, "tone_hz": (520, 720), "decay": 2.0,
        "tone_mix": 0.38, "pulse_mix": 0.24, "pulse_threshold": -0.08,
        "noise_mix": 0.18, "noise_lp": 0.26, "drive": 1.55, "gain": 0.62,
        "clacks": ((0.018, 0.34, 0.005), (0.082, 0.18, 0.006)),
        "wav_sha256": "cd9baf21f890646304feac90ee4139a421d5cac752a00660ba9227eb0c62bad2",
    },
    "ui_firmar_01": {
        "seed": 181323, "duration": 0.24, "tone_hz": (260, 110), "decay": 1.35,
        "tone_mix": 0.46, "pulse_mix": 0.14, "pulse_threshold": 0.10,
        "noise_mix": 0.24, "noise_lp": 0.16, "drive": 1.45, "gain": 0.66,
        "clacks": ((0.022, 0.28, 0.006), (0.145, 0.31, 0.008)),
        "wav_sha256": "4cc752f4c891e6cce3aac9aa1fb6a1c8da81b89914fdb6bace6d23f4e68b33f4",
    },
    "ui_error_01": {
        "seed": 181324, "duration": 0.18, "tone_hz": (185, 95), "decay": 1.8,
        "tone_mix": 0.34, "pulse_mix": 0.34, "pulse_threshold": 0.34,
        "noise_mix": 0.16, "noise_lp": 0.20, "drive": 1.8, "gain": 0.60,
        "clacks": ((0.020, 0.22, 0.005), (0.065, 0.20, 0.005)),
        "wav_sha256": "a5dc5bc889d47d9bab2d994210f6cc536414176cbf1d764cc42c7835098936cf",
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
