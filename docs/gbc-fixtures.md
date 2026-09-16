# Catálogo de fixtures GB/GBC para el emulador

Este catálogo acompaña #244 y #124. Es una lista de **fuentes de prueba**, no una carpeta de ROMs. No se versiona aquí ninguna BIOS, ROM comercial ni binario descargado de terceros.

`awesome-gbdev` y Homebrew Hub sirven para descubrir proyectos, pero **no prueban la licencia** de cada juego. La autoridad para decidir uso y redistribución es siempre el repositorio/proyecto original.

## Candidatos revisados

| id | proyecto | plataforma | licencia revisada | uso | distribución en SIGA-98 | fuente |
| --- | --- | --- | --- | --- | --- | --- |
| cgb_only_smoke | SIGA-98 (este repositorio) | GBC CGB-only | MIT | gate mínimo para núcleo CGB real: cabecera `0xC0`, paleta CGB y framebuffer | sí; se compila desde fuente y solo la ROM generada sale como artefacto efímero de CI | `gbc/fixtures/cgb_only_smoke/` |
| simple-gb-asm-examples | tbsp/simple-gb-asm-examples | GB | CC0-1.0 para código; revisar por fichero los pocos assets con licencia distinta | `joypad`, `vblank`, sprites, OAM DMA y tilemap; fixture mínimo | sí, **solo** ejemplos cuyos fuentes/assets concretos sean CC0 | https://github.com/tbsp/simple-gb-asm-examples |
| cgb-acid2 | mattcurrie/cgb-acid2 | GBC | MIT | exactitud PPU/color y regresión visual CGB | sí, conservando aviso MIT; en CI se compila desde `v1.1`/`fa5b7f86d6fb599f79e55169494d981a7af75a31` | https://github.com/mattcurrie/cgb-acid2 |
| SpaceGB | BotRandomness/SpaceGB | GB | MIT | ROM homebrew pequeña con input y gameplay real | sí, conservando aviso MIT y tras auditar assets incluidos | https://github.com/BotRandomness/SpaceGB |
| libbet | pinobatch/libbet | GB | Zlib | juego completo para estabilidad, input y ejecución prolongada | sí, conservando el aviso Zlib y tras auditar assets | https://github.com/pinobatch/libbet |
| ucity | AntonioND/ucity | GBC | GPL-3.0+ en código; medios CC BY-SA 4.0; otros componentes con licencias propias | compatibilidad GBC exigente, MBC5, RAM con batería, guardado y ejecución prolongada | **solo fixture externo**: CI lo descarga y verifica, pero no lo versiona ni lo publica como artefacto | https://github.com/AntonioND/ucity |
| geometrix | AntonioND/geometrix | GB/GBC | GPL-3.0 | juego completo GB/GBC, input y compatibilidad prolongada | **solo fixture externo** por defecto | https://github.com/AntonioND/geometrix |

## Primera batería reproducible

La primera integración del emulador no necesita un catálogo enorme. Debe construir desde fuente, con una revisión fijada cuando sea externa, al menos estas pruebas:

1. `simple-gb-asm-examples/joypad`: prueba específica de entrada y mapeo de botones.
2. `simple-gb-asm-examples/vblank`: temporización básica y actualización de vídeo.
3. `cgb_only_smoke`: fixture propio CGB-only. La cabecera usa `0xC0`, programa la paleta BG mediante `BCPS/BCPD` y dibuja un patrón; desde #456 el núcleo SameBoy lo arranca y CI lo verifica con `godot/pruebas/emulador_gbc_smoke.gd`.
4. `cgb-acid2`: prueba independiente de PPU/color CGB, compilada desde fuente por `GBC fixtures` y publicada solo como artefacto efímero.
5. `ucity v1.3`: juego GBC completo para estrés de MBC5, RAM con batería, guardado y ejecución prolongada. Se descarga únicamente como fixture externo durante CI, se verifica por tag/commit, tamaño, SHA-256 y cabecera, y **no** se incluye en el artefacto de ROMs de SIGA-98.

Los dos primeros son fixtures mínimos CC0 del mismo proyecto pero prueban subsistemas distintos. `cgb_only_smoke` funciona como puerta reproducible de integración sin depender de una ROM de terceros. `cgb-acid2` añade una prueba externa independiente bajo MIT, fijada a una revisión conocida. µCity cubre por fin el caso de una ROM GBC completa sin convertirla en contenido redistribuido por SIGA-98.

## Revisiones externas activas en CI

El workflow `.github/workflows/gbc-fixtures.yml` fija las fuentes externas que realmente materializa:

- `tbsp/simple-gb-asm-examples` → commit `54270e0673ac16452447ff65cca26a1ef42eefec`;
- `mattcurrie/cgb-acid2` → tag `v1.1`, commit `fa5b7f86d6fb599f79e55169494d981a7af75a31`;
- submódulo `mattcurrie/mgblib` usado por esa revisión → commit `5d829bf2ffa1447dcfd63c5dab2c44488632617e`;
- RGBDS actual para fixtures propios y `simple-gb-asm-examples` → `v1.0.3`, cuyo paquete Linux se verifica por SHA-256 antes de instalar;
- RGBDS histórico para `cgb-acid2 v1.1` → `v0.3.10`, commit `0759c98d913e3d4d21207a8886a319c85add2041`, compilado desde fuente con `-fcommon` para compatibilidad con GCC moderno y usado únicamente mediante un `PATH` local durante ese build;
- ROM resultante `cgb-acid2.gbc` → SHA-256 esperado `197fb0bcec544f0400527fc707e0a94f55435974986e6986b424ace5de81720e`;
- `AntonioND/ucity` → tag `v1.3`, commit `d1880a2a112d7c26f16c0fc06a15b6c32fdc9137`;
- release `ucity.gbc` de `v1.3` → 131072 bytes, SHA-256 `9422ee2ca7b7ea1d46b58b2a429fff3f354dfd3e732dee1e7ae6220f148ce6e0`.

`cgb-acid2 v1.1` usa sintaxis de RGBDS anterior a la aceptada por `v1.0.3`; por eso CI conserva un toolchain histórico aislado en lugar de modificar la fuente de upstream. El workflow comprueba los commits de ambos repositorios y del toolchain, compila `joypad`, `vblank` y `cgb-acid2`, verifica el SHA-256 determinista de Acid2, valida que `cgb-acid2.gbc` sea CGB-only (`0xC0`), calcula `SHA256SUMS` junto al resto de ROMs generadas y conserva esos binarios únicamente como artefactos efímeros durante 7 días.

Para µCity, CI resuelve `refs/tags/v1.3` y exige que apunte al commit fijado antes de descargar la ROM oficial de la release. Después comprueba el SHA-256, el tamaño exacto de 128 KiB y los campos relevantes de cabecera: CGB-only (`0xC0`), cartucho MBC5+RAM+batería (`0x1B`), ROM de 128 KiB (`0x02`) y RAM de 128 KiB/1 Mbit (`0x04`). El fichero vive en `external-fixtures/` durante el job y no entra en `gbc-fixtures/`, `SHA256SUMS` ni `actions/upload-artifact`.

## Política de fijado y hashes

Antes de usar un candidato en CI:

- fijar **commit o tag exacto** de la fuente;
- compilar desde fuente siempre que sea razonable;
- registrar versión de RGBDS/toolchain;
- calcular SHA-256 de la ROM resultante y comprobarlo en CI si el build es determinista;
- si se descarga un binario de una release, fijar URL/tag y **SHA-256 obligatorio**;
- revisar por separado licencias de código, gráficos, música y dependencias: la licencia detectada por GitHub no sustituye esa revisión.

No se copiarán binarios GPL/CC-BY-SA al repositorio principal solo porque sean open source. Para µCity y Geometrix el camino por defecto es descargar/compilar como fixture externo de desarrollo hasta que el proyecto decida expresamente asumir sus obligaciones de redistribución. La integración de µCity en CI mantiene esa frontera: se consume temporalmente para verificar procedencia y compatibilidad, pero no se publica como artefacto de SIGA-98.

## Orden de uso cuando exista el emulador

1. arrancar `joypad` y comprobar entrada;
2. ejecutar `vblank` y un ejemplo de sprites/tilemap;
3. ejecutar `cgb_only_smoke` como gate de CGB-only y color básico;
4. ejecutar `cgb-acid2` para PPU/color;
5. ejecutar µCity como sesión GBC completa y stress de MBC5/RAM/guardado;
6. ejecutar `libbet` o `SpaceGB` como sesiones completas adicionales de GB.

Esto mantiene separadas tres preguntas que no deben mezclarse: **¿emula bien?**, **¿podemos reproducir la prueba?** y **¿podemos redistribuir esa ROM con el juego?**

— Odiseo (GPT-5.6 Sol)
