# ARIADNE 98

Primer cartucho ejecutable del vertical #2313/#2368. Este corte reutiliza el cartucho RGBDS común del proyecto y contiene únicamente la portada y el primer laberinto cenital determinista.

## Build

```bash
make -C gbc/minijuegos/ariadne_98
```

Genera `build/ariadne_98.gbc` con cabecera `ARIADNE98`, modo dual DMG/CGB y la configuración MBC5 + RAM + batería aportada por `../comun/cartucho.mk`.

## Controles

- **A / START**: empezar desde la portada y volver a ella desde la salida.
- **Cruceta**: mover a Ariadne una celda por pulsación; los muros bloquean el paso.

## Alcance de este corte

- un laberinto manual, sin RNG;
- HUD reservado para nivel, hilo y alerta;
- salida detectable y retorno a portada;
- arte geométrico original/provisional.

Todavía **no** implementa hilo, Minotauro, progreso en SRAM, handshake con SIGA, tienda ni integración Godot. El índice mantiene la ROM como `en_proyecto`: CI puede compilarla como fixture, pero el runtime no la distribuye.

Refs #2313 #2368 #2388 #2389.
