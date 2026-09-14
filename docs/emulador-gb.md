# Emulador GB de la Portátil Color 98

El vertical de #124 integra un núcleo nativo para que la portátil de la casa pueda ejecutar la ROM propia `Caza Píxeles 98` y ROMs locales aportadas opcionalmente por el jugador.

## Núcleo actual y licencia

La GDExtension usa dos dependencias fijadas por commit en `godot/native/siga98_gb/deps.lock.json`:

- `godotengine/godot-cpp`, licencia MIT, bindings oficiales de GDExtension;
- `deltabeard/Peanut-GB`, licencia MIT, núcleo de emulación Game Boy/DMG.

Las dependencias no se vendorizan ni se descargan en tiempo de juego. `scripts/preparar_emulador_gb.sh` las obtiene exclusivamente durante el build desde los commits fijados y genera las bibliotecas nativas.

No se incluye BIOS, boot ROM ni ROM comercial.

## Compatibilidad actual

Peanut-GB es un núcleo **DMG**, no un emulador Game Boy Color completo. Por eso este corte declara exactamente estas reglas:

- ROM Game Boy normal: compatible si el cartucho/MBC es admitido por Peanut-GB;
- cartucho dual-mode con byte CGB `0x80`: se admite en fallback DMG;
- ROM CGB-only con byte `0xC0`: se rechaza antes de inicializar el núcleo.

`Caza Píxeles 98` usa `0x80` y contiene fallback DMG, así que sirve como fixture propio para la integración. Sus paletas CGB no se reproducen todavía cuando corre mediante este núcleo.

`Siga98GB` expone además `core_name()`, `supports_cgb()` y `supports_audio()`. Con Peanut-GB esos valores son, respectivamente, `Peanut-GB`, `false` y `false`. El contrato permite sustituir el núcleo sin hacer que la UI deduzca capacidades a partir de errores o del nombre de una dependencia.

## Decisión para #456: candidato CGB + audio

El candidato seleccionado para el siguiente corte es **SameBoy/Core** (`LIJI32/SameBoy`) fijado para evaluación en el commit:

`213a12ce93d66b105a113debd9396306066a7cfc`

La licencia del repositorio declara que, salvo `iOS/` y `HexFiend/`, los archivos están bajo **Expat License**, una licencia permisiva compatible con el objetivo MIT del proyecto. La integración propuesta usaría únicamente `Core/`; no se incorporarán las excepciones de `iOS/` o `HexFiend/`.

La API pública y el frontend libretro de SameBoy confirman las piezas que necesita este proyecto:

- modelo CGB (`GB_MODEL_CGB_E`);
- carga de ROM desde memoria (`GB_load_rom_from_buffer`);
- framebuffer configurable (`GB_set_pixels_output`);
- ejecución por frame (`GB_run_frame`);
- APU con callback de muestras (`GB_apu_set_sample_callback`).

Esto permite conservar el contrato 160×144 de `Siga98GB`, añadir color real y llevar PCM al `AudioStreamGenerator` de Godot sin mezclarlo con los sonidos físicos de la carcasa de #245.

**Gearboy queda descartado para este proyecto**: aunque implementa Game Boy Color y audio, su repositorio declara GPL-3.0. Introducirlo en el binario actual incumpliría la restricción de #456 de no añadir accidentalmente un núcleo GPL.

SameBoy todavía **no es dependencia de runtime ni de build** en este corte. Primero se fija la decisión y el contrato de capacidades; el cambio de núcleo debe entrar en un PR separado con build Linux/Windows, fixture CGB legal y smoke correspondiente. No se añadirá ninguna BIOS o boot ROM propietaria para hacerlo funcionar.

## Ruta de integración SameBoy

El reemplazo del núcleo debe mantener estable la superficie usada por Godot:

1. conservar `load_rom`, `reset`, `set_buttons`, `run_frame_rgba`, `save_ram`, `load_save_ram`, `rom_title`, `last_error`, `width` y `height`;
2. cambiar `supports_cgb()` a `true` solo cuando una ROM CGB-only legal arranque y dibuje correctamente en CI;
3. añadir un buffer PCM nativo y activar `supports_audio()` solo cuando exista consumo real desde Godot;
4. mantener SRAM por identidad SHA-256 bajo `user://sram/gb`, independientemente del núcleo;
5. conservar soporte GB clásico y dual-mode y no tocar `Partida`, `Jornada` ni los guardados de campaña;
6. fijar el commit de SameBoy en la configuración de build antes de retirar Peanut-GB.

## Interfaz

Al usar la Portátil Color 98:

1. el mundo se pausa sin modificar `Partida` ni `Jornada`;
2. aparece el selector de ROMs;
3. se ofrece la ROM propia si la build la contiene;
4. se añaden los `.gb`/`.gbc` válidos descubiertos en `user://roms`;
5. la ROM elegida se carga en memoria y el núcleo produce un framebuffer RGBA de 160×144;
6. la SRAM de cartucho se restaura y guarda por ROM cuando corresponde;
7. `Esc` sale de la portátil y restaura el estado de pausa previo.

Controles del corte actual:

| Portátil | Teclado | Mando 0 |
| --- | --- | --- |
| Cruceta | Flechas o WASD | D-pad |
| A | Z o Espacio | A / botón inferior |
| B | X | B / botón derecho |
| Start | Enter | Start |
| Select | Tab | Back/Select |
| Salir | Esc | botón de UI |

## ROMs del jugador

`user://roms` sigue siendo una carpeta local, vacía por defecto. El proyecto no descarga ROMs, no ofrece enlaces para obtenerlas y no intenta convertir la presencia de un archivo en permiso para usarlo o redistribuirlo.

El catálogo solo acepta archivos directos `.gb`/`.gbc` de 32 KiB a 8 MiB. La persona que añade una ROM es responsable de tener derecho a usarla.

## SRAM por ROM

La persistencia de #456 está activa desde #458:

- identidad estable SHA-256 calculada sobre los bytes de la ROM;
- ruta `user://sram/gb/<sha256>.sav`;
- guardado al cambiar de ROM, cerrar la portátil o retirar la UI;
- reemplazo mediante `.nuevo` y respaldo `.anterior`;
- recuperación del respaldo si falta el save principal;
- snapshots incompatibles apartados como `.roto` en lugar de bloquear el arranque.

La SRAM no se escribe junto a la ROM ni dentro del repositorio y no forma parte del guardado de campaña.

## Aislamiento

El wrapper nativo recibe únicamente:

- bytes de la ROM seleccionada;
- estado de ocho botones;
- SRAM del cartucho correspondiente.

Devuelve el framebuffer RGBA, estado de capacidades y mensajes de error. No recibe referencias a `Partida`, `Jornada`, expedientes, dinero, pistas ni guardados del juego principal.

## Limitaciones pendientes de #456

- sin emulación CGB real mientras Peanut-GB siga activo;
- sin audio emulado mientras Peanut-GB siga activo;
- una ROM incompatible se rechaza en la inicialización cuando Peanut-GB puede identificarla;
- no se promete compatibilidad con todos los MBC o homebrew existentes.

## Build reproducible

En Linux, con RGBDS disponible para la ROM propia:

```bash
bash scripts/preparar_emulador_gb.sh linux-debug
bash scripts/preparar_emulador_gb.sh rom
```

Para generar bibliotecas de exportación:

```bash
bash scripts/preparar_emulador_gb.sh linux-all
bash scripts/preparar_emulador_gb.sh windows-release
```

CI ejecuta además `godot/pruebas/emulador_gb_smoke.gd`: carga `Caza Píxeles 98`, prueba la superficie SRAM nativa, ejecuta frames y exige un framebuffer de 160×144×4 bytes con contenido no uniforme.

— Odiseo (GPT-5.6 Sol)
