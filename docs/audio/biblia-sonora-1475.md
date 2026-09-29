# Biblia sonora SIGA-98 — laboratorio inicial

Dirección: [#1475](https://github.com/EspacioKoop/expediente-legado/issues/1475).
Producción/foley: #1471. Música/efectos puntuales: #76. Ambientes/buses: #119.
Esta propuesta no acredita una decisión de escucha ni cambia el audio del juego.
Ejecución y auditoría: [laboratorio-1475.md](laboratorio-1475.md).

Estudio de dirección actualizado el 2026-09-27. Las secciones 11–16 son una
**propuesta de composición propia pendiente de cata**, no una descripción de
funciones implementadas. La cata principal posterior al estudio será de dos
motivos por dos timbres; el ensayo de oficina es su antecedente técnico.
Las técnicas musicales generales no se presentan como invenciones
del proyecto; nuestra aportación es su elección y aplicación a SIGA-98.

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

**Decisión de Varo (29-09-2026): nada de foley grabado.** Todo el foley es
**síntesis original** con carácter de chip: NES (pulso, triángulo, ruido LFSR y
barridos de tono) y sampler de PSX (ADPCM a baja frecuencia, ADSR y reverb
corta). Un efecto no reproduce el sonido real del objeto: evoca la acción y
suena a videojuego. Ejemplo guía: el archivador al abrirse y cerrarse suena como
un «bombeo», no como una chapa. `sello`, `tecla`, `carro` y `red` describen
conceptos, no objetos capturados. Sus WAV limpios se conservan junto al
experimento ADPCM.

No se graban tomas con micro ni móvil ni se incorporan grabaciones como fuente
de foley. Los OGG de Kenney que reproduce hoy `Sonido` son un respaldo
provisional hasta que la síntesis los sustituya (#1813). Sustituir una fuente
exige una receta y su procedencia en el repo; no se renombra una grabación para
hacerla pasar por síntesis. La sesión de grabación que proponía este estudio
(sello, teclado, cajón metálico y aparato eléctrico) queda descartada.

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

`careo_tracker` es un posible corte tras decidir sobre la cata 2×2: motivo compartido,
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

## 11. Estudio de dirección: música para investigar, habitar y recordar

El problema musical es acompañar lectura, rutina, vínculos y tensión sin dictar
al jugador qué debe pensar. Una pieza vistosa fuera del juego puede distraer
dentro. La dirección propuesta se evalúa por adecuación al recorrido, recuerdo
del motivo, legibilidad de señales, contraste y coste de producción.

La identidad se apoya en tres decisiones: instrumentos nacidos de la oficina;
un pequeño vocabulario melódico que cambia de función; entradas musicales
selectivas. El carácter retro proviene de articulación, banco, voces y estructura,
además del timbre. Añadir ruido o reducir resolución al máster no basta.

### Familias y subgéneros que conviene ensayar

Esta selección es un juicio de dirección para el proyecto, no una clasificación
universal de calidad. «Prioridad» indica encaje propuesto, no resultado de escucha.

| Familia / subgénero | Aportación aprovechable | Aplicación propia | Prioridad y riesgo |
| --- | --- | --- | --- |
| Minimalismo electroacústico | Repetición con pequeños cambios y silencios | Sello/tecla como pulso de trabajo; alterar un acento al cambiar sección | Núcleo; fatiga si el patrón ocupa toda la jornada |
| Ambient y electrónica de cámara | Profundidad con pocos elementos | Textura eléctrica y resonancias propias en trayecto/casa | Núcleo; no tapar pistas ni duplicar `Ambiente` |
| Canción instrumental y miniatura de RPG | Motivo reconocible que admite arreglos | Dos motivos compartidos entre escenas y transformaciones posteriores | Núcleo; evitar melodía protagonista mientras se lee |
| Downtempo y groove FM | Bajo, silencio y síncopa con banco pequeño | Ensayo de careo a 96 BPM, articulación antes que volumen | Acento; no convertir cada conflicto en combate |
| Chip melódico y contrapunto | Voces independientes con pocos recursos | Casa: dos voces que se responden y bajo ocasional | Acento; brillo y actividad pueden volverlo infantil o invasivo |
| Post-rock de cámara | Desarrollo por registro y densidad | Clímax: reunir materiales conocidos con crecimiento gradual | Acento; una pared sonora eliminaría la intimidad |
| Collage electroacústico y glitch | Memoria reconocible, corte y recontextualización | Sueño: fragmentos de nuestros propios motivos y máquinas | Acento; aleatoriedad sin referente borra la memoria |
| Escritura chip progresiva | Contraste de secciones y ritmo desplazado | Una desviación breve en sueño o careo, seguida de retorno | Uso excepcional; virtuosismo puede competir con la escena |

No combinar las ocho familias en cada pieza. Oficina fija la paleta; casa prueba
su capacidad de ternura; careo, su presión; sueño, su transformación. La cohesión
se comprueba reconociendo el material entre contextos, sin necesitar que todos
usen igual tempo, modo o número de voces.
Las asociaciones emocionales de esta tabla son intenciones a contrastar, no
propiedades objetivas de una onda, modo o instrumento.

### Conclusiones de composición

- **Melodía:** diseñar una frase breve que funcione sola y en dos registros;
  comprobar que el cambio de timbre no sea lo único reconocible.
- **Armonía:** comenzar con pedal y dos notas; añadir movimiento de voces cuando
  cambie la función dramática. Menor no equivale automáticamente a tristeza ni
  disonancia a culpabilidad. La música no confirma hechos ocultos del expediente.
- **Ritmo:** el gesto mecánico aporta métrica; una omisión o una respuesta puede
  aumentar tensión sin subir BPM ni ganancia. Reservar retrigger intenso.
- **Timbre:** conservar una huella compartida entre lo institucional y lo íntimo;
  cambiar envolvente, registro y densidad antes de añadir otra familia de samples.
- **Forma:** introducir, transformar y retirar. La repetición necesita una función
  jugable; una cadencia insistente cada pocos segundos distrae durante lectura.
- **Silencio:** escribir también dónde no hay música. Un hallazgo puede necesitar
  espacio después de su señal, no una capa adicional permanente.

## 12. Subtemas y gramática propia

Los nombres siguientes son etiquetas de trabajo musical; no añaden personajes,
facciones, hechos ni estados narrativos al juego. Las alturas se expresan en
semitonos respecto a una raíz libre. Son bocetos para probar, no melodías aprobadas.

| ID / función | Célula propuesta | Transformaciones | Regla de reconocimiento |
| --- | --- | --- | --- |
| M01 · Registro | `0, +3, -5`; la respuesta de `carro` ya está en la receta, filas 4/7/10 | Oficina: ataque seco; careo: bajo y respuesta; casa: ataque blando y notas más largas | Conservar inicialmente contorno y orden; variar una dimensión cada vez |
| M02 · Vínculo | `0, +2, +7, +5`; distancias entre ataques `3, 1, 2` corcheas y dos hasta cerrar el compás | Dos voces podrían responderse en un arreglo futuro | Mantener ritmo de arranque; evitar presentarlo como resolución obligatoria |

En el banco actual, la raíz de `carro` es 220 Hz: M01 usa aproximadamente
La3–Do4–Mi3 como alturas de síntesis. Esto describe la receta existente; no
prescribe una tonalidad definitiva para todo el juego. Una omisión futura de
notas puede sugerir ausencia tras presentar el motivo completo; no constituye
un tercer candidato en esta cata.

Tras cerrar el estudio, la primera cata cruza M01 y M02 con T01 y T02: cuatro
clips. Cambiar de timbre conserva notas, ataques, puerta, registro y duración;
cambiar de motivo conserva la receta del timbre. Sin pedal, acompañamiento,
reverb ni variantes ADPCM en esta cata. El render es PCM limpio para todos.

No asignar un leitmotiv distinto a cada objeto. La prioridad es que dos ideas
sean recordables y transformables. Si el motivo solo funciona con su producción
completa, revisar primero fraseo y ritmo antes de multiplicar las capas.

## 13. Mapa de piezas y función dramática

Duraciones y presupuestos de esta tabla son briefs de piezas futuras. Solo la
fila de oficina existe como estudio de escena previo. Las demás requieren otro corte y escucha; no son
una reserva de archivos ni un compromiso de implementación en este PR.

| Pieza / contexto | Función y forma | Paleta y presupuesto inicial | Entrada, salida y cata |
| --- | --- | --- | --- |
| `oficina_machine_pulse`, 28 s | Aire → pulso → respuesta → tensión → retirada; presentar M01 | Cuatro fuentes actuales; 96 BPM; máximo medido 2 voces | Estudio offline, termina en silencio; comparar A/B y fatiga |
| `careo_tracker`, 30–40 s | Exponer M01, desplazar un acento, respuesta breve, descompresión | Banco compartido + un bajo FM propio; 96 BPM; objetivo ≤6 voces | Prototipo de intro/loop/salida; el contrato actual `careo` repite |
| `casa_chip`, 24–36 s | Presentar M02 y dejar respuestas incompletas | Un timbre blando derivado de `carro`, ciclo cálido; 72–84 BPM; ≤3 voces | Ensayo musical aislado; aún sin nuevo disparador runtime |
| `sueno_memory`, 24–36 s | Mostrar M01, retirar un fragmento, reconstruir parcialmente | Fuentes propias identificadas; base temporal libre; ≤6 voces | Comparar reconocibilidad con/sin transformación; respetar fase `sueño` |
| Cierre, 35–45 s | Recuperar un motivo, reunir registros y terminar con espacio | Banco compartido; ≤8 voces como decisión artística | Una pasada para `final`; no convertirlo en loop |

El trayecto y la oficina ordinaria mantienen su cama ambiental existente. Un
estudio musical de oficina no justifica encender música durante toda esa fase.
Tampoco se decide desde el laboratorio qué dato narrativo dispara una pieza.

### Arreglo y textura

Mantener una voz que lleva la información, otra que contesta y un suelo rítmico
cuando haga falta. Un máximo técnico de 24 voces no es una meta de densidad.
Separar bajo, transitorios y motivo por registro; comprobar en mono si cada uno
conserva función. Una capa nueva debe aportar fraseo, relación o transición.

Reservar la deformación fuerte para fuentes cuya versión normal ya sea familiar.
Un objeto puede ser percusión, nota y textura en distintas piezas, conservando
su procedencia. Una fuente sintética nueva se compara con la actual antes de
deformarla con una cadena de efectos.

## 14. Diseño interactivo: propuesta compatible con los contratos actuales

El primer paso sigue siendo composición y render. El runtime actual tiene
responsabilidades separadas: efectos puntuales, música dramática y ambiente.
No se introduce aquí middleware ni otro director de audio.

| Técnica | Cuándo merece probarse | Coste / condición |
| --- | --- | --- |
| Render único con loop | Careo con duración variable y función estable | Primera opción por simplicidad; fabricar y escuchar costura, intro y salida |
| Resequenciación de secciones | Cuando una escena tenga cambios de estado documentados | Diseñar fronteras de frase y salidas; requiere corte de código y pruebas |
| Capas sincronizadas | Si hacen falta intensidades simultáneas sin cambiar melodía | Stems del mismo largo y origen temporal; medir suma, fase y sincronía |
| Acento breve / stinger | Hecho confirmado que ya tenga feedback autorizado | Evitar dobles señales con UI y `Sonido`; no revelar una solución oculta |
| Pausa musical | Lectura, espera o retirada dramática | Mantener sonidos útiles y ambiente; probar que el silencio no parezca un fallo |

Para un ensayo futuro de capas, exportar pulso, motivo y textura desde la misma
partitura, con idéntica duración y punto cero. Documentar si la reverb se imprime
por stem o se entrega como retorno común; comprobar la suma prevista para que
no se duplique un retorno compartido. Para secciones, componer continuidad armónica y salidas
antes de programar saltos; el crossfade no corrige una transición mal escrita.

La intensidad debe responder a estados observables autorizados por diseño.
Propuesta a validar: tiempos mínimos de permanencia, salida tras estabilidad y
un enfriamiento para señales repetidas. Los valores se fijarán con el recorrido,
no con un temporizador arbitrario de este documento. No reiniciar un tema cada
vez que se abre un panel ni aumentar presión solo porque el jugador lee despacio.

Pausa, cambio de escena, carga de partida, salto de secuencia y sliders/mute
necesitan pruebas al integrar. Hasta entonces no se declara funcional ninguno
de estos comportamientos nuevos. Cualquier dato jugable decisivo conserva
representación visual/textual: reconocer un motivo no puede ser requisito.

## 15. Producción y revisión profesional

Cada propuesta entrega un brief de función, partitura/receta editable, banco con
procedencia, render limpio, variante de una sola variable, mediciones y ficha de
escucha. Los módulos tracker futuros añaden formato, versión de reproductor,
fuentes y render de referencia. Mantener semillas, offsets y decisiones de loop.

Los rangos de tempo, voces y duración anteriores son puntos de partida. No se
presentan como especificaciones de una consola ni como fórmulas de calidad.
El objetivo no es un máster fuerte: es legibilidad a través de los buses reales.

### Pruebas futuras en contexto, aún pendientes

La cata aislada 2×2 no acredita lectura, fatiga prolongada, mezcla runtime ni
transiciones. Estas pruebas se aplicarán al corte que integre una pieza.

| Pregunta | Comparación | Evidencia que registrar |
| --- | --- | --- |
| ¿Se recuerda la idea? | Motivo solo y después con otro timbre | Descripción o reproducción del contorno tras una pausa, sin prometer porcentaje de éxito |
| ¿La música ayuda a leer? | Pasajes equivalentes con/sin música, alternando orden y registrando familiaridad | Comprensión, distracción y señales perdidas; evitar atribuir aprendizaje del texto al audio |
| ¿La variación cuenta algo? | Misma célula en oficina/casa/careo | Qué cambió emocionalmente y qué siguió siendo reconocible |
| ¿ADPCM aporta carácter? | A/B con ganancia común y orden alternado | Preferencia por fuente, ataque, ruido y costuras; revisar sesgo de nivel con métricas |
| ¿Fatiga o se vuelve mecánica? | 5–10 minutos en un recorrido representativo | Instante y causa de molestia; no confundir este ensayo con una sesión ya realizada |
| ¿Se entiende en equipos distintos? | Auriculares, altavoces/TV, mono y volumen bajo | Dispositivo, entorno, controles y elementos que desaparecen |
| ¿Funcionan entradas y salidas? | Loop, cancelación, pausa, recarga y cambio de escena | Grabación reproducible del evento y criterio de aceptación, tras integración |

Empezar la cata con volumen moderado del usuario, sin normalización automática
del reproductor. Si el nivel sesga la comparación, preparar una segunda escucha
igualada y etiquetada, conservando los originales y el cambio de ganancia. No
inventar calibración acústica a partir de un slider ni certificar loudness desde
la impresión subjetiva.

Una decisión artística queda como `iterar`, `descartar` o `candidato`. «Candidato»
exige una observación concreta y su contexto; pasar métricas no equivale a
aprobar la música. Antes de producción, revisar además que motivos, samples y
arreglos sean propios, que toda fuente esté declarada y que no haya frases
reconocibles tomadas de otra obra. Esta revisión es humana, no una garantía
automática de originalidad ni una comparación ya realizada.

## 16. Decisiones y traspaso entre agentes

Estudio cerrado para esta iteración el 2026-09-27, tras tres revisiones de
motivos, timbres e interacción. Se han incorporado sus correcciones de alcance,
control de nivel y límites de las pruebas. Este cierre autoriza preparar el
experimento; no equivale a aprobar su resultado artístico.

### Protocolo de la cata 2×2 posterior al estudio

| Variable | Decisión de esta iteración |
| --- | --- |
| Escritura | M01 `0,+3,-5`, ataques filas `0,3,6`; M02 `0,+2,+7,+5`, ataques `0,6,8,12` |
| Tiempo | 96 BPM; fila de 0,15625 s; primera frase a 0,5 s, repetición a 5,5 s; cada clip dura 10 s |
| Articulación | Puerta fija 0,25 s, ganancia de evento común, una voz, centro, offset cero |
| T01 | FM: raíz 220 Hz, ratio 1, índice inicial 0,25 |
| T02 | FM: raíz 220 Hz, ratio 2, índice inicial 1,8 |
| Envolvente y fuente | Ambos: 28.224 muestras (0,64 s), caída 6 s⁻¹, caída del índice 12 s⁻¹, filtro/rampas comunes |
| Nivel | Calibrar cada timbre sobre M01+M02 concatenados; congelar su ganancia para los dos motivos; atenuación común si hace falta margen |
| Salida | Cuatro WAV PCM; sin acompañamiento, reverberación, ADPCM ni variación aleatoria |

M01 conserva alturas y separación entre ataques de la respuesta de oficina,
trasladando su primer ataque al inicio de frase. La cata retira el offset y los
paneos previos. Las duraciones `3,1,2,2` de M02 describen la métrica entre ataques
y cierre; la puerta audible de cada nota sigue siendo 0,25 s en ambos motivos.
Comparar M01 con M02 evalúa su escritura completa, no solo intervalos aislados.

La calibración utiliza loudness integrado medido por FFmpeg, objetivo inicial
de laboratorio −24 LUFS y diferencia máxima 0,5 LU entre los dos programas de
calibración. Si el pico exige atenuar las cuatro celdas, el nivel final será menor
y se registrará. Estos números son controles propios del experimento, no una
norma de mezcla para el juego ni garantía de igual sonoridad subjetiva. No se
normaliza cada motivo por separado: se preserva su distinta densidad de notas.

Los botones se etiquetan M01/M02 y T01/T02 sin adjetivos emocionales. Primera
escucha: descripción libre. Después, comparar el mismo motivo entre timbres y
el mismo timbre entre motivos; repetir en orden inverso y anotar si cambia la
preferencia. Registrar reconocimiento, ataques/colas, atención y un recuerdo
tras una pausa cuya duración se anote. No se declara prueba ciega ni se exige
un porcentaje de éxito. La adecuación a lectura se validará luego en contexto.

T01 y T02 son nombres neutros de prueba; sus recetas conceptuales son `fibra`
y `lamina`, síntesis propia, no grabaciones. FM se calcula offline y se samplea;
no equivale a FM nativa de SPU ni a PMON. El presupuesto PCM de esta cata es
128 KiB para sus dos fuentes, independiente del banco ADPCM anterior.

**Propuesta vigente:** usar la oficina como origen conceptual del banco, M01 como
primer ancla y M02 como contraste. La ausencia queda como transformación futura.
Elegir pocas voces, contrastes de función y entradas selectivas. Orden acordado:
cerrar estudio → generar cata de dos motivos por dos timbres → registrar escucha
→ decidir siguiente corte. El estudio previo de oficina no sustituye esta cata.

**Fuera de este corte:** nuevos controladores, canciones completas de casa/sueño,
foley grabado, adopción de middleware, aprobación artística e integración de
assets. No se ha tomado una decisión auditiva sobre ellos.

El [issue #1475](https://github.com/EspacioKoop/expediente-legado/issues/1475)
conserva prioridades y decisiones; [#182](https://github.com/EspacioKoop/expediente-legado/issues/182)
reserva rutas. Esta biblia es el brief versionado, no otra cola de trabajo.
Para continuar: leer último checkpoint/PR/CI, elegir una pregunta de la cata,
reclamar únicamente rutas libres y publicar resultado con SHA. No reservar toda
la música, todo el issue ni impedir otros cortes independientes.

## 17. Encaje con el plan de chips de #1475

Se han revisado las [cuatro partes del plan](https://github.com/EspacioKoop/expediente-legado/issues/1475#issuecomment-5855850575)
y publicado sus [correcciones técnicas y de alcance](https://github.com/EspacioKoop/expediente-legado/issues/1475#issuecomment-5855920920).
El laboratorio inicial #1478 fue fusionado por eGurucharri el 2026-09-27. El
estudio ampliado y la cata continúan desde `main` en `feature/1475-cata-motivos-timbres`,
con [seis rutas reservadas](https://github.com/EspacioKoop/expediente-legado/issues/182#issuecomment-5855940426).
Las decisiones D1–D15 permanecen en el issue; este laboratorio no las aprueba
implícitamente. Se conserva una sola biblia sonora y el reparto de rutas de #182.

Este corte corresponde a **T01 exploratorio**: la cata 2×2 no depende de construir
los núcleos completos ni de migrar su JSON a `.trk98`. Distingue motivo,
instrumento, motor, cadena de reproducción y función narrativa. Elegir un
timbre FM no acredita un núcleo OPL3; reproducir PCM no acredita SPU ni XA.
La propuesta de llevar un vocabulario a varias máquinas sigue abierta a escucha.

Antes de implementar T07/T09/T15 se deben concretar tabla/aritmética de
interpolación, cuantización de pitch y punto de extracción de stems frente a
procesos no lineales. T19/T20/T25 requieren transporte musical explícito,
resolución de manifiestos y separación entre fundido y limpieza de escena.
Estas correcciones están en el comentario de revisión; no duplicamos las 32
tareas aquí ni las convertimos en una reserva global.

El ADPCM Python anterior es una referencia cruzada limitada: decodifica una
pasada, sin ejecutar flags de playback. El futuro núcleo necesita sus propios
vectores documentales y pruebas de reproducción. Los WAV de esta cata son
bocetos de síntesis propia del laboratorio, no assets promovidos al juego;
la discrepancia de licencias señalada en D14 sigue pendiente para esa promoción.

Las otras tareas pueden avanzar por rutas libres sin esperar al merge/cierre de
#1478, conforme al [acuerdo de coordinación](https://github.com/EspacioKoop/expediente-legado/issues/182#issuecomment-5855921027).
