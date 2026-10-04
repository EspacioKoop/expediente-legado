#!/usr/bin/env python3
"""Cata offline de #1475. Python estándar; FFmpeg opcional para true peak.

El codec ensaya bloques SPU-ADPCM, no emula una SPU. La secuencia JSON no es XM.
No lee grabaciones, no usa red y no escribe dentro de los assets del juego.
"""
from __future__ import annotations

import argparse
from array import array
import hashlib
from html import escape
import json
import math
from pathlib import Path
import platform
import random
import re
import shutil
import struct
import subprocess
import tempfile
import wave

RAIZ = Path(__file__).resolve().parents[1]
RECETA = RAIZ / "referencia/audio/laboratorio_1475/oficina_machine_pulse.json"
RECETA_CATA = RECETA.with_name("cata_motivos_timbres.json")
SR = 44_100
FILTROS = ((0, 0), (60, 0), (115, -52), (98, -55), (122, -60))


def sha256(datos: bytes) -> str:
    return hashlib.sha256(datos).hexdigest()


def limitar16(valor: int) -> int:
    return max(-32768, min(32767, valor))


def paso_pitch_spu(registro: int) -> int:
    """Paso lógico del contador PITCH sin PMON; no produce PCM interpolado."""
    if type(registro) is not int or not 0 <= registro <= 0xFFFF:
        raise ValueError("PITCH debe ser un registro unsigned de 16 bits")
    return min(registro, 0x4000)


def tasa_pitch_spu(registro: int) -> float:
    """Consumo teórico de muestras fuente por segundo con DAC fijo a 44,1 kHz."""
    return SR * paso_pitch_spu(registro) / 0x1000


def trazar_pitch_spu(
    registro: int,
    ticks: list[int],
    contador_inicial: int = 0,
) -> dict:
    """Traza T07 sin interpolación PCM ni estado completo de voz."""
    paso = paso_pitch_spu(registro)
    if type(contador_inicial) is not int or contador_inicial < 0:
        raise ValueError("contador_inicial debe ser entero no negativo")
    if (
        not ticks
        or any(type(tick) is not int or tick <= 0 for tick in ticks)
        or ticks != sorted(set(ticks))
    ):
        raise ValueError("ticks debe contener enteros positivos, únicos y crecientes")

    contadores = [contador_inicial + tick * paso for tick in ticks]
    return {
        "paso": paso,
        "contadores": contadores,
        "indices_muestra": [contador >> 12 for contador in contadores],
        "indices_interpolacion": [(contador >> 4) & 0xFF for contador in contadores],
    }


def pcm16(muestras) -> bytes:
    if any(not math.isfinite(x) or abs(x) >= 1 for x in muestras):
        raise ValueError("PCM no finito o sin margen; no se recorta silenciosamente")
    return b"".join(struct.pack("<h", round(x * 32767)) for x in muestras)


def decodificar_adpcm(datos: bytes) -> list[int]:
    """Decodifica una pasada de bloques; flags no gobiernan playback offline."""
    if not datos or len(datos) % 16:
        raise ValueError("SPU-ADPCM requiere bloques completos de 16 bytes")
    anterior = anterior2 = 0
    salida = []
    for inicio in range(0, len(datos), 16):
        filtro, desplazamiento = datos[inicio] >> 4, datos[inicio] & 15
        if filtro > 4 or desplazamiento > 12:
            raise ValueError("cabecera ADPCM fuera del subconjunto soportado")
        a, b = FILTROS[filtro]
        for octeto in datos[inicio + 2:inicio + 16]:
            for nibble in (octeto & 15, octeto >> 4):
                firmado = nibble if nibble < 8 else nibble - 16
                predicho = (anterior * a + anterior2 * b + 32) >> 6
                valor = limitar16((firmado << 12 >> desplazamiento) + predicho)
                salida.append(valor)
                anterior2, anterior = anterior, valor
    return salida


def codificar_adpcm(muestras: list[int], bucle: bool = False) -> bytes:
    """Búsqueda de error cuadrático con historial reconstruido por bloque.

    El primer bloque usa filtro 0: reinicia el predictor también al repetir.
    No es un empaquetador VAG ni una imagen de RAM lista para hardware.
    """
    if not muestras or any(type(x) is not int or not -32768 <= x <= 32767 for x in muestras):
        raise ValueError("se necesita PCM entero de 16 bits no vacío")
    datos = muestras + [0] * (-len(muestras) % 28)
    anterior = anterior2 = 0
    salida = bytearray()
    for inicio in range(0, len(datos), 28):
        bloque = datos[inicio:inicio + 28]
        mejor = None
        for filtro in range(1 if inicio == 0 else 5):
            a, b = FILTROS[filtro]
            for desplazamiento in range(13):
                h1, h2, error, nibbles = anterior, anterior2, 0, []
                paso = 1 << (12 - desplazamiento)
                for objetivo in bloque:
                    predicho = (h1 * a + h2 * b + 32) >> 6
                    nibble = max(-8, min(7, round((objetivo - predicho) / paso)))
                    reconstruido = limitar16(predicho + nibble * paso)
                    error += (objetivo - reconstruido) ** 2
                    nibbles.append(nibble & 15)
                    h2, h1 = h1, reconstruido
                if mejor is None or error < mejor[0]:
                    mejor = (error, filtro, desplazamiento, nibbles, h1, h2)
        _, filtro, desplazamiento, nibbles, anterior, anterior2 = mejor
        flags = 4 if inicio == 0 and bucle else 0
        if inicio + 28 == len(datos):
            flags |= 3 if bucle else 1
        salida.extend((filtro << 4 | desplazamiento, flags))
        salida.extend(nibbles[i] | nibbles[i + 1] << 4 for i in range(0, 28, 2))
    return bytes(salida)


def filtrar_fuente(muestras: list[float], bucle: bool) -> list[float]:
    """FIR simétrico a 5,5 kHz: limita brillo antes de transponer hasta +12 st."""
    fc, radio = 5500 / SR, 32
    kernel = [
        (2 * fc if k == 0 else math.sin(2 * math.pi * fc * k) / (math.pi * k))
        * (0.5 + 0.5 * math.cos(math.pi * k / radio))
        for k in range(-radio, radio + 1)
    ]
    total = sum(kernel)
    n = len(muestras)
    return [sum(c * (muestras[(i + k - radio) % n] if bucle else
                     muestras[i + k - radio] if 0 <= i + k - radio < n else 0)
                for k, c in enumerate(kernel)) / total for i in range(n)]


def sintetizar(cfg: dict) -> list[float]:
    n = cfg["muestras"]
    if type(n) is not int or not 28 <= n <= SR or n % 28:
        raise ValueError("cada fuente debe ocupar 28..44100 muestras alineadas a 28")
    frecuencia = float(cfg["hz"])
    if not 30 <= frecuencia <= 2000 or cfg["tipo"] not in ("fm", "ruido", "ciclo"):
        raise ValueError("fuente fuera de la paleta experimental")
    rng = random.Random(cfg["semilla"])
    bucle = cfg["tipo"] == "ciclo"
    salida = []
    for i in range(n):
        t = i / SR
        fase = math.tau * frecuencia * t
        if bucle:
            valor = math.sin(fase) + 0.22 * math.sin(2 * fase) + 0.05 * math.sin(7 * fase)
        elif cfg["tipo"] == "ruido":
            valor = 0.55 * rng.uniform(-1, 1) + 0.45 * math.sin(fase)
        else:
            indice = cfg["indice_fm"] * math.exp(-t * 12)
            valor = math.sin(fase + indice * math.sin(fase * cfg["ratio_fm"]))
        if not bucle:
            valor *= math.exp(-t * cfg["caida"])
        salida.append(valor)
    salida = filtrar_fuente(salida, bucle)
    media = sum(salida) / n
    salida = [x - media for x in salida]
    if not bucle:
        rampa = min(round(SR * 0.003), n // 2)
        salida = [x * min(1, i / rampa, (n - 1 - i) / rampa) for i, x in enumerate(salida)]
    pico = max(abs(x) for x in salida)
    return [x * 0.6 / pico for x in salida]


def eventos(cfg: dict, banco: dict) -> list[dict]:
    """Patrones y ticks explícitos; retrigger/delay/offset sin semántica XM implícita."""
    bpm, ticks, filas = cfg["bpm"], cfg["ticks_fila"], cfg["filas_patron"]
    if not (40 <= bpm <= 200 and 1 <= ticks <= 12 and 1 <= filas <= 64):
        raise ValueError("tempo o tamaño de patrón inválido")
    tick_s = 2.5 / bpm
    resultado = []
    for orden, patron in enumerate(cfg["orden"]):
        for ev in cfg["patrones"][patron]:
            nombre = ev["instrumento"]
            fila, delay = ev["fila"], ev.get("delay_ticks", 0)
            tono, ganancia, pan = ev.get("semitonos", 0), ev["ganancia"], ev["pan"]
            offset = ev.get("offset", 0)
            puerta = ev.get("duracion_filas", 1) * ticks * tick_s
            retrigger = ev.get("retrigger_ticks", ticks)
            if (nombre not in banco or not 0 <= fila < filas or not 0 <= delay < ticks
                    or not -12 <= tono <= 12 or not 0 < ganancia <= 1 or not -1 <= pan <= 1
                    or type(offset) is not int or not 0 <= offset < len(banco[nombre])
                    or type(retrigger) is not int or not 1 <= retrigger <= ticks
                    or not 0 < puerta <= 8):
                raise ValueError("evento fuera de límites")
            ratio = 2 ** (tono / 12)
            bucle = cfg["banco"][nombre]["tipo"] == "ciclo"
            for tick in range(delay, ticks, retrigger):
                inicio = 0.5 + ((orden * filas + fila) * ticks + tick) * tick_s
                duracion = puerta if bucle else min(puerta, (len(banco[nombre]) - offset) / (SR * ratio))
                # Retriggers cortan la voz anterior con rampa; nunca acumulan colas ocultas.
                if "retrigger_ticks" in ev:
                    duracion = min(duracion, retrigger * tick_s)
                resultado.append(dict(instrumento=nombre, inicio=round(inicio * SR),
                                      muestras=round(duracion * SR), ratio=ratio,
                                      ganancia=ganancia, pan=pan, offset=offset, bucle=bucle))
    return sorted(resultado, key=lambda e: e["inicio"])


def contar_voces(partitura: list[dict]) -> int:
    bordes = [(e["inicio"], 1) for e in partitura]
    bordes += [(e["inicio"] + e["muestras"], -1) for e in partitura]
    actuales = maximas = 0
    for _, cambio in sorted(bordes):
        actuales += cambio
        maximas = max(maximas, actuales)
    return maximas


def mezclar(banco: dict, partitura: list[dict], n: int) -> list[array]:
    canales = [array("d", [0]) * n, array("d", [0]) * n]
    for ev in partitura:
        fuente = banco[ev["instrumento"]]
        angulo = (ev["pan"] + 1) * math.pi / 4
        ganancias = [math.cos(angulo) * ev["ganancia"], math.sin(angulo) * ev["ganancia"]]
        if ev["inicio"] + ev["muestras"] > n:
            raise ValueError("la partitura rebasa la duración; no se truncan voces")
        rampa = min(132, max(1, ev["muestras"] // 2))
        for i in range(ev["muestras"]):
            pos = ev["offset"] + i * ev["ratio"]
            indice, fraccion = int(pos), pos % 1
            if ev["bucle"]:
                indice %= len(fuente)
                siguiente = fuente[(indice + 1) % len(fuente)]
            else:
                if indice >= len(fuente):
                    break
                siguiente = fuente[min(indice + 1, len(fuente) - 1)]
            valor = fuente[indice] * (1 - fraccion) + siguiente * fraccion
            valor *= min(1, i / rampa, (ev["muestras"] - 1 - i) / rampa)
            for canal, ganancia in zip(canales, ganancias):
                canal[ev["inicio"] + i] += valor * ganancia
    # DC blocker común a A y B, 20 Hz; es mezcla moderna, no DSP de PSX.
    polo = math.exp(-math.tau * 20 / SR)
    for canal in canales:
        x_anterior = y_anterior = 0.0
        for i, x in enumerate(canal):
            y = x - x_anterior + polo * y_anterior
            x_anterior, y_anterior = x, y
            canal[i] = y
    return canales


def escribir_wav(ruta: Path, canales: list) -> None:
    planos = array("d", (x for frame in zip(*canales) for x in frame))
    with wave.open(str(ruta), "wb") as wav:
        wav.setnchannels(len(canales))
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(pcm16(planos))


def medir_wav(ruta: Path) -> dict:
    """Mide el PCM exportado, no el flotante anterior a la cuantización."""
    with wave.open(str(ruta), "rb") as wav:
        canales, n, sr = wav.getnchannels(), wav.getnframes(), wav.getframerate()
        datos = wav.readframes(n)
    valores = [x[0] / 32768 for x in struct.iter_unpack("<h", datos)]
    pistas = [valores[c::canales] for c in range(canales)]
    pico = max(map(abs, valores))
    energia = sum(x * x for x in valores) / len(valores)
    mono = [sum(frame) / canales for frame in zip(*pistas)]
    energia_mono = sum(x * x for x in mono) / len(mono)
    return dict(duracion_s=n / sr, muestras=n, canales=canales,
                pico_dbfs=20 * math.log10(max(pico, 1e-12)),
                rms_dbfs=10 * math.log10(max(energia, 1e-24)),
                dc_por_canal=[sum(p) / len(p) for p in pistas],
                clipping=sum(abs(x) >= 32767 / 32768 for x in valores),
                mono_delta_db=10 * math.log10(max(energia_mono, 1e-24) / max(energia, 1e-24)),
                salto_extremos=max(abs(p[-1] - p[0]) for p in pistas),
                sha256=sha256(ruta.read_bytes()))


def medir_ffmpeg(ruta: Path, ejecutable: str) -> dict:
    proceso = subprocess.run([ejecutable, "-hide_banner", "-nostats", "-i", str(ruta),
                              "-af", "ebur128=peak=true", "-f", "null", "-"],
                             capture_output=True, text=True, check=True)
    pico = re.findall(r"True peak:\s*Peak:\s*([-\d.]+) dBFS", proceso.stderr)
    lufs = re.findall(r"\bI:\s*([-\d.]+) LUFS", proceso.stderr)
    if not pico or not lufs:
        raise RuntimeError("FFmpeg no informó true peak/LUFS del programa")
    return dict(true_peak_dbtp=float(pico[-1]), programa_lufs_i=float(lufs[-1]))


def escribir_escucha(destino: Path, salidas: list[dict], fichas: list[dict]) -> None:
    """Reproduce los WAV originales sin servidor, instalación ni recodificación."""
    def reproductor(ruta: str, etiqueta: str) -> str:
        return (f'<div class="version"><p>{escape(etiqueta)}</p>'
                f'<audio controls preload="none" aria-label="{escape(etiqueta)}" '
                f'src="{escape(ruta)}"></audio>'
                f'<a href="{escape(ruta)}" download>Descargar WAV</a></div>')

    estudio = "".join(reproductor(r["archivo"], etiqueta) for r, etiqueta in zip(
        salidas, ("A · Estudio limpio — 28 s", "B · Estudio con ADPCM — 28 s")))
    banco = "".join(
        f'<section><h3>{escape(f["id"].capitalize())}</h3><div class="pareja">' +
        "".join(reproductor(f'banco/{f["id"]}_{variante}.wav', f'{f["id"]} · {etiqueta}')
                for variante, etiqueta in (("limpio", "A · limpio"), ("adpcm", "B · ADPCM"))) +
        '</div></section>' for f in fichas)
    cata = "motivo" in salidas[0]
    titulo = "Oficina · machine pulse"
    descripcion = "Misma partitura y ganancia en el estudio A/B; sin reverberación."
    instrucciones = "Compara las versiones limpia y ADPCM y escucha cada fuente."
    banco = ('<h2>Banco de cuatro samples</h2><p>Fuentes sintéticas aisladas; '
             '«Red» es un ciclo de 40 ms, cuyo uso sostenido se oye en el estudio.</p>' + banco)
    limites = "Experimento ADPCM por instrumento; no emula una SPU completa."
    if cata:
        estudio = "".join(reproductor(r["archivo"],
                                     f'{r["motivo"].upper()} · {r["timbre"].upper()} — 10 s')
                           for r in salidas)
        titulo = "Dos motivos · dos timbres"
        descripcion = "96 BPM, raíz 220 Hz, puerta 0,25 s. Nivel calibrado por timbre; PCM limpio, sin reverb."
        instrucciones = "Compara el mismo motivo entre timbres y el mismo timbre entre motivos."
        banco = '<p>Repite en orden inverso. Describe primero lo que oyes, sin buscar una emoción prefijada.</p>'
        limites = "Boceto compositivo T01: no emula SPU-98 ni FM-98 completos."
    pagina = """<!doctype html>
<html lang="es"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>SIGA-98 · __TITULO__</title>
<style>
:root{color-scheme:dark;font-family:system-ui,sans-serif;background:#111b20;color:#e7efec}
body{max-width:900px;margin:auto;padding:32px 20px;line-height:1.6}
h1,h2,h3{line-height:1.2}h1{font-size:2.3rem}h2{margin-top:36px}
.ceja{color:#a1c8b0;letter-spacing:.15em;font-size:.8rem}
.nota{color:#b8c7cb}section{border-top:1px solid #385057;padding:12px 0}
.pareja{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}
.version{min-width:0}audio{display:block;width:100%;margin:10px 0}
a{color:#b4e5c6}button{font:inherit;border:1px solid #87bda1;border-radius:6px;
padding:8px 16px;background:#1d3530;color:#e7efec;cursor:pointer}
@media(max-width:620px){.pareja{grid-template-columns:1fr;gap:8px}}
</style>
<body><header><p class="ceja">SIGA-98 / LABORATORIO SONORO / 1475</p>
<h1>__TITULO__</h1><p>__INSTRUCCIONES__</p>
<p class="nota">Sonidos sintéticos originales. __DESCRIPCION__ Escucha humana pendiente.</p></header>
<button id="parar" type="button">Parar todos</button>
<h2>Escuchar y comparar</h2><div class="pareja">__ESTUDIO__</div>
__BANCO__
<footer><h2>Registrar la escucha</h2>
<p>Comenta en <a href="https://github.com/EspacioKoop/expediente-legado/issues/1475">#1475</a>
indicando los identificadores del audio, instante y qué mejorarías.
El issue enlaza la PR vigente, sus pruebas y la discusión.</p>
<p><a href="REVISION.md">Ficha de revisión</a> · <a href="manifest.json">Parámetros y hashes</a></p>
<p class="nota">WAV PCM originales, sin conversión con pérdidas. La página funciona
sin conexión tras descomprimir el ZIP entero. __LIMITES__</p></footer>
<script>
const audios = [...document.querySelectorAll('audio')];
audios.forEach(audio => audio.addEventListener('play', () => {
  audios.forEach(otro => { if (otro !== audio) otro.pause(); });
}));
document.querySelector('#parar').addEventListener('click', () => {
  audios.forEach(audio => { audio.pause(); audio.currentTime = 0; });
});
</script></body></html>
"""
    for clave, valor in {"TITULO": escape(titulo), "DESCRIPCION": escape(descripcion),
                         "INSTRUCCIONES": escape(instrucciones), "LIMITES": escape(limites),
                         "ESTUDIO": estudio, "BANCO": banco}.items():
        pagina = pagina.replace(f"__{clave}__", valor)
    (destino / "escucha.html").write_text(pagina, encoding="utf-8")


def generar_cata(receta: Path, destino: Path) -> dict:
    """Cuatro celdas; calibración por timbre congelada para ambos motivos."""
    cfg = json.loads(receta.read_text(encoding="utf-8"))
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("la cata 2x2 requiere FFmpeg para calibrar sonoridad")
    if (RAIZ / "godot").resolve() in destino.resolve().parents or destino.resolve() == (RAIZ / "godot").resolve():
        raise ValueError("la cata no escribe dentro del runtime")
    if (cfg["id"] != "cata_motivos_timbres" or set(cfg["motivos"]) != {"m01", "m02"}
            or set(cfg["timbres"]) != {"t01", "t02"}
            or cfg["duracion_s"] != 10 or cfg["bpm"] != 96
            or cfg["inicios_frase_s"] != [0.5, 5.5] or cfg["puerta_s"] != 0.25
            or not 0 < cfg["ganancia_evento"] <= 0.3
            or not -18 <= cfg["pico_techo_dbfs"] <= -9
            or not -30 <= cfg["calibracion_lufs"] <= -24
            or not 0 < cfg["tolerancia_calibracion_lu"] <= 0.5):
        raise ValueError("receta fuera del protocolo de cata 2x2")
    timbres = cfg["timbres"]
    for fuente in timbres.values():
        if any(fuente[k] != v for k, v in {"tipo": "fm", "hz": 220, "muestras": 28224, "caida": 6}.items()):
            raise ValueError("los timbres deben compartir raíz, duración y envolvente")
    fuentes_pcm = {nombre: pcm16(sintetizar(fuente)) for nombre, fuente in timbres.items()}
    banco = {nombre: [x[0] / 32768 for x in struct.iter_unpack("<h", pcm)]
             for nombre, pcm in fuentes_pcm.items()}
    memoria = sum(len(x) * 2 for x in banco.values())
    if not 0 < memoria <= cfg["max_banco_pcm_bytes"] <= 131072:
        raise ValueError("presupuesto PCM excedido")
    partituras, renders = {}, {}
    n = round(cfg["duracion_s"] * SR)
    for motivo, datos in cfg["motivos"].items():
        filas, tonos = datos["filas"], datos["semitonos"]
        if (not 2 <= len(filas) == len(tonos) <= 8 or filas != sorted(set(filas))
                or any(type(f) is not int or not 0 <= f < 16 for f in filas)
                or any(type(t) is not int or not -12 <= t <= 12 for t in tonos)):
            raise ValueError("partitura inválida")
        notas = [dict(inicio=round((inicio + fila * 15 / cfg["bpm"]) * SR),
                      muestras=round(cfg["puerta_s"] * SR), ratio=2 ** (tono / 12),
                      ganancia=cfg["ganancia_evento"], pan=0, offset=0, bucle=False)
                 for inicio in cfg["inicios_frase_s"] for fila, tono in zip(filas, tonos)]
        if contar_voces(notas) != 1:
            raise ValueError("la cata debe conservar una voz sin solapamientos")
        partituras[motivo] = notas
        for timbre in timbres:
            renders[motivo, timbre] = mezclar(banco, [dict(e, instrumento=timbre) for e in notas], n)

    def programa(timbre: str) -> list[array]:
        return [array("d", (x for motivo in cfg["motivos"] for x in renders[motivo, timbre][c]))
                for c in range(2)]

    calibracion = {}
    with tempfile.TemporaryDirectory() as temporal:
        for timbre in timbres:
            ruta = Path(temporal) / f"{timbre}.wav"
            escribir_wav(ruta, programa(timbre))
            medida = medir_ffmpeg(ruta, ffmpeg)
            if not math.isfinite(medida["programa_lufs_i"]):
                raise ValueError("no hay señal suficiente para calibrar")
            ganancia = 10 ** ((cfg["calibracion_lufs"] - medida["programa_lufs_i"]) / 20)
            calibracion[timbre] = dict(lufs_antes=medida["programa_lufs_i"], ganancia=ganancia)
        pico = max(abs(x) * calibracion[t]["ganancia"]
                   for (_, t), render in renders.items() for canal in render for x in canal)
        comun = min(1.0, 10 ** (cfg["pico_techo_dbfs"] / 20) / pico)
        for (_, timbre), render in renders.items():
            for canal in render:
                for i in range(len(canal)):
                    canal[i] *= calibracion[timbre]["ganancia"] * comun
        for timbre in timbres:
            ruta = Path(temporal) / f"{timbre}.wav"
            escribir_wav(ruta, programa(timbre))
            calibracion[timbre]["lufs_despues"] = medir_ffmpeg(ruta, ffmpeg)["programa_lufs_i"]
    niveles = [x["lufs_despues"] for x in calibracion.values()]
    if max(niveles) - min(niveles) > cfg["tolerancia_calibracion_lu"]:
        raise ValueError("la calibración supera la tolerancia entre timbres")
    destino.mkdir(parents=True, exist_ok=True)
    salidas = []
    for (motivo, timbre), render in renders.items():
        ruta = destino / f"{motivo}_{timbre}.wav"
        escribir_wav(ruta, render)
        medida = dict(**medir_wav(ruta), **medir_ffmpeg(ruta, ffmpeg))
        if (medida["clipping"] or medida["true_peak_dbtp"] > -6
                or max(map(abs, medida["dc_por_canal"])) > 0.0001
                or medida["mono_delta_db"] < -3):
            raise ValueError("celda fuera del gate técnico de cata")
        salidas.append(dict(archivo=ruta.name, motivo=motivo, timbre=timbre, **medida))
    manifest = dict(issue=1475, estudio=cfg["id"], receta_sha256=sha256(receta.read_bytes()),
                    generador_sha256=sha256(Path(__file__).read_bytes()),
                    biblia_sha256=sha256((RAIZ / "docs/audio/biblia-sonora-1475.md").read_bytes()),
                    python=platform.python_version(),
                    ffmpeg=subprocess.run([ffmpeg, "-version"], capture_output=True, text=True,
                                          check=True).stdout.splitlines()[0],
                    frecuencia_hz=SR, voces_maximas=1, banco_pcm_bytes=memoria,
                    fuentes={t: dict(origen="sintesis_original", licencia="MIT", receta=timbres[t],
                                     sha256_pcm=sha256(fuentes_pcm[t])) for t in timbres},
                    calibracion=calibracion, atenuacion_comun=comun, renders=salidas,
                    escucha_humana="pendiente", limite="Boceto T01; no SPU-98/FM-98 completos ni prueba en juego.")
    for nombre, datos in (("manifest.json", manifest), ("partitura.json", partituras), ("receta.json", cfg)):
        (destino / nombre).write_text(json.dumps(datos, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for nombre, orden in (("cata.m3u", salidas), ("cata_inversa.m3u", list(reversed(salidas)))):
        (destino / nombre).write_text("#EXTM3U\n" + "\n".join(r["archivo"] for r in orden) + "\n", encoding="utf-8")
    (destino / "REVISION.md").write_text(
        "# Cata 2×2 — escucha pendiente\n\nDescomprimir todo y abrir escucha.html.\n\n"
        "Cuatro clips: M01_T01, M01_T02, M02_T01, M02_T02. Cada uno dura 10 s.\n"
        "Comparar por motivo y por timbre; repetir en orden inverso.\n"
        "Anotar SHA del manifest, orden, dispositivo, volumen relativo, instante y observación.\n"
        "Preguntas: ¿se distingue cada motivo?, ¿se reconoce con el otro timbre?, "
        "¿qué ataque o cola molesta?, ¿qué se recuerda tras una pausa registrada?\n"
        "Decisión: iterar / descartar / candidato. Registrar en #1475.\n\n"
        "Nivel calibrado por timbre sobre M01+M02; no por clip. No garantiza igual percepción.\n"
        "No valida lectura, fatiga prolongada, mezcla runtime, fidelidad de chip ni producción.\n",
        encoding="utf-8")
    escribir_escucha(destino, salidas, [])
    return manifest


def generar(receta: Path, destino: Path, exigir_ffmpeg: bool = False) -> dict:
    cfg = json.loads(receta.read_text(encoding="utf-8"))
    if cfg["id"] != "oficina_machine_pulse" or not 20 <= cfg["duracion_s"] <= 45:
        raise ValueError("receta o duración fuera del primer estudio")
    if not 1 <= cfg["max_voces"] <= 24 or not 0 < cfg["max_banco_adpcm_bytes"] <= 512 * 1024:
        raise ValueError("presupuesto de voces/memoria inválido")
    if not -18 <= cfg["pico_techo_dbfs"] <= -6:
        raise ValueError("techo de cata sin margen suficiente")
    ffmpeg = shutil.which("ffmpeg")
    if exigir_ffmpeg and not ffmpeg:
        raise RuntimeError("falta FFmpeg para medir el true peak requerido")
    if (RAIZ / "godot").resolve() in destino.resolve().parents or destino.resolve() == (RAIZ / "godot").resolve():
        raise ValueError("el laboratorio no escribe dentro del runtime")
    limpios, tratados, comprimidos, fichas = {}, {}, {}, []
    for nombre, fuente in cfg["banco"].items():
        if not re.fullmatch(r"[a-z0-9_]+", nombre):
            raise ValueError("identificador instrumental inválido")
        muestras = sintetizar(fuente)
        pcm = pcm16(muestras)
        enteros = [x[0] for x in struct.iter_unpack("<h", pcm)]
        comprimidos[nombre] = codificar_adpcm(enteros, fuente["tipo"] == "ciclo")
        limpios[nombre] = [x / 32768 for x in enteros]
        tratados[nombre] = [x / 32768 for x in decodificar_adpcm(comprimidos[nombre])]
        fichas.append(dict(id=nombre, origen="sintesis_original_no_grabacion", licencia="MIT",
                           autor="Proyecto SIGA-98; receta y generador originales",
                           pcm_bytes=len(pcm), adpcm_bytes=len(comprimidos[nombre]),
                           sha256_pcm=sha256(pcm), sha256_adpcm=sha256(comprimidos[nombre])))
    memoria = sum(len(x) for x in comprimidos.values())
    partitura = eventos(cfg, limpios)
    voces = contar_voces(partitura)
    if memoria > cfg["max_banco_adpcm_bytes"] or voces > cfg["max_voces"]:
        raise ValueError("se excede el presupuesto de memoria o voces")
    renders = [mezclar(banco, partitura, round(cfg["duracion_s"] * SR)) for banco in (limpios, tratados)]
    pico = max(abs(x) for render in renders for canal in render for x in canal)
    if not math.isfinite(pico) or pico <= 0:
        raise ValueError("estudio vacío o no finito")
    ganancia = 10 ** (cfg["pico_techo_dbfs"] / 20) / pico
    destino.mkdir(parents=True, exist_ok=True)
    banco_dir = destino / "banco"
    banco_dir.mkdir(exist_ok=True)
    for ficha in fichas:
        nombre = ficha["id"]
        for variante, banco in (("limpio", limpios), ("adpcm", tratados)):
            ruta = banco_dir / f"{nombre}_{variante}.wav"
            escribir_wav(ruta, [banco[nombre]])
            ficha[variante] = medir_wav(ruta)
        (banco_dir / f"{nombre}.spu").write_bytes(comprimidos[nombre])
    salidas = []
    for variante, render in zip(("limpio", "psx_adpcm"), renders):
        for canal in render:
            for i in range(len(canal)):
                canal[i] *= ganancia
        ruta = destino / f"{cfg['id']}_{variante}.wav"
        escribir_wav(ruta, render)
        medicion = medir_wav(ruta)
        if ffmpeg:
            medicion.update(medir_ffmpeg(ruta, ffmpeg))
        if (medicion["clipping"] or max(map(abs, medicion["dc_por_canal"])) > 0.0001
                or medicion.get("true_peak_dbtp", medicion["pico_dbfs"]) > -6
                or medicion["mono_delta_db"] < -3):
            raise ValueError("el render no supera el gate técnico de cata")
        salidas.append(dict(archivo=ruta.name, **medicion))
    version_ffmpeg = (subprocess.run([ffmpeg, "-version"], capture_output=True, text=True,
                                     check=True).stdout.splitlines()[0] if ffmpeg else None)
    manifest = dict(issue=1475, estudio=cfg["id"], version_receta=cfg["version"],
                    receta_sha256=sha256(receta.read_bytes()),
                    generador_sha256=sha256(Path(__file__).read_bytes()), python=platform.python_version(),
                    ffmpeg=version_ffmpeg, frecuencia_hz=SR, voces_maximas=voces,
                    banco_adpcm_bytes=memoria, banco_pcm_bytes=sum(f["pcm_bytes"] for f in fichas),
                    ganancia_comun=ganancia, banco=fichas, renders=salidas,
                    eventos=len(partitura), escucha_humana="pendiente",
                    limite="ADPCM por instrumento; interpolacion lineal y mezcla moderna. No SPU completa.")
    (destino / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (destino / "partitura.json").write_text(json.dumps(partitura, indent=2) + "\n", encoding="utf-8")
    (destino / "cata.m3u").write_text("#EXTM3U\n" + "\n".join(r["archivo"] for r in salidas) + "\n", encoding="utf-8")
    escribir_escucha(destino, salidas, fichas)
    (destino / "REVISION.md").write_text(
        "# Cata oficina_machine_pulse — pendiente\n\n"
        "Abrir escucha.html en el navegador tras descomprimir el ZIP completo.\n\n"
        "A=limpio; B=SPU-ADPCM por instrumento. Ganancia común; sin reverb.\n"
        "Escuchar completos A/B y banco, alternar a igual volumen; consultar delta RMS.\n"
        "Comprobar auriculares, altavoces/TV, mono, volumen bajo y repetición prolongada.\n"
        "No son loops de programa: ambos estudios terminan en silencio.\n\n"
        "| Revisión | Observación |\n| --- | --- |\n"
        "| Identidad / burocracia reconocible | pendiente |\n"
        "| Transitorios / graves / fatiga | pendiente |\n"
        "| Costura del instrumento red | pendiente |\n"
        "| Aporta ADPCM o empeora | pendiente |\n"
        "| Decisión: iterar / descartar / candidato | pendiente |\n\n"
        "La cata no demuestra traducción a hardware ni ausencia de enmascaramiento en juego.\n"
        "Registrar decisión y SHA del manifest en #1475; producción requiere #1471/#76/#119.\n",
        encoding="utf-8")
    return manifest


def generar_careo_tracker(destino: Path) -> dict:
    """Bucle breve y autosuficiente para contrastar dos voces en careo."""
    if (RAIZ / "godot").resolve() in destino.resolve().parents or destino.resolve() == (RAIZ / "godot").resolve():
        raise ValueError("el laboratorio no escribe dentro del runtime")
    banco_cfg = {
        "argumento": {"tipo": "fm", "hz": 220, "muestras": 13230, "semilla": 2324,
                      "indice_fm": 1.8, "ratio_fm": 2, "caida": 5},
        "replica": {"tipo": "fm", "hz": 330, "muestras": 13230, "semilla": 1475,
                     "indice_fm": 2.4, "ratio_fm": 3, "caida": 6},
        "pulso": {"tipo": "ciclo", "hz": 55, "muestras": 4410, "semilla": 76,
                   "indice_fm": 0, "ratio_fm": 1, "caida": 0},
    }
    limpios, fichas = {}, []
    for nombre, fuente in banco_cfg.items():
        pcm = pcm16(sintetizar(fuente))
        limpios[nombre] = [x[0] / 32768 for x in struct.iter_unpack("<h", pcm)]
        fichas.append(dict(id=nombre, origen="sintesis_original_no_grabacion", receta=fuente,
                           pcm_bytes=len(pcm), sha256_pcm=sha256(pcm)))
    duracion_s, pasos = 8, 16
    paso = round(SR * duracion_s / pasos)
    partitura = []
    for indice in range(pasos):
        inicio = indice * paso
        partitura.append(dict(instrumento="pulso", inicio=inicio, muestras=paso,
                              ratio=1, ganancia=0.11, pan=0, offset=0, bucle=True))
        if indice % 4 in (0, 2):
            partitura.append(dict(instrumento="argumento", inicio=inicio, muestras=round(SR * 0.22),
                                  ratio=2 ** ((0, 3, 5, 3)[indice // 4] / 12), ganancia=0.28,
                                  pan=-0.45, offset=0, bucle=False))
        if indice % 4 in (1, 3):
            partitura.append(dict(instrumento="replica", inicio=inicio, muestras=round(SR * 0.18),
                                  ratio=2 ** ((7, 5, 3, 5)[indice // 4] / 12), ganancia=0.24,
                                  pan=0.45, offset=0, bucle=False))
    voces = contar_voces(partitura)
    memoria = sum(ficha["pcm_bytes"] for ficha in fichas)
    if voces > 24 or len(fichas) > 4:
        raise ValueError("el careo excede el presupuesto declarado")
    render = mezclar(limpios, partitura, duracion_s * SR)
    pico = max(abs(x) for canal in render for x in canal)
    ganancia = 10 ** (-9 / 20) / pico
    for canal in render:
        for i in range(len(canal)):
            canal[i] *= ganancia
    destino.mkdir(parents=True, exist_ok=True)
    ruta = destino / "careo_tracker.wav"
    escribir_wav(ruta, render)
    medida = medir_wav(ruta)
    if medida["clipping"] or max(map(abs, medida["dc_por_canal"])) > 0.0001:
        raise ValueError("el render careo_tracker no supera el gate técnico")
    salida = dict(archivo=ruta.name, **medida)
    manifest = dict(issue=2324, estudio="careo_tracker", generador_sha256=sha256(Path(__file__).read_bytes()),
                    frecuencia_hz=SR, duracion_s=duracion_s, voces_maximas=voces,
                    limite_voces=24, banco_pcm_bytes=memoria, banco_pequeno_max_fuentes=4,
                    banco=fichas, bucle=dict(inicio_muestras=0, fin_muestras=duracion_s * SR,
                                              inicio_s=0, fin_s=duracion_s,
                                              descripcion="Repetir careo_tracker.wav completo desde 0 s hasta 8 s."),
                    partitura_sha256=sha256(json.dumps(partitura, sort_keys=True).encode()),
                    renders=[salida], escucha_humana="pendiente",
                    limite="Boceto offline; no runtime, asset de producción ni emulación de hardware.")
    (destino / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (destino / "partitura.json").write_text(json.dumps(partitura, indent=2) + "\n", encoding="utf-8")
    escribir_escucha(destino, [salida], [])
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--receta", type=Path, default=RECETA)
    parser.add_argument("--destino", type=Path)
    parser.add_argument("--cata-motivos-timbres", action="store_true")
    parser.add_argument("--careo-tracker", action="store_true")
    parser.add_argument("--exigir-ffmpeg", action="store_true")
    args = parser.parse_args()
    if args.cata_motivos_timbres and args.careo_tracker:
        parser.error("--cata-motivos-timbres y --careo-tracker son excluyentes")
    destino = args.destino or RAIZ / "dist/salida" / (
        "careo_tracker_2324"
        if args.careo_tracker
        else "cata_motivos_timbres_1475" if args.cata_motivos_timbres else "laboratorio_1475"
    )
    if args.careo_tracker:
        manifest = generar_careo_tracker(destino)
    elif args.cata_motivos_timbres:
        receta = RECETA_CATA if args.receta == RECETA else args.receta
        manifest = generar_cata(receta, destino)
    else:
        manifest = generar(args.receta, destino, args.exigir_ffmpeg)
    print(json.dumps({k: manifest[k] for k in ("voces_maximas", "renders")}, indent=2))


if __name__ == "__main__":
    main()
