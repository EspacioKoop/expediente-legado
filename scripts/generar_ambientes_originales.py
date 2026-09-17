#!/usr/bin/env python3
"""Renderiza fuentes procedurales originales de ambiente para #119 a OGG/Vorbis."""
from __future__ import annotations

import argparse
import json
import math
import random
import shutil
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

TAU = math.tau


def _fase(freq: float, i: int, sr: int) -> float:
    return TAU * freq * i / sr


def _clip(x: float) -> float:
    return math.tanh(x)


def _parciales(rng: random.Random, dur: float, inicio: int, fin: int, paso: int,
               amp_min: float, amp_max: float) -> list[tuple[float, float, float]]:
    base = 1.0 / dur
    return [(base * k, rng.uniform(amp_min, amp_max), rng.uniform(0, TAU))
            for k in range(inicio, fin, paso)]


def _suma_parciales(i: int, sr: int, ps: list[tuple[float, float, float]]) -> float:
    return sum(a * math.sin(_fase(f, i, sr) + p) for f, a, p in ps)


def _fluorescente(cfg: dict) -> list[float]:
    sr, dur, seed = cfg["muestras_por_segundo"], cfg["duracion"], cfg["semilla"]
    n, rng = int(sr * dur), random.Random(seed)
    r = cfg["ruido"]
    ps = _parciales(rng, dur, r["inicio"], r["fin"], r["paso"], r["amplitud_min"], r["amplitud_max"])
    out = []
    for i in range(n):
        t = i / sr
        x = sum(a * math.sin(_fase(f, i, sr) + p) for f, a, p in cfg["tonos"])
        x += _suma_parciales(i, sr, ps)
        x *= 0.82 + 0.18 * math.sin(TAU * t / dur)
        out.append(_clip(x))
    return out


def _teclado(cfg: dict) -> list[float]:
    sr, dur, seed = cfg["muestras_por_segundo"], cfg["duracion"], cfg["semilla"]
    n, rng = int(sr * dur), random.Random(seed)
    ps = _parciales(rng, dur, 23, 180, 17, 0.003, 0.009)
    out = [cfg["ventilador_amplitud"] * math.sin(_fase(cfg["ventilador_hz"], i, sr)) + _suma_parciales(i, sr, ps) for i in range(n)]
    cursor = 0.30
    eventos: list[float] = []
    while cursor < dur - 0.20:
        for _ in range(rng.randint(2, 5)):
            cursor += rng.uniform(0.055, 0.12)
            if cursor >= dur - 0.15:
                break
            eventos.append(cursor)
        cursor += rng.uniform(0.18, 0.38)
    for ev in eventos:
        start, length = int(ev * sr), int(0.055 * sr)
        pitch, body = rng.choice(cfg["pitches"]), rng.choice(cfg["cuerpos"])
        for j in range(length):
            idx = start + j
            if idx >= n:
                break
            t = j / sr
            env = math.exp(-t * 62.0)
            out[idx] += 0.21 * env * math.sin(TAU * pitch * t) + 0.11 * env * math.sin(TAU * body * t + 0.7)
    return [_clip(x) for x in out]


def _calle(cfg: dict) -> list[float]:
    sr, dur, seed = cfg["muestras_por_segundo"], cfg["duracion"], cfg["semilla"]
    n, rng = int(sr * dur), random.Random(seed)
    ps = _parciales(rng, dur, 11, 420, 19, 0.003, 0.012)
    out = []
    for i in range(n):
        t = i / sr
        x = sum(a * math.sin(_fase(f, i, sr) + p) for f, a, p in cfg["rumble"])
        f, a, p = cfg["lampara"]
        x += a * math.sin(_fase(f, i, sr) + p) + _suma_parciales(i, sr, ps)
        for center, width, freq in cfg["pasadas"]:
            d = (t - center) / width
            env = math.exp(-3.2 * d * d)
            doppler = freq * (1.0 + 0.035 * math.tanh(-d))
            x += env * (0.095 * math.sin(TAU * doppler * t) + 0.033 * math.sin(TAU * doppler * 2.03 * t))
        out.append(_clip(x))
    return out


def _sueno(cfg: dict) -> list[float]:
    sr, dur, seed = cfg["muestras_por_segundo"], cfg["duracion"], cfg["semilla"]
    n, rng = int(sr * dur), random.Random(seed)
    ps = _parciales(rng, dur, 31, 520, 29, 0.002, 0.007)
    out = []
    for i in range(n):
        t = i / sr
        x = sum(a * math.sin(_fase(f, i, sr) + p) for f, a, p in cfg["drone"])
        breath = 0.5 + 0.5 * math.sin(TAU * t / (dur / 2.0) - math.pi / 2)
        x += _suma_parciales(i, sr, ps) * (0.35 + 0.65 * breath)
        f1, f2, a = cfg["pulso"]
        x += a * math.sin(_fase(f1, i, sr)) * math.sin(_fase(f2, i, sr))
        out.append(_clip(x))
    return out


SINTESIS = {"fluorescente": _fluorescente, "teclado": _teclado, "calle": _calle, "sueno": _sueno}


def _wav(path: Path, muestras: list[float], sr: int, ganancia: float) -> None:
    peak = max(max(abs(x) for x in muestras), 1e-9)
    gain = ganancia / peak
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        frames = bytearray()
        for x in muestras:
            frames.extend(struct.pack("<h", int(round(max(-1.0, min(1.0, x * gain)) * 32767))))
        wf.writeframes(frames)


def render(origen: Path, destino: Path) -> list[Path]:
    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        raise SystemExit("ffmpeg no está disponible; es necesario para codificar OGG/Vorbis")
    destino.mkdir(parents=True, exist_ok=True)
    salidas: list[Path] = []
    with tempfile.TemporaryDirectory(prefix="siga98-audio-") as td:
        temporal = Path(td)
        for spec in sorted(origen.glob("*.json")):
            cfg = json.loads(spec.read_text(encoding="utf-8"))
            muestras = SINTESIS[cfg["tipo"]](cfg)
            wav = temporal / (cfg["id"] + ".wav")
            _wav(wav, muestras, cfg["muestras_por_segundo"], cfg["ganancia_objetivo"])
            salida = destino / cfg["salida"]
            subprocess.run(
                [ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "-1", str(salida)],
                check=True,
            )
            salidas.append(salida)
    return salidas


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--origen", type=Path, default=Path("referencia/audio/ambientes_originales"))
    p.add_argument("--destino", type=Path, default=Path("build/ambientes_originales"))
    args = p.parse_args()
    for ruta in render(args.origen, args.destino):
        print(ruta)


if __name__ == "__main__":
    main()
