# Biblia sonora SIGA-98 — laboratorio inicial

Dirección: [#1475](https://github.com/EspacioKoop/expediente-legado/issues/1475).
Producción/foley: #1471. Música/efectos puntuales: #76. Ambientes/buses: #119.
Esta propuesta no acredita una decisión de escucha ni cambia el audio del juego.
Ejecución y auditoría: [laboratorio-1475.md](laboratorio-1475.md).

## 1. Identidad musical

La burocracia se convierte en instrumento: golpes, resonancias y ciclos de trabajo
comparten una familia tímbrica con casa y sueño. Motivos cortos, reutilización de
fuentes y silencios deliberados. Evitar que cada escena parezca otra banda sonora.

| Espacio | Propuesta de composición | Límite |
| --- | --- | --- |
| Oficina | Pulsos discontinuos, electricidad, respuestas de máquinas | Estudio de paleta; no autoriza una banda sonora permanente |
| Careo | Mismo banco, bajo FM sampleado, ritmo seco y densidad creciente | Música puntual según #76 |
| Casa | Motivo íntimo, pocos canales, campana/FM suave y ciclo cálido | Refugio ambiguo; no alegría automática |
| Sueño | Material reconocible desordenado | No sustituir memoria por un preset de terror |
| Clímax | Recuperar y desarrollar los motivos anteriores | Densidad con contraste, no volumen constante |

## 2. Identidad de foley

El banco inicial es **síntesis original**, no grabaciones: `sello`, `tecla`,
`carro` y `red` describen conceptos, no objetos capturados. Sus WAV limpios se
conservan junto al experimento ADPCM.

Cuando haya tomas propias: conservar original, seleccionar gesto, editar ruido/DC,
afinar si tiene función musical, elegir loop/envolvente, generar variantes y
comparar en contexto. Sustituir una fuente exige una receta/procedencia explícita,
no renombrar una grabación para hacerla pasar por el sintetizador actual.
Primera sesión propuesta: sello, teclado, cajón metálico y aparato eléctrico;
varias intensidades y perspectivas. Nadie ha realizado todavía esa sesión.

## 3. Ambientes

Reutilizar `Ambiente`, su contexto adaptativo y la [cata #119](cata-ambientes-119.md).
Una máquina musical no sustituye la cama de oficina ni crea un segundo bus.
Contrastar posteriormente contra pasos, interacción e información importante.
Separar continuidad ambiental de la entrada dramática de música.

## 4. Sueño: memoria digital deformada

Siguiente experimento: recortar fragmentos identificados por SHA y posición de
los estudios anteriores; reorganizarlos con reverse, offset, transposición y
granos con ventanas solapadas. Registrar cada origen y transformación. Comparar
con el motivo original a igual nivel. Pitch cambia duración; timestretch la
desacopla: no confundir ambas operaciones. Granularidad y espacialización son
decisiones nuestras, no funciones nativas de la SPU. Todavía no se implementan.

## 5. Música dramática

`careo_tracker` será el siguiente corte tras escuchar oficina: motivo compartido,
escalada por variación rítmica y capas; export corto de 20–45 s. Investigar primero
un XM nativo con MilkyTracker y comparar su render con OpenMPT. `final` debe
resolver el material con una sola pasada; no cambiar su contrato por comodidad.

## 6. PSX: hardware, aproximación y decisión artística

Base técnica: [PSX-SPX, SPU](https://github.com/psx-spx/psx-spx.github.io/blob/master/docs/ps1/spu/soundprocessingunitspu.md),
documentación de ingeniería inversa, no manual oficial de Sony. Consultada
2026-09-27; blob `abdaede3693b2e5d5285824e08e48f586680d97b`.

| Hardware documentado | Experimento actual / diferencia |
| --- | --- |
| 24 voces; salida a 44,1 kHz | Contador de voces activas con límite 24; WAV a 44,1 kHz |
| 512 KiB de RAM compartida por muestras, captura y reverb | Presupuesto artístico de 32 KiB para el banco ADPCM; no mapa completo de RAM |
| SPU-ADPCM: 28 muestras por bloque de 16 bytes, cinco predictores | Encoder/decoder offline propio; flags escritos, reproducción de una pasada |
| Playback sampleado, pitch y ADSR por voz | Pitch ±12 semitonos, caídas sintéticas y rampas propias; no ADSR exacto |
| Interpolación de cuatro puntos conocida como gaussiana | Interpolación lineal; no se etiqueta como gaussiana |
| PMON usa la voz anterior para modular pitch | No implementado; nuestra FM se sintetiza antes de samplear |
| Noise hardware compartido, habilitable por voz | Ruido pseudoaleatorio offline; no emulación del generador |
| Flags de loop y dirección de repetición | Repetición del PCM decodificado; no emulación del estado SPU |
| Reverb estéreo con área de RAM y procesamiento a media frecuencia | Desactivada en A/B; futura comparación independiente |
| Entradas CD-DA/XA adicionales | Fuera del experimento; XA no es el empaquetado SPU-ADPCM |

El banco limitado y la secuencia por patrones son decisiones de producción.
Un fichero XM no es un formato nativo de la SPU. No imponemos que toda música PS1
usase tracker: el chip reproduce voces; el software organiza la composición.
El primer A/B solo responde «¿qué aporta ADPCM a estas fuentes?».

Los [formatos de audio PS1](https://github.com/psx-spx/psx-spx.github.io/blob/master/docs/ps1/cdr/cdromfileformats/audio.md)
documentan VAG para muestras, VAB/VH/VB para bancos y SEQ para secuencias.
Separar banco de eventos permite reutilizar una muestra con diferentes notas y
envolventes; no obliga a usar esos contenedores en Godot. El algoritmo predictivo
y sus coeficientes se contrastaron también con
[CDROM format](https://github.com/psx-spx/psx-spx.github.io/blob/master/docs/ps1/cdr/cdromformat.md),
conservando el empaquetado de bloques SPU, no el de sectores XA.

## 7. Técnicas tracker y compatibilidad

Fuentes: [manual de MilkyTracker](https://milkytracker.org/docs/manual/MilkyTracker.html)
y [referencia de OpenMPT](https://wiki.openmpt.org/Manual:_Effect_Reference),
consultadas 2026-09-27. MilkyTracker persigue compatibilidad FT2/XM; OpenMPT
documenta diferencias entre formatos y extensiones. Fijar reproductor y ajustes
al comparar: no asumir que exportar MOD/XM/IT/S3M preserva todos los efectos.

| Técnica | Códigos MOD/XM de referencia | Uso propuesto |
| --- | --- | --- |
| Arpegio | `0xy` | Insinuar acorde con una voz |
| Portamento | `1xx`, `2xx`, `3xx` | Motor que cambia de esfuerzo |
| Vibrato / tremolo | `4xy` / `7xy` | Inestabilidad de tono / amplitud |
| Retrigger | `E9x`, XM `Rxy` | Ráfaga mecánica con función rítmica |
| Sample offset | `9xx` | Elegir otro ataque del mismo objeto |
| Note cut / delay | `ECx` / `EDx` | Silencio y desplazamiento del acento |
| Velocidad / tempo | `Fxx` | Cambiar articulación y densidad |
| Orden / patrón | `Bxx`, `Dxx`, `E6x` | Repetición y ruptura estructural |

No trasladar estos códigos literalmente a IT/S3M. El laboratorio usa JSON con
filas, ticks, orden, offset, puerta y retrigger explícitos; **no implementa FT2**,
memoria de efectos ni importación/exportación XM. Arpegio/portamento/vibrato/tremolo
quedan investigados, no implementados. Evitar comandos de surround por inversión
de fase que comprometan mono. Loops cortos y transposición amplia necesitan
escucha de costuras y espectro, no solo notas correctas.

## 8. Síntesis y banco

[Furnace OPN](https://github.com/tildearrow/furnace/blob/master/doc/4-instrument/fm-opn.md)
expone algoritmos de cuatro operadores, envolventes y macros;
[wavesynth](https://github.com/tildearrow/furnace/blob/master/doc/4-instrument/wavesynth.md)
combina/modula tablas. Su [exportador](https://github.com/tildearrow/furnace/blob/master/doc/2-interface/export.md)
permite WAV por canción, chip o canal. Consultados 2026-09-27.

Receta propuesta en Furnace: diseñar un timbre aislado sin material externo,
exportar WAV mono a 44,1 kHz, conservar `.fur`, versión y ajustes; recortar y
construir el banco antes de secuenciar. PSG/pulse para motivos pequeños, FM para
bajos/campanas/metales, tablas/single-cycle para pads y leads, ruido para
percusión. No se ha ejecutado Furnace en este corte: el equivalente reproducible
ensayado es Python (FM de dos osciladores, ruido y ciclo aditivo).

Flujo elegido: síntesis → PCM limpio → banco → ADPCM opcional por instrumento →
patrones → render → mezcla moderna. Degradar todo el master ocultaría qué
instrumento gana carácter y cuál pierde articulación. Se conserva A/B del banco.

## 9. Mezcla y evaluación

Filtro de fuentes a 5,5 kHz antes de transponer, rampas de 3 ms, DC blocker
común a 20 Hz y ganancia común para A/B. Son decisiones de mezcla modernas.
La restricción de pitch evita exigir a este resampler lineal un rango extremo;
no se garantiza aliasing nulo, especialmente tras ADPCM.

El techo de -9 dBFS deja margen en **esta cata**, no define el nivel del juego.
Registrar pico/true peak, DC, clipping, RMS, delta mono y loudness del programa.
Sin objetivo LUFS por sample. `ebur128=peak=true` de
[FFmpeg](https://ffmpeg.org/ffmpeg-filters.html#ebur128-1) mide true peak por
sobremuestreo; guardar su versión. Sin FFmpeg queda explícitamente sin medir.

Igual ganancia conserva diferencias; RMS/LUFS permiten advertir un sesgo de nivel.
Escuchar a volumen bajo, luego auriculares, altavoces/TV y mono; repetir para
fatiga. Solo después probar contra el recorrido. Las métricas no certifican
timbre, inteligibilidad, calidad artística ni traducción a un televisor.

## 10. Integración runtime y registro de decisiones

Promover solo tras decisión humana: render final → licencia/autor/fuente/hash →
Git LFS real según `.gitattributes` → catálogo `Musica`, `Sonido` o `Ambiente` →
escucha con buses existentes. Los artifacts de cata no son assets de producción.

| Estado | Regla / experimento | Evidencia necesaria |
| --- | --- | --- |
| Regla técnica comprobable | Banco pequeño, límites de voces, mismos eventos/ganancia A/B | Tests y manifest del SHA |
| Propuesta pendiente | Motivo de carro y percusión de sello representan SIGA | Cata humana |
| Descartado para este A/B | Bitcrusher global y reverb añadida simultáneamente | Confundirían la variable ADPCM; no es un juicio auditivo |
| Aún no ensayado | Gaussiana, ADSR/PMON/reverb SPU exactos, XM, Furnace | Corte posterior si la escucha justifica su coste |
| Descartes auditivos | Ninguno registrado todavía | No inventar escuchas |

Toda decisión subjetiva futura registra fecha, revisor, SHA/receta, dispositivo,
volumen relativo, observación, decisión y motivo en #1475/#1471. Actualizar esta
biblia solo cuando exista evidencia; mantener los descartes para no repetirlos.
