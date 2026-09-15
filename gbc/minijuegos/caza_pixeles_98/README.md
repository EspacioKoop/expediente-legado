# Caza Píxeles 98

Minijuego original para **Game Boy Color**, pensado como primera ROM propia de SIGA-98 para validar la integración del emulador de #124 y la consola doméstica de #95.

## Juego

`Caza Píxeles 98` es una partida arcade breve de 30 segundos:

- portada propia con arranque mediante **A** o **Start**;
- mueve el cursor verde/cian con la cruceta;
- persigue y toca el rombo rojo para sumar puntos;
- el objetivo reaparece en una de 16 posiciones seguras, con selección pseudoaleatoria y sin repetir inmediatamente la anterior;
- cada objetivo sigue moviéndose y rebota por el área de juego;
- encadenar capturas antes de **1,5 segundos** mantiene el combo: desde 3 capturas puntúa **x2** y desde 6 puntúa **x3**;
- el HUD muestra **SCORE**, multiplicador y **TIME**;
- el tono de captura sube con x1/x2/x3 para que el combo se perciba sin apartar la vista del objetivo;
- la velocidad del objetivo aumenta al alcanzar 5, 10 y 20 puntos aunque un multiplicador salte sobre uno de esos valores;
- pantalla final con la puntuación y reinicio inmediato mediante **A** o **Start**;
- puntuación limitada a 99 para mantener un HUD de dos dígitos.

La selección de posiciones usa un LFSR de 8 bits sembrado desde el registro `DIV` al empezar una partida. El binario sigue siendo totalmente reproducible: la variación solo existe durante la ejecución y no requiere reloj real, fichero de guardado ni estado de Godot.

La puntuación es exclusivamente interna a la sesión de la ROM. No hay dinero, pistas, progreso de `Partida`, modificación de `Jornada`, descanso, bonificaciones ni efectos sobre sueños/archivo. Todo el estado vive en RAM y se pierde al apagar o salir de la consola.

## Controles

| Entrada | Acción |
| --- | --- |
| Cruceta | Mover el cursor |
| A / Start | Empezar o reiniciar una partida |

## Compilar

Requiere RGBDS 1.0.x; CI usa la versión fijada por el repositorio.

```bash
make
```

Salida:

```text
build/caza_pixeles_98.gbc
```

El byte CGB del encabezado se fija a `0x80`, por lo que la ROM anuncia compatibilidad Game Boy Color. El programa inicializa sus propias paletas, tiles, tipografía, sprites, sonido y estado; no necesita assets externos.

## Pruebas de regresión

Con RGBDS disponible:

```bash
make clean test
```

`test_rom.py` fija el contrato del combo, el PRNG, los umbrales de dificultad, el HUD y la cabecera de la ROM compilada. No necesita PyBoy ni ninguna dependencia Python externa; el smoke del emulador integrado sigue siendo el gate de ejecución de extremo a extremo.

## Integración

La ROM es deliberadamente standalone. El emulador solo necesita proporcionar framebuffer, audio y joypad estándar. La salida del minijuego puede descartarse al cerrar la consola: no existe formato de guardado que haya que sincronizar con Godot.

No depende de BIOS, ROMs comerciales, recursos externos ni assets binarios. El código se publica bajo la licencia MIT del repositorio.
