# SPU-98: referencia verificable, T02 parcial

Continúa [#1475](https://github.com/EspacioKoop/expediente-legado/issues/1475)
y el laboratorio integrado en #1478/#1485. La dirección musical sigue en la
[biblia única](../biblia-sonora-1475.md). Esta ficha delimita qué puede comprobar
el siguiente corte técnico; no aprueba D1–D15 ni sustituye la escucha de la cata.

**Estado:** once vectores ADPCM manuales ejecutables contra el decoder offline;
casos de pitch preparados para T07; control de voces e interpolación pendientes.
No hay núcleo C++ ni integración nueva en Godot en este corte. T02 completo
requiere todavía D9, las especificaciones restantes y revisión humana.

## Fuentes y trazabilidad

La referencia pública es documentación de ingeniería inversa de PSX-SPX, fijada
al commit `7d89534f7b642aa302222269039cbf754893d3be`:

- [S1: SPU](https://github.com/psx-spx/psx-spx.github.io/blob/7d89534f7b642aa302222269039cbf754893d3be/docs/ps1/spu/soundprocessingunitspu.md): apartados `SPU ADPCM Samples`, `Flag Bits`, `SPU ADPCM Pitch`, `Pitch Counter` y `SPU Memory layout`.
- [S2: algoritmo ADPCM](https://github.com/psx-spx/psx-spx.github.io/blob/7d89534f7b642aa302222269039cbf754893d3be/docs/ps1/cdr/cdromformat.md): `decode_28_nibbles`, `Pos/neg Tables` y `Old/Older Values`. S1 remite a ese algoritmo; el empaquetado XA es otro formato.

Los [vectores](../../../referencia/audio/chips/spu98_vectores.json) son datos
sintéticos propios. Sus resultados se calculan mediante aritmética escrita en
cada caso y se guardan como literales. No salen de ejecutar el decoder, de un
roundtrip con su encoder ni de audio de terceros. Dos revisiones técnicas de
agentes contrastan fuentes y límites; esto no es una captura de hardware.

No se han usado BIOS, SDK, audio extraído ni código de emuladores. Esta ficha
no resuelve la licencia de futuros assets de producción (D14) ni copia la tabla
de interpolación pendiente de D9.

## Perfil de comparación del laboratorio

`laboratorio-1475-adpcm-v1` nombra el contrato actual, no una certificación SPU.
Cada llamada parte de historia cero y procesa secuencialmente todos los bloques.
Los bloques de preparación de los fixtures suministran historias no nulas sin
añadir una API de estado al laboratorio.

Datos de S1/S2: 16 bytes por bloque, 28 muestras; nibble bajo antes del alto;
nibble con signo de −8 a 7. Filtros 0–4: `(0,0)`, `(60,0)`, `(115,−52)`,
`(98,−55)`, `(122,−60)`.

Para shift `s` de 0 a 12, residuo `q × 2^(12−s)` y predictor
`floor((a×h1 + b×h2 + 32)/64)`. Se satura la suma a int16 antes de actualizar
`(h1,h2) = (salida,h1)`. **La división negativa es una interpretación explícita
del perfil:** S2 escribe `/64` sin precisar su semántica. El laboratorio usa
desplazamiento aritmético; falta contraste independiente para afirmar hardware.

Un port C++17 debe definir esa aritmética sin depender de desplazar negativos
ni de una división truncada hacia cero. Por ejemplo, el predictor con `h1=-1`,
F1 y residuo cero conserva −1 en este perfil. Los empates de +7,5 y −7,5 dan 8
y −7: tampoco corresponde al redondeo bancario. Multiplicar para formar el
residuo evita trasladar un desplazamiento izquierdo negativo indefinido.

| Vectores ejecutados | Qué detectan |
| --- | --- |
| ADPCM-01/02 | Orden, signo y escalas extremas de shift |
| ADPCM-03/04/05/06 | Filtros 1–4 con historia conservada entre bloques |
| ADPCM-07/08/09 | División negativa y empates con ambos signos |
| ADPCM-10/11 | Saturación positiva/negativa y uso posterior de la historia saturada |

Los rangos `tramos` son deliberados: unos casos comprueban todo el PCM y otros
solo el prefijo o la frontera que se deriva a mano. El test comprueba también
la longitud total. No se presenta un prefijo como un golden completo.

El perfil rechaza filtros >4 y shifts >12. No extrapolar a SPU el comportamiento
de cabeceras reservadas descrito para XA. Los flags se ignoran en esta API.

## Flags: contrato pendiente de la voz

S1: start guarda LSAX; end salta al terminar el bloque y fija ENDX; end sin
repeat además fuerza release y nivel ADSR cero. Repeat sin end no salta.
Las direcciones de registro están expresadas en unidades de ocho bytes.

Plan de pruebas T06/T07 — **ninguna ejecutada como reproducción SPU aquí**:

| ID futuro | Entrada preparada | Observación a comprobar |
| --- | --- | --- |
| VOZ-01 | A en byte `0x2000`, flags `04`; B en `0x2010`, flags `03` | Tras A, LSAX `0x0400`; después de B, salto a A y ENDX |
| VOZ-02 | Cambiar flags de B a `00` o `02` | Siguiente bloque en `0x2020` |
| VOZ-03 | Cambiar flags de B a `01` | Salto a LSAX, ENDX, release y envolvente cero; no simplemente detener lecturas |
| VOZ-04 | Un bloque con `07` | Repetición sobre sí mismo; contrastar historia e interpolación de dos vueltas |

Estas trazas son lógicas por bloque: no especifican prelectura, latencia en
ciclos ni instante de ENDX respecto a la salida interpolada. No deducir un
reinicio del predictor del flag start. El estado exacto ante Key On y saltos
requiere completar la referencia antes de implementar esa voz.

Los tests actuales sí demuestran el límite offline: un bloque end seguido de
otro devuelve 56 muestras. También comprueban el encoder para 1, 28 y 29
muestras: al repetir, el relleno hasta múltiplo de 28 forma parte del período.
Verificar esos bytes no valida las trazas anteriores.

## Pitch: datos preparados, implementación pendiente

S1 documenta `PITCH=0x1000` como avance de una muestra fuente por tick de salida;
sin PMON, el paso se limita a `0x4000`. La salida conserva 44,1 kHz.
El índice de interpolación usa bits 4–11; los cuatro bits inferiores se acumulan.

El JSON guarda siete casos de tasa y dos trazas con estado **pendiente T07**.
`test_spu98_vectores.py` no los ejecuta: el laboratorio no tiene ese contador.
Con paso `0x1800`, cuatro ticks producen contadores `0x1800,0x3000,0x4800,0x6000`
e índices fuente `1,3,4,6`. Esto no describe la salida PCM interpolada.
Con paso 1, 16 ticks acumulan `0x10`; 4096 ticks, `0x1000`.

Derivación propia para una fuente de raíz `f0`, tasa `Fs` y objetivo `ft`:

```text
P ideal = 4096 × (Fs / 44100) × (ft / f0)
f obtenida = f0 × (P entero / 4096) × (44100 / Fs)
error en cents = 1200 × log2(f obtenida / ft)
```

Elegir entero y resolver empates es política del secuenciador. Ejemplo con
La4=440 Hz: raíz 220 Hz a 22050 Hz, objetivo Do1≈32,703196 Hz; `P=304` obtiene
32,65625 Hz, aproximadamente −2,487 cents. El presupuesto debe separar error de
cuantización y error de implementación. Pitch cero no demuestra PCM silencioso.

## Memoria y resto de T02

S1 describe 512 KiB compartidos y 4 KiB iniciales de capturas. Propuesta de
presupuesto conservador para el futuro empaquetador:

```text
4096 + datos ADPCM + área de reverb + rellenos/guardas <= 524288 bytes
```

Con reverb de 8192 bytes, quedan 512000 para datos y otras reservas. Un caso
futuro deberá aceptar el límite exacto y rechazar su desbordamiento. La elección
artística de 32 KiB del laboratorio no es un mapa físico de SPU-RAM. Una política
de alineación a bloques de 16 bytes debe distinguirse de las unidades de ocho
bytes de los registros. El empaquetador/linter aún no existe.

| Pendiente | Referencia inicial | Prueba que debe concretarse |
| --- | --- | --- |
| Interpolación/D9 | S1, `4-Point Gaussian Interpolation` | Fases, coeficientes y aritmética con referencia independiente; no validar una fórmula contra sí misma |
| ADSR | S1, `SPU Volume and ADSR Generator` | Especificar tasas, transiciones y contador antes de prometer tiempos a una muestra |
| Ruido y PMON | S1, `SPU Noise Generator` / `Pitch Counter` | Estado compartido, voz anterior y límites del registro; excluidos de las trazas de pitch |
| Reverb | S1, `SPU Reverb Formula` | Topología, tasa, saturación y área de trabajo; parámetros propios, sin presets de SDK |
| XA | S2, `CDROM XA Audio ADPCM Compression` | Empaquetado, tasa e interpolación propios; no equipararlo al render de stems PCM/Vorbis |
| DMA/IRQ/CD-DA y barridos | S1, secciones correspondientes | Acordar inclusiones/exclusiones; no declarar esos subsistemas emulados |

## Ejecución y traspaso

Desde la raíz, solo Python estándar:

```bash
python3 -m unittest -v scripts/test_spu98_vectores.py
```

Son cinco pruebas, con once vectores PCM y casos de contrato offline. La suite
canónica Python los descubre por nombre. Un futuro T06 puede consumir el mismo
JSON: comparar sus tramos literales antes de usar el laboratorio como contraste
adicional. T07 debe implementar las trazas de voz/pitch por separado y registrar
qué pasa realmente. La CI en verde no promueve los casos pendientes.

Para cerrar T02: resolver D9, completar los apartados pendientes, añadir la
evidencia independiente necesaria y registrar revisión humana. Las observaciones
y el reparto entre agentes se publican en #1475/#182; esta ficha no abre una
segunda cola ni reserva otras rutas del plan.
