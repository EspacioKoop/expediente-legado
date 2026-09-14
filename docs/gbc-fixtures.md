# Catálogo de fixtures GB/GBC para el emulador

Este catálogo acompaña #244 y #124. Es una lista de **fuentes de prueba**, no una carpeta de ROMs. No se versiona aquí ninguna BIOS, ROM comercial ni binario descargado de terceros.

`awesome-gbdev` y Homebrew Hub sirven para descubrir proyectos, pero **no prueban la licencia** de cada juego. La autoridad para decidir uso y redistribución es siempre el repositorio/proyecto original.

## Candidatos revisados

| id | proyecto | plataforma | licencia revisada | uso | distribución en SIGA-98 | fuente |
| --- | --- | --- | --- | --- | --- | --- |
| simple-gb-asm-examples | tbsp/simple-gb-asm-examples | GB | CC0-1.0 para código; revisar por fichero los pocos assets con licencia distinta | `joypad`, `vblank`, sprites, OAM DMA y tilemap; fixture mínimo | sí, **solo** ejemplos cuyos fuentes/assets concretos sean CC0 | https://github.com/tbsp/simple-gb-asm-examples |
| cgb-acid2 | mattcurrie/cgb-acid2 | GBC | MIT | exactitud PPU/color y regresión visual CGB | sí, conservando aviso MIT | https://github.com/mattcurrie/cgb-acid2 |
| SpaceGB | BotRandomness/SpaceGB | GB | MIT | ROM homebrew pequeña con input y gameplay real | sí, conservando aviso MIT y tras auditar assets incluidos | https://github.com/BotRandomness/SpaceGB |
| libbet | pinobatch/libbet | GB | Zlib | juego completo para estabilidad, input y ejecución prolongada | sí, conservando el aviso Zlib y tras auditar assets | https://github.com/pinobatch/libbet |
| ucity | AntonioND/ucity | GBC | GPL-3.0+ en código; medios CC BY-SA 4.0; otros componentes con licencias propias | compatibilidad GBC exigente, RAM/cartucho y guardado prolongado | **solo fixture externo** salvo aceptación explícita de todas las obligaciones | https://github.com/AntonioND/ucity |
| geometrix | AntonioND/geometrix | GB/GBC | GPL-3.0 | juego completo GB/GBC, input y compatibilidad prolongada | **solo fixture externo** por defecto | https://github.com/AntonioND/geometrix |

## Primera batería reproducible

La primera integración del emulador no necesita un catálogo enorme. Debe construir desde fuente, con una revisión fijada, al menos estas pruebas:

1. `simple-gb-asm-examples/joypad`: prueba específica de entrada y mapeo de botones.
2. `simple-gb-asm-examples/vblank`: temporización básica y actualización de vídeo.
3. `cgb-acid2`: prueba de PPU/color en modo CGB.

Los dos primeros son fixtures mínimos CC0 del mismo proyecto pero prueban subsistemas distintos. `cgb-acid2` añade una prueba CGB independiente bajo MIT.

## Política de fijado y hashes

Antes de usar un candidato en CI:

- fijar **commit o tag exacto** de la fuente;
- compilar desde fuente siempre que sea razonable;
- registrar versión de RGBDS/toolchain;
- calcular SHA-256 de la ROM resultante y comprobarlo en CI si el build es determinista;
- si se descarga un binario de una release, fijar URL/tag y **SHA-256 obligatorio**;
- revisar por separado licencias de código, gráficos, música y dependencias: la licencia detectada por GitHub no sustituye esa revisión.

No se copiarán binarios GPL/CC-BY-SA al repositorio principal solo porque sean open source. Para µCity y Geometrix el camino por defecto es descargar/compilar como fixture externo de desarrollo hasta que el proyecto decida expresamente asumir sus obligaciones de redistribución.

## Orden de uso cuando exista el emulador

1. arrancar `joypad` y comprobar entrada;
2. ejecutar `vblank` y un ejemplo de sprites/tilemap;
3. ejecutar `cgb-acid2` para PPU/color;
4. ejecutar `libbet` o `SpaceGB` como sesión de juego completa;
5. usar µCity como stress de GBC/RAM/guardado, externamente.

Esto mantiene separadas tres preguntas que no deben mezclarse: **¿emula bien?**, **¿podemos reproducir la prueba?** y **¿podemos redistribuir esa ROM con el juego?**

— Odiseo (GPT-5.6 Sol)
