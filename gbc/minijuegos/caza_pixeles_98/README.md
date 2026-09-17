# Pixel Exodus

`Pixel Exodus` es el nombre visible de la ROM cuyo id técnico estable sigue siendo `caza_pixeles_98`. Es un minijuego original para **Game Boy Color** integrado en la Portátil Color 98 de SIGA-98.

## Premisa

Chromia está perdiendo su **croma**, la materia viva que da color a sus océanos, bosques y criaturas. Los sistemas automatizados de extracción han llevado el planeta al colapso y fragmentos luminosos empiezan a escapar al espacio: el *Pixel Exodus*.

La nave del jugador empieza rescatando croma, pero durante la partida aparecen semillas de ecosistema y focos contaminantes. Cerrar estos focos restaura Chromia, aunque obliga a abandonar el combo: el juego contrapone de forma explícita la puntuación inmediata y la recuperación del planeta.

El cierre de la campaña enfrenta a la nave con el **Glitch Behemoth**, una masa de chatarra, maquinaria abandonada y croma corrompido. No se trata como una criatura natural “malvada”: sus cuatro puntos vulnerables representan focos de residuo industrial que hay que limpiar para deshacer la masa.

## Campaña actual

Una partida dura hasta **45 segundos** y se divide en tres fases consecutivas:

1. **El éxodo** — 45→30 s. Croma libre y semillas; atmósfera todavía abierta, estrellas y un último ave visible antes del colapso.
2. **La zona muerta** — 30→15 s. Entran focos contaminantes, el fondo adopta una trama industrial y la fauna desaparece salvo que el jugador ya haya recuperado suficiente ecosistema.
3. **Restauración** — 15→0 s. Ritmo máximo, nebulosa más viva y fauna que reaparece por etapas. En los últimos **8 segundos** aparece el Glitch Behemoth.

Si se limpian los cuatro núcleos del Behemoth antes de que se agote el tiempo, la partida termina inmediatamente como final completado y el récord de fase pasa a `P4`. Si el tiempo llega a cero con el Behemoth activo, se conserva el progreso y la restauración lograda, pero el residuo continúa visible en la pantalla final.

### Objetivos

- **Croma libre**: rombo móvil. Mantiene el loop clásico de captura y combo.
- **Semilla de ecosistema**: brote móvil más lento. Puntúa y añade restauración.
- **Foco contaminante**: instalación fija. Cerrarla suma mucha restauración y un punto fijo, pero rompe el combo y devuelve el multiplicador a x1.
- **Núcleo del Behemoth**: punto vulnerable que rota por cuatro esquinas del metasprite. Cada impacto restaura Chromia; existe un breve cooldown para impedir que un solapamiento sostenido cuente varios golpes.

El combo conserva la ventana de **1,5 segundos**: desde 3 capturas puntúa x2 y desde 6 puntúa x3. La puntuación sigue saturada en 99 y la velocidad aumenta por puntuación y por fase.

## Escenario vivo, parallax y fauna

El gameplay ya no se apoya en un fondo casi vacío. `escenario.asm` dibuja un campo completo por fase sin aumentar el coste OAM del juego:

- **fase 1**: bandas de atmósfera, estrellas y lectura limpia de Chromia;
- **fase 2**: patrón de maquinaria/residuos y focos visuales industriales;
- **fase 3/final**: nebulosa más orgánica y croma disperso;
- el campo de juego usa la **paleta BG CGB 2** mediante atributos `rVBK`, separada de la paleta del HUD y de la paleta BG 1 reservada para Chromia.

El parallax es deliberadamente compatible con el HUD existente: no desplaza `rSCX/rSCY` de toda la pantalla. En su lugar hay dos bandas de estrellas en el tilemap, una actualizada cada **4 frames** y otra cada **8 frames**. Esa diferencia de velocidad crea profundidad sin mover el HUD ni el planeta.

La fauna también vive en el **background**, no en OAM:

- un ave solitaria funciona como testigo en la fase 1;
- la zona muerta queda vacía mientras Chromia siga degradado;
- al recuperar agua vuelve primero fauna acuática;
- con bosque regresan las aves;
- con Chromia vivo aparece además vegetación/fauna recuperada.

Ave y pez alternan dos frames de animación cada 16 frames. Como todo esto son tiles BG, el presupuesto del Glitch Behemoth se mantiene exactamente igual: **18 entradas OAM totales y máximo teórico de 6 sprites en una scanline**.

## Transiciones breves

Los cambios de fase tienen una transición visual corta de **36 frames** con iconografía mínima y sin textos largos. El cambio de fondo se hace con LCD apagado para evitar tearing, se reactiva inmediatamente y el juego continúa; no se altera `wTiempo` ni se introduce un `halt` adicional.

También hay aviso visual propio para la aparición del Behemoth y una marca final distinta según se haya disuelto el residuo o haya quedado contaminación activa.

## Restauración visual de Chromia

La restauración no es solo un número del HUD. El planeta aparece dentro del gameplay y cambia en cuatro escalones:

- `0–24`: **seco**, rodeado por cuatro restos de basura orbital;
- `25–49`: **agua**, desaparece parte del cinturón de residuos;
- `50–74`: **bosque**, queda un único foco visible;
- `75–99`: **vivo**, desaparecen los restos y la paleta recupera saturación.

Chromia usa tiles propios y una **paleta BG CGB independiente mediante atributos en `rVBK`**, de modo que el planeta puede recuperar color sin recolorear el HUD. En la fase 3 también cambia gradualmente la paleta global del espacio al cruzar esos mismos umbrales.

La pantalla final conserva el estado visual alcanzado. Además muestra una semilla si el Behemoth fue disuelto o un núcleo contaminado si el tiempo terminó antes.

## Glitch Behemoth y presupuesto OAM

El Behemoth es un metasprite **32×32** formado por una cuadrícula 4×4 de sprites de 8×8:

- 16 sprites de cuerpo;
- 1 sprite superpuesto para el núcleo vulnerable actual;
- 1 sprite para la nave del jugador.

El cuerpo ocupa como máximo **4 sprites en una misma scanline**. Sumando núcleo y jugador, el peor caso documentado es de **6 sprites por línea**, por debajo del límite hardware de 10. En total se usan 18 entradas OAM durante el boss, muy por debajo de las 40 disponibles.

Los cuatro núcleos se recorren en posiciones diferentes del cuerpo; no es una barra de vida abstracta. Cada impacto limpia un residuo, suma restauración y mueve el siguiente punto vulnerable.

## Controles

| Entrada | Acción |
| --- | --- |
| Cruceta | Mover la nave/cursor |
| A / Start | Empezar o reiniciar una partida |

## Récords en SRAM

La ROM usa la infraestructura MBC5 + 8 KiB RAM + batería introducida en #819. Guarda exclusivamente datos internos de `Pixel Exodus`:

- mejor puntuación;
- mejor combo;
- fase más alta alcanzada (`P4` indica final del Behemoth completado);
- mejor nivel de restauración.

El bloque de guardado empieza con la firma `PX98`, lleva versión y checksum. Si la SRAM está vacía, pertenece a otra versión o no supera la comprobación, los récords se inicializan de forma segura a cero.

La pantalla final muestra el resultado actual y los mejores valores persistidos. La RAM se protege inmediatamente después de leer o escribir.

**No existe integración de estos récords con `Partida`, `Jornada`, economía, pistas, sueños ni progreso de SIGA-98.** El `.sav` pertenece únicamente al cartucho emulado.

## Presentación GBC

- pantalla de título CGB a pantalla completa procedente de la lámina aprobada de #810;
- fallback de título de texto en DMG;
- cuatro paletas OBJ: nave, croma/núcleo, semilla y foco/Behemoth;
- paleta BG 0 para gameplay/HUD, BG 1 para Chromia y BG 2 para escenario por fase;
- fondos completos por fase con atributos CGB;
- parallax de dos velocidades sin desplazar el HUD;
- fauna animada y reactiva a restauración mediante tiles BG;
- metasprite 32×32 del Glitch Behemoth;
- transiciones visuales breves entre fases y aviso de boss;
- sonidos diferenciados para captura, restauración, cierre de foco, transición de fase, aparición del Behemoth, golpe de núcleo, victoria y derrota.

Todavía quedan en #882 la **música de fase completa**, cinemáticas más elaboradas que las transiciones actuales y las capturas/playtest visual humano final.

## Compilar

Requiere RGBDS 1.0.x; CI usa la versión fijada por el repositorio.

```bash
make
```

Salida:

```text
build/caza_pixeles_98.gbc
```

El byte CGB del encabezado es `0x80`. `cartucho.mk` fija MBC5+RAM+BATTERY (`0x1B`) y 8 KiB de SRAM (`0x02`). `Makefile` declara `escenario.asm` como dependencia explícita para que los cambios visuales fuercen recompilación incremental.

## Pruebas de regresión

```bash
make clean test
```

`test_rom.py` comprueba el contrato del combo y PRNG heredados y añade regresiones para:

- las tres fases y la entrada al final del Behemoth;
- los tres tipos de objetivo;
- la decisión restauración vs. combo de los focos;
- cuatro estados visuales de Chromia y sus atributos CGB;
- aparición, cuatro núcleos, cooldown y resolución del Behemoth;
- presupuesto OAM/scanline del metasprite;
- fondo completo por fase y paleta BG 2 vía `rVBK`;
- dos capas de parallax con cadencias diferentes y sin scroll global;
- fauna BG animada/reactiva que no consume OAM;
- transiciones temporizadas sin bloquear ni modificar el timer;
- HUD de fase/restauración;
- formato y protección de SRAM;
- cabecera CGB y cartucho con batería.

El smoke común del repositorio valida la ROM con `Siga98GB`, el mismo núcleo usado por la Portátil Color 98. Este README no afirma validación visual humana: las capturas comparativas y el playtest final forman parte del trabajo pendiente de #882.

## Integración

La ROM es standalone. El emulador proporciona framebuffer, audio, joypad y persistencia de RAM del cartucho. No depende de BIOS ni ROMs comerciales. El código se publica bajo la licencia MIT del repositorio.
