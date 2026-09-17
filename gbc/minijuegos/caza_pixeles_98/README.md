# Pixel Exodus

`Pixel Exodus` es el nombre visible de la ROM cuyo id técnico estable sigue siendo `caza_pixeles_98`. Es un minijuego original para **Game Boy Color** integrado en la Portátil Color 98 de SIGA-98.

## Premisa

Chromia está perdiendo su **croma**, la materia viva que da color a sus océanos, bosques y criaturas. Los sistemas automatizados de extracción han llevado el planeta al colapso y fragmentos luminosos empiezan a escapar al espacio: el *Pixel Exodus*.

La nave del jugador empieza rescatando croma, pero durante la partida aparecen semillas de ecosistema y focos contaminantes. Cerrar estos focos restaura Chromia, aunque obliga a abandonar el combo: el juego contrapone de forma explícita la puntuación inmediata y la recuperación del planeta.

Este primer vertical de #882 cuenta la trama mediante reglas y cambios de presentación; las cinemáticas completas, el Glitch Behemoth y el pase artístico final quedan para cortes posteriores.

## Campaña actual

Una partida dura **45 segundos** y se divide en tres fases consecutivas:

1. **El éxodo** — 45→30 s. Croma libre y semillas; ritmo de introducción.
2. **La zona muerta** — 30→15 s. Entran focos contaminantes estacionarios y aumenta la velocidad.
3. **Restauración** — 15→0 s. Ritmo máximo y mezcla de los tres tipos de objetivo.

Cada fase cambia la paleta de fondo para reforzar el paso de Chromia vivo a la zona industrial y, después, a una restauración más luminosa. El HUD muestra `P` (fase) y `R` (restauración) además de puntuación, combo y tiempo.

### Objetivos

- **Croma libre**: rombo móvil. Mantiene el loop clásico de captura y combo.
- **Semilla de ecosistema**: brote móvil más lento. Puntúa y añade restauración.
- **Foco contaminante**: instalación fija. Cerrarla suma mucha restauración y un punto fijo, pero rompe el combo y devuelve el multiplicador a x1.

El combo conserva la ventana de **1,5 segundos**: desde 3 capturas puntúa x2 y desde 6 puntúa x3. La puntuación sigue saturada en 99 y la velocidad aumenta por puntuación y por fase.

## Controles

| Entrada | Acción |
| --- | --- |
| Cruceta | Mover la nave/cursor |
| A / Start | Empezar o reiniciar una partida |

## Récords en SRAM

La ROM usa la infraestructura MBC5 + 8 KiB RAM + batería introducida en #819. Guarda exclusivamente datos internos de `Pixel Exodus`:

- mejor puntuación;
- mejor combo;
- fase más alta alcanzada;
- mejor nivel de restauración.

El bloque de guardado empieza con la firma `PX98`, lleva versión y checksum. Si la SRAM está vacía, pertenece a otra versión o no supera la comprobación, los récords se inicializan de forma segura a cero.

La pantalla final muestra el resultado actual y los mejores valores persistidos. La RAM se protege inmediatamente después de leer o escribir.

**No existe integración de estos récords con `Partida`, `Jornada`, economía, pistas, sueños ni progreso de SIGA-98.** El `.sav` pertenece únicamente al cartucho emulado.

## Presentación GBC

- pantalla de título CGB a pantalla completa procedente de la lámina aprobada de #810;
- fallback de título de texto en DMG;
- cuatro paletas OBJ: nave, croma, semilla y foco;
- tres paletas de gameplay por fase;
- sprites de 8×8 para el vertical actual;
- sonido diferenciado para captura, restauración, cierre de foco, transición de fase y final.

El arte de gameplay todavía es deliberadamente un vertical: fondos completos, parallax, metasprites, fauna, animaciones, música y Glitch Behemoth siguen pendientes en #882.

## Compilar

Requiere RGBDS 1.0.x; CI usa la versión fijada por el repositorio.

```bash
make
```

Salida:

```text
build/caza_pixeles_98.gbc
```

El byte CGB del encabezado es `0x80`. `cartucho.mk` fija MBC5+RAM+BATTERY (`0x1B`) y 8 KiB de SRAM (`0x02`).

## Pruebas de regresión

```bash
make clean test
```

`test_rom.py` comprueba el contrato del combo y PRNG heredados y añade regresiones para:

- las tres fases y sus transiciones;
- los tres tipos de objetivo;
- la decisión restauración vs. combo de los focos;
- HUD de fase/restauración;
- formato y protección de SRAM;
- cabecera CGB y cartucho con batería.

El smoke común del repositorio sigue validando la ROM con `Siga98GB`, el mismo núcleo usado por la Portátil Color 98. Este README no afirma validación visual humana: las capturas y el playtest final forman parte del trabajo pendiente de #882.

## Integración

La ROM es standalone. El emulador proporciona framebuffer, audio, joypad y persistencia de RAM del cartucho. No depende de BIOS ni ROMs comerciales. El código se publica bajo la licencia MIT del repositorio.
