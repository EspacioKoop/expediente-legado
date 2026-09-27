# Laboratorio sonoro #1475 — estudio y cata 2×2

Entrega principal: **dos motivos × dos timbres**, cuatro clips de 10 segundos,
generados después del estudio y sus tres revisiones especializadas.
Antecedente técnico: `oficina_machine_pulse`, 28 segundos, A limpio/B ADPCM.
Pendientes: `careo_tracker`, `casa_chip`, `sueno_memory` y sus catas humanas.
Dirección e investigación: [biblia-sonora-1475.md](biblia-sonora-1475.md).

## Escuchar sin instalar herramientas

En el [checkpoint vigente de #1475](https://github.com/EspacioKoop/expediente-legado/issues/1475), abrir
el enlace al paquete de escucha, descargar el ZIP de Actions (requiere sesión de
GitHub), **descomprimirlo entero y abrir `escucha.html`** en el navegador.
Incluye cuatro reproductores: M01/T01, M01/T02, M02/T01 y M02/T02.
Reproducir uno pausa el anterior; «Parar todos» los detiene.
Los WAV se reproducen sin recodificación. Funciona sin conexión y sin arrancar
el juego. El último checkpoint de escucha del PR contiene el enlace vigente.

La cata usa PCM limpio, una voz, 96 BPM, raíz 220 Hz y puerta de 0,25 s.
Ambos timbres comparten envolvente y duración; cambia el espectro FM. El nivel
se calibra por timbre sobre los dos motivos concatenados y se mantiene fijo
entre ellos. No se añaden ADPCM, acompañamiento ni reverb a estos cuatro clips.
Su alcance es compositivo T01; no demuestra emulación SPU-98/FM-98 ni sustituye
la cata en contexto o las futuras T18/T21 del plan.

## Auditoría del audio existente

Base leída: `0359555d969c3e609e9c48f03631c543769b8cdd` (2026-09-27).

| Contrato / archivo | Estado observado | Consecuencia |
| --- | --- | --- |
| `godot/guion/sonido.gd` | Catálogo Kenney CC0, pasos por suelo, familias y voces 3D | Reemplazos propios pasan por #1471/#76; sin segundo catálogo |
| `godot/guion/musica.gd` | `careo`/`final` vacíos; careo repite, final una pasada | No hay pista que la síntesis de laboratorio deba sustituir automáticamente |
| `careo_app.gd` y final político | Inicio/parada/limpieza conectados según #1279/#1326 | La deuda es contenido y escucha, no otro controlador |
| `godot/guion/ambiente.gd` | Cuatro fases, cache procedural a 22,05 kHz, contexto adaptativo y crossfade 0,35 s | Preservar #119/#966 |
| `dia_clima_app.gd` | Consume Ambiente a -24 dB con contexto | Comprobar mezcla futura en ese recorrido real |
| `mezcla_audio.gd` / bus layout | Efectos, Ambiente y Musica hacia Master; niveles/mute persistentes | Reutilizar buses y Opciones |
| `scripts/generar_ambientes_originales.py` | Cuatro recetas ambientales y OGG vía FFmpeg | Material previo útil, no duplicar su cata |
| `scripts/preparar_cata_ambientes.py` | Repeticiones, playlist, métricas PCM fuente y revisión humana | Conservar flujo; nueva cata musical mide además el WAV final |
| `.gitattributes` / `assets/procedencia.json` | WAV y nueva música OGG con LFS; procedencia de assets | Este corte versiona código/receta, no punteros sin objeto |

La cabecera histórica de `Sonido` aún dice que falta ambiente; el contrato vivo
de `Ambiente` y #119 confirma que existe. No se cambia esa ruta fuera de reserva.
Se revisaron cuerpos y comentarios de #181/#182/#76/#119/#1471/#1475, ramas de
audio y PRs abiertas. En ese momento solo #1469 estaba abierta y trataba UI 4K.
Este inventario no demuestra escucha ni describe cambios futuros de `main`.

## Reproducir

Python 3.11+; biblioteca estándar. FFmpeg es el único ejecutable adicional para
true peak/LUFS y ya se utiliza en la cata #119. Sin Godot, tracker, NumPy ni red.

```bash
python3 -m unittest -v scripts/test_laboratorio_sonoro_1475.py
python3 scripts/laboratorio_sonoro_1475.py --cata-motivos-timbres --exigir-ffmpeg
```

Salida ignorada por Git: `dist/salida/cata_motivos_timbres_1475/`. Abrir `escucha.html` en el
navegador, `cata.m3u` en un reproductor local o los WAV individualmente.
El workflow **Laboratorio sonoro 1475** adjunta el mismo paquete durante 14 días,
con el SHA de Actions en el nombre; después se puede regenerar desde la rama/PR.

| Salida | Contenido |
| --- | --- |
| `escucha.html` | Cuatro reproductores de la matriz motivos/timbres, sin servidor |
| `m01_t01.wav`, `m01_t02.wav`, `m02_t01.wav`, `m02_t02.wav` | Cuatro cruces PCM estéreo 16-bit/44,1 kHz, 10 s cada uno |
| `receta.json`, `partitura.json`, `manifest.json` | Parámetros, eventos, hashes, niveles y ganancias de calibración |
| `REVISION.md`, `cata.m3u`, `cata_inversa.m3u` | Protocolo y órdenes de comparación |

El antecedente de oficina se regenera sin `--cata-motivos-timbres`, en
`dist/salida/laboratorio_1475/`; el codec sigue conservando su propio A/B.

| Salida del antecedente | Contenido |
| --- | --- |
| `oficina_machine_pulse_limpio.wav` | A, PCM estéreo 16-bit/44,1 kHz |
| `oficina_machine_pulse_psx_adpcm.wav` | B, misma partitura/ganancia; codec por instrumento |
| `banco/*_limpio.wav`, `banco/*_adpcm.wav` | Fuentes para escuchar e importar manualmente a un tracker |
| `banco/*.spu` | Bloques comprimidos de experimento; no fichero VAG ni paquete de consola |
| `partitura.json` | Eventos efectivos con tiempos, tono, offset, ganancia y duración |
| `manifest.json` | Hashes, versiones, memoria, voces y medidas de los WAV |
| `REVISION.md`, `cata.m3u` | Ficha humana y orden A/B |

Las salidas son síntesis MIT propia; las fuentes técnicas se consultan, no se
incorporan sus muestras, tablas o implementaciones. El manifest distingue la
huella PCM de entrada al codec de la huella de cada WAV emitido. No representa
una entrada en el inventario de assets distribuibles del juego.

## Qué se oye y qué se compara

0–0,5 s: margen inicial. Patrones desde 0,5 s, de 2,5 s cada uno: aire → pulso →
pulso → respuesta → aire → tensión → respuesta → pulso → aire → salida.
El estudio termina con margen de silencio; no es un loop continuo de gameplay.
Un motivo de tres alturas de `carro` conecta las respuestas; `sello` organiza
el tiempo y `tecla` aporta ráfagas, delay y cortes. El loop `red` dura 40 ms.

Las cuatro fuentes comparten límite de brillo y se reutilizan, en lugar de
sintetizar una muestra distinta por nota. El presupuesto es 24 voces activas
(incluyendo toda duración de cada evento) y 32 KiB ADPCM para este banco.
No contabiliza memoria del secuenciador, buffers ni reverb de una consola.

El encoder explora cinco predictores y shifts válidos minimizando error con el
historial reconstruido. Empieza con predictor cero para poder repetir la fuente
sin depender de la pasada anterior. El decoder solo hace una pasada; no emula
key-on/off, IRQs, ADSR ni gaussiana. El sampler repite el PCM cuando corresponde.
No se afirma compatibilidad bit-perfect ni carga directa del banco en una PS1.

## Verificación y límites

Tests: vectores manuales de nibbles firmados/predictor, historial entre bloques,
silencio, flags, error de codificación, semillas, timing/retrigger/offset, conteo
de colas, rechazo de entradas inválidas, mezcla determinista y export completo.
El workflow genera dos paquetes y exige igualdad byte a byte en el mismo entorno.
Entre plataformas/versiones, libm o FFmpeg pueden variar: se guardan versiones y
hashes, no se promete identidad universal. Los códigos JSON no son efectos XM.

El export rechaza clipping, DC de programa mayor que 0,0001, pico/true peak sin
6 dB de margen y pérdida mono superior a 3 dB. Son gates de regresión de esta
cata. No son una norma universal de mastering ni validación de escucha.
La prueba principal ejecuta el WAV real; FFmpeg mide true peak del programa
cuando está disponible, y `--exigir-ffmpeg` impide omitirlo en el artifact.

En este entorno inicial no están Godot, GDExtension/ROMs, gdtoolkit ni Maven.
La CI canónica del PR deberá validar el SHA antes de `PR_READY`. No se rebajan
gates, no se afirma que la suite del juego haya pasado localmente.
La pasada Python general sobre el checkout sin materializar LFS ejecutó 2499
tests con 50 fallos, 46 errores y 142 saltos; por tanto no es un preflight verde.
El workflow canónico descarga LFS y prepara la toolchain completa.

## Cooperación y siguiente corte

Reserva #182 limitada a seis rutas de la continuación, incluida la receta 2×2. No bloquea el
runtime, todo el audio, `main` ni todo #1475. El checkpoint vigente vive en el
issue; la PR conserva SHA, pruebas, artifact y limitaciones. No usar este documento
como una segunda cola ni inferir permiso de merge o propiedad de archivos ajenos.

Tras CI: escuchar la cata 2×2 y registrar observaciones por motivo y timbre.
ADPCM conserva una comparación técnica separada. Después decidir el siguiente
corte de composición conforme al plan del issue;
casa y sueño llegarán con fuentes y motivos trazables. Cualquier promoción al
juego exige el gate humano y los contratos de #1471/#76/#119. Esta PR no cierra
ninguno de esos issues ni #1475.
