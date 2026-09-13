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
- Hay **3 pliegues** (`FOLD`): un impacto arruga el avión y consume uno.
- Cada hito pasado sin choque suma un punto.
- Tras Empire se muestra `NYC CLEAR`; con cero pliegues, `PLANE CRUMPLED`.
- A/Start reinicia inmediatamente.

La puntuación, las vidas y la ruta existen únicamente dentro de la RAM de la ROM. No hay dinero, pistas, progreso de `Partida`, cambios de `Jornada` ni efectos sobre sueño/archivo.

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

## Siguientes rutas candidatas

La estructura está pensada para añadir ciudades sin alterar el contrato del minijuego. Las siguientes rutas naturales son **París 1998** (Torre Eiffel/Arco/La Défense), **Tokio 1998** (Tokyo Tower/Shinjuku) y **Londres 1998** (Big Ben/Tower Bridge/Canary Wharf).
