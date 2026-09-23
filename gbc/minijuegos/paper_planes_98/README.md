# Paper Planes 98

Segundo minijuego original para **Game Boy Color** de SIGA-98. El jugador pilota un avión de papel por rutas urbanas inspiradas en grandes ciudades tal y como se reconocían en 1998.

## Ruta 1: Nueva York, 1998

Nueva York va primero porque el perfil de Lower Manhattan de finales de los 90 estaba visualmente dominado por el World Trade Center y permite una ruta muy reconocible incluso con siluetas de 8×8 píxeles. La ruta recorre cuatro hitos, reinterpretados con pixel-art original del proyecto:

1. **Liberty** — sobrevolar la Estatua de la Libertad y su pedestal.
2. **WTC** — ganar altura ante las Torres Gemelas del skyline pre-2001.
3. **Brooklyn Bridge** — atravesar el vano entre cables y tablero.
4. **Empire** — remontar junto al Empire State Building y su aguja.

Referencias históricas visuales, usadas solo como documentación y no como assets:

- Skyscraper Museum, *Modernist Skyline 1961–2000*: https://old.skyscraper.org/skyline/modernist-skyline-1961-2000.html
- Archivo fotográfico del World Trade Center y Manhattan en 1998, University of Vaasa: https://lipas.uwasa.fi/~atn/travel/usa/wtc/

No se incorporan fotografías, logotipos, BIOS ni ROMs de terceros. Todos los gráficos de la ROM son siluetas originales creadas para SIGA-98.

## Mecánica

- El escenario avanza automáticamente de derecha a izquierda.
- **Arriba o A** hace remontar el avión.
- **Abajo** permite picar.
- **Izquierda/Derecha** desplazan lateralmente el avión para afinar la trayectoria.
- **B** pliega momentáneamente el avión: mantiene la altura y anula el viento, pero mientras se mantiene pulsado no se puede maniobrar.
- Hay **3 pliegues** (`FOLD`): un impacto arruga el avión y consume uno.
- Cada hito alterna un patrón de viento propio. Liberty y Brooklyn Bridge empujan suavemente hacia arriba; WTC y Empire tienen rachas descendentes más frecuentes.
- Pasar un hito limpio suma **1 punto**. Cruzar además la franja central de precisión suma **2 puntos** y aumenta `PERF`.
- El HUD informa de `FOLD`, dirección del viento, puerta actual, puntuación y número de pasos perfectos en una sola fila para no tapar el cielo.
- Tras Empire se muestra `NYC CLEAR`; con cero pliegues, `PLANE CRUMPLED`. La pantalla final muestra puntuación y `PERFECT n/4`.
- A/Start reinicia inmediatamente.

El segundo pase convierte la ruta en algo más que memorizar cuatro alturas: el jugador debe anticipar la racha del siguiente tramo, decidir cuándo corregir y cuándo fijar la trayectoria con **B**, y escoger entre un paso simplemente seguro o buscar la banda estrecha que da el perfecto.

El pase de legibilidad de #804 mantiene esas reglas y corrige únicamente presentación: el cielo CGB deja de ser blanco puro, aparecen nubes de referencia, el skyline jugable gana una base urbana, el avión usa una silueta 16×8 de alto contraste y las dos filas de agua se escriben respetando el stride real de 32 celdas del tilemap. Esto último evita la antigua franja 32+8 que se leía como una barra atravesando media pantalla. El nombre del hito deja de ocupar una tercera fila de texto durante el vuelo: el gate del HUD y la silueta del obstáculo llevan esa lectura.

La puntuación, las vidas, los perfectos y la ruta existen únicamente dentro de la RAM de la ROM. No hay dinero, pistas, progreso de `Partida`, cambios de `Jornada` ni efectos sobre sueño/archivo.

## Compilar

Requiere RGBDS 1.0.x; CI utiliza la versión fijada por el repositorio.

```bash
make
```

Salida:

```text
build/paper_planes_98.gbc
```

El encabezado usa el flag CGB `0x80`, de modo que la ROM es dual-mode pero aprovecha paletas de Game Boy Color cuando están disponibles.

## Pruebas de regresión

Con RGBDS disponible, instalar el emulador de pruebas en un entorno virtual:

```bash
python3 -m venv /tmp/paper-planes-tests
/tmp/paper-planes-tests/bin/python -m pip install pyboy==2.6.1
make clean
make test PYTHON=/tmp/paper-planes-tests/bin/python
```

`test_rom.py` ejecuta el código máquina compilado en copias temporales de la ROM y comprueba la cabecera dual-mode, la limpieza de las 1024 celdas del fondo, el stride y la anchura visible de skyline/agua, la silueta 16×8 del avión, los sprites de los cuatro hitos en OAM, el HUD de una fila, la alternancia/frecuencia de las rachas, el bloqueo del viento con **B** y la diferencia entre un paso normal y un paso perfecto.

El arnés llama a las rutinas con la LCD apagada: verifica sus escrituras en memoria, pero no el presupuesto de VBlank, el renderizado durante una partida ni controles físicos. PyBoy es una dependencia de pruebas local; no se distribuye con la ROM ni se integra en el juego. El workflow GBC existente compila la ROM; estas pruebas se ejecutan explícitamente con `make test`.

## Siguientes rutas candidatas

La estructura sigue pensada para añadir ciudades que cambien también el comportamiento de vuelo, no solo el decorado. Las siguientes rutas naturales son **París 1998** (Torre Eiffel/Arco/La Défense), **Tokio 1998** (Tokyo Tower/Shinjuku) y **Londres 1998** (Big Ben/Tower Bridge/Canary Wharf). Una segunda ruta debería traer su propio patrón de viento/obstáculos para que no sea un simple reskin de Nueva York.
