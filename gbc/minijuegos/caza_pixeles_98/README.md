# Caza Píxeles 98

Minijuego original y mínimo para **Game Boy Color**, pensado como primera ROM propia de SIGA-98 para validar la integración del emulador de #124 y la consola doméstica de #95.

## Juego

- Mueve el cuadrado verde con la cruceta.
- Toca el rombo rojo para capturarlo.
- Al capturarlo, suena un bip y el objetivo reaparece en una de 16 posiciones.
- La partida no termina y no guarda nada: es un pasatiempo deliberadamente improductivo.

No hay dinero, pistas, progreso de `Partida`, modificación de `Jornada` ni efectos sobre sueños/archivo. Todo el estado vive dentro de la ROM y se pierde al apagarla.

## Compilar

Requiere RGBDS 1.0.x; CI usa la versión fijada por el repositorio.

```bash
make
```

Salida:

```text
build/caza_pixeles_98.gbc
```

El byte CGB del encabezado se fija a `0x80`, por lo que la ROM anuncia compatibilidad Game Boy Color. El código inicializa además paletas CGB para jugador, objetivo y fondo.

## Controles

| Entrada | Acción |
| --- | --- |
| Cruceta | Mover el jugador |

No depende de BIOS, ROMs comerciales, recursos externos ni assets binarios. El código se publica bajo la licencia MIT del repositorio.
