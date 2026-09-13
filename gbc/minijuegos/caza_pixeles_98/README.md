# Caza Píxeles 98

Minijuego original para **Game Boy Color**, pensado como primera ROM propia de SIGA-98 para validar la integración del emulador de #124 y la consola doméstica de #95.

## Juego

`Caza Píxeles 98` es una partida arcade breve de 30 segundos:

- portada propia con arranque mediante **A** o **Start**;
- mueve el cursor verde/cian con la cruceta;
- persigue y toca el rombo rojo para sumar un punto;
- el objetivo reaparece en una de 16 posiciones y se desplaza por la pantalla;
- la velocidad del objetivo aumenta a los 5, 10 y 20 puntos;
- HUD con **SCORE** y **TIME**;
- bip diferente al empezar, capturar y terminar;
- pantalla final con la puntuación y reinicio inmediato mediante **A** o **Start**;
- puntuación limitada a 99 para mantener un HUD de dos dígitos.

La puntuación es exclusivamente interna a la sesión de la ROM. No hay dinero, pistas, progreso de `Partida`, modificación de `Jornada` ni efectos sobre sueños/archivo. Todo el estado vive en RAM y se pierde al apagar o salir de la consola.

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

## Integración

La ROM es deliberadamente standalone. El emulador solo necesita proporcionar framebuffer, audio y joypad estándar. La salida del minijuego puede descartarse al cerrar la consola: no existe formato de guardado que haya que sincronizar con Godot.

No depende de BIOS, ROMs comerciales, recursos externos ni assets binarios. El código se publica bajo la licencia MIT del repositorio.
