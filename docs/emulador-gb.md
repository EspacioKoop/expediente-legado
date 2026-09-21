# Emulador GB de la Portátil Color 98

El vertical de #124 integra un núcleo nativo para que la portátil de la casa pueda ejecutar las ROMs propias del índice `godot/datos/roms_propias.json` y ROMs locales aportadas opcionalmente por el jugador.

## Núcleo actual y licencia

La GDExtension usa dos dependencias fijadas por commit en `godot/native/siga98_gb/deps.lock.json`:

- `godotengine/godot-cpp`, licencia MIT, bindings oficiales de GDExtension;
- `LIJI32/SameBoy`, licencia Expat para el alcance usado (`Core/` y `BootROMs/`), **núcleo activo** en modelo CGB-E.

Las dependencias no se vendorizan ni se descargan en tiempo de juego. `scripts/preparar_emulador_gb.sh` las obtiene exclusivamente durante el build desde los commits fijados y genera las bibliotecas nativas.

No se incluye BIOS de Nintendo ni ROM comercial. La boot ROM que necesita el modelo CGB es `BootROMs/cgb_boot_fast.asm` de SameBoy: código original bajo Expat, compilado desde fuente con RGBDS v1.0.3 y comprobado contra el SHA-256 fijado en el lock. `SConstruct` la incrusta en la biblioteca, así que el juego nunca busca ficheros de BIOS en disco.

## Compatibilidad actual

SameBoy ejecuta hardware Game Boy Color real:

- ROM Game Boy clásica: arranca en un CGB con la paleta de compatibilidad que asigna la boot ROM; `dmg_only_smoke.gb` (flag CGB `0x00`) lo verifica de forma explícita en CI;
- cartucho dual-mode con byte CGB `0x80`: corre en modo Color con sus propias paletas;
- ROM CGB-only con byte `0xC0`: se admite (`LOAD_CGB_ONLY` se conserva en la API por estabilidad, pero ya no se devuelve);
- cabecera con checksum incorrecto: se rechaza con `LOAD_INVALID_ROM`, como ya hacía el núcleo anterior.

La boot ROM rápida tarda unos 16 frames en ceder el control al cartucho.

`Siga98GB` expone `core_name()`, `supports_cgb()` y `supports_audio()`, que ahora devuelven `SameBoy`, `true` y `true`. La APU entrega PCM S16LE estéreo a 48 kHz y la Portátil Color 98 lo consume mediante un `AudioStreamGenerator` separado de los sonidos físicos de carcasa.

## Decisión para #456: SameBoy/Core

El núcleo seleccionado es **SameBoy/Core** (`LIJI32/SameBoy`) fijado en el commit:

`213a12ce93d66b105a113debd9396306066a7cfc`

La licencia del repositorio declara que, salvo `iOS/` y `HexFiend/`, los archivos están bajo **Expat License**, una licencia permisiva compatible con el objetivo MIT del proyecto. La integración usa únicamente `Core/`; no se incorporan las excepciones de `iOS/` o `HexFiend/`.

La API pública confirma las piezas que necesita este proyecto:

- modelo CGB (`GB_MODEL_CGB_E`);
- carga de ROM desde memoria (`GB_load_rom_from_buffer`);
- framebuffer configurable (`GB_set_pixels_output`);
- ejecución por frame (`GB_run_frame`);
- persistencia de batería mediante buffer;
- APU con callback de muestras (`GB_apu_set_sample_callback`).

Esto permite conservar el contrato 160×144 de `Siga98GB`, añadir color real y llevar PCM al `AudioStreamGenerator` de Godot sin mezclarlo con los sonidos físicos de la carcasa de #245.

**Gearboy queda descartado para este proyecto**: aunque implementa Game Boy Color y audio, su repositorio declara GPL-3.0. Introducirlo en el binario actual incumpliría la restricción de #456 de no añadir accidentalmente un núcleo GPL.

SameBoy ya es una **dependencia de build**: el preparador obtiene el commit fijado y `SConstruct` compila `Core/*.c` dentro de la GDExtension, excluyendo debugger, cheats, cheat search, rewind y disassembler/symbols. Ese staging (#500) forzó a Linux/Windows a detectar incompatibilidades de compilación antes de cambiar el núcleo visible; desde #555 SameBoy es el adapter de runtime.

## Integración SameBoy

El cambio de adapter conservó la superficie usada por Godot:

1. `load_rom`, `reset`, `set_buttons`, `run_frame_rgba`, `save_ram`, `load_save_ram`, `rom_title`, `last_error`, `width` y `height` no cambian de firma;
2. internamente se usan `GB_MODEL_CGB_E`, `GB_load_rom_from_buffer`, `GB_set_pixels_output` y `GB_run_frame`;
3. `set_buttons` mantiene el orden de bits público (A, B, Select, Start, Derecha, Izquierda, Arriba, Abajo) y lo traduce a `GB_set_key_state`;
4. la SRAM usa `GB_save_battery_to_buffer` / `GB_load_battery_from_buffer` con la misma identidad SHA-256 bajo `user://sram/gb`. Para cartuchos sin reloj el formato son los mismos bytes crudos; en cartuchos con RTC el tamaño incluye el reloj y un save antiguo se aparta como `.roto`;
5. Peanut-GB se ha retirado del build tras superar los smoke GB y CGB-only;
6. la APU de SameBoy se captura a 48 kHz como S16LE estéreo y `EmuladorPortatilAudioApp` lo convierte a frames estéreo normalizados para `AudioStreamGeneratorPlayback`.

El backlog nativo está limitado a un segundo y el consumer Godot a 9600 frames. El audio pendiente se limpia al cambiar de ROM, mutear, cerrar o retirar la UI. Volumen y mute del audio de ROM son independientes de los sonidos físicos procedurales de #245.

## Interfaz

Al usar la Portátil Color 98:

1. el mundo se pausa sin modificar `Partida` ni `Jornada`;
2. aparece el selector de ROMs;
3. se ofrece la ROM propia si la build la contiene;
4. se añaden los `.gb`/`.gbc` válidos descubiertos en `user://roms`;
5. la ROM elegida se carga en memoria y el núcleo produce un framebuffer RGBA de 160×144;
6. la SRAM de cartucho se restaura y guarda por ROM cuando corresponde;
7. el PCM de la ROM se reproduce por un stream dedicado, separado de clics/sonidos de carcasa;
8. `Esc` sale de la portátil, corta el audio pendiente y restaura el estado de pausa previo.

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

El gate end-to-end de #456 compila dos cartuchos MBC5+batería propios con marcadores distintos. `emulador_sram_smoke.gd` abre la UI real, ejecuta la primera ROM, cierra la Portátil Color 98 para forzar el guardado, crea otra instancia y exige que el snapshot se restaure antes de ejecutar de nuevo. Después repite con una segunda ROM y comprueba que ambas rutas SHA-256 y sus contenidos permanecen aislados.


## Link Cable diegético (#245)

La primera versión del Link Cable es deliberadamente local y modular:

- `LinkCablePortatil` mantiene únicamente el estado conectado/desconectado de la sesión;
- la portátil muestra un cable procedural junto a la carcasa y mueve el conector al enchufarlo;
- la UI permite conectar/desconectar y muestra «esperando otra consola»;
- el gesto tiene un clic físico procedural separado del audio de la ROM;
- no hay networking, `PacketPeer`, ENet ni emulación del puerto serie en este corte;
- el módulo no conoce `Siga98GB`, `Partida`, `Jornada`, pistas, economía ni guardados.

El objetivo es fijar primero el objeto, el ritual y el contrato. Un backend serie real puede
sustituir el estado local más adelante sin reescribir la representación 3D ni la UI.


## Puerto IR ambiental/local (#245)

El primer corte de infrarrojos mantiene el mismo enfoque modular del Link Cable:

- `PuertoIRPortatil` solo cuenta pulsos locales de la sesión y emite una señal Godot;
- la carcasa incorpora una lente IR procedural propia con un destello breve al emitir;
- la UI ofrece un pulso de prueba y muestra que no existe receptor local;
- no se llama a `Siga98GB` ni se intenta simular tráfico de una ROM;
- no hay protocolo IR, networking, recompensas, pistas ni persistencia;
- la representación queda lista para conectar más adelante un backend compatible o
  receptores ambientales de la casa sin mezclarlo con campaña.

Este corte es deliberadamente visual/ambiental. No afirma compatibilidad con accesorios
o juegos reales y no inventa semántica de protocolo.


## Impresora térmica diegética (#1054)

El primer corte de impresión mantiene el periférico fuera del núcleo y de la campaña:

- `ImpresoraTermicaPortatil` implementa una cola FIFO local con estados apagada, lista,
  imprimiendo y papel disponible;
- la entrada estable es una `Image` o un framebuffer RGBA entregado explícitamente por
  Godot; este corte no implementa el protocolo de una impresora comercial ni afirma
  compatibilidad con hardware real;
- la prueba visible usa un **patrón procedural propio** y determinista, convertido a una
  trama térmica monocroma de 160 píxeles de ancho;
- `ImpresoraTermicaPortatil3D` vive junto a la Portátil Color 98 como objeto separado,
  con LED, tira que emerge, textura del papel y un traqueteo `AudioStreamWAV` generado
  en tiempo de ejecución;
- sonido y animación son capas externas con interruptores propios; la cola sigue
  funcionando aunque se desactive su presentación;
- cerrar la portátil no cancela ni bloquea el trabajo: el controlador pertenece al
  objeto físico de la casa y avanza con `PROCESS_MODE_ALWAYS`;
- recoger la tira solo la retira del periférico. Es una interacción decorativa, sin recompensas
  sistémicas: no entra en inventario, no se guarda y no concede dinero, pistas, acciones ni
  desbloqueos.

Un adaptador de protocolo real, si se añade más adelante con fixtures propios y licencia
clara, deberá alimentar la misma entrada RGBA. Así puede sustituirse la fuente de imagen
sin reescribir cola, papel, sonido o representación 3D.


## Aislamiento

El wrapper nativo recibe únicamente:

- bytes de la ROM seleccionada;
- estado de ocho botones;
- SRAM del cartucho correspondiente.

Devuelve el framebuffer RGBA, PCM de audio, estado de capacidades y mensajes de error. No recibe referencias a `Partida`, `Jornada`, expedientes, dinero, pistas ni guardados del juego principal.

## Limitaciones pendientes de #456

- la ROM de SIGA-98 corre en modelo CGB; no hay selector de modelo DMG/GBA;
- no se promete compatibilidad con todos los MBC o homebrew existentes;
- el smoke headless verifica producción y consumo contractual de PCM, pero la latencia y continuidad audible requieren una pasada manual en una alpha con dispositivo de audio real.

## Build reproducible

En Linux, con RGBDS v1.0.3 y un compilador C disponibles (la boot ROM y las ROMs propias se ensamblan con RGBDS):

```bash
bash scripts/preparar_emulador_gb.sh linux-debug
bash scripts/preparar_emulador_gb.sh rom
```

El build nativo descarga los commits fijados de godot-cpp y SameBoy, y compila la boot ROM si no existe en `godot/native/siga98_gb/.deps/bootroms/`. Para generar bibliotecas de exportación:

```bash
bash scripts/preparar_emulador_gb.sh linux-all
bash scripts/preparar_emulador_gb.sh windows-release
```

El runner Windows no tiene RGBDS: la alpha compila la boot ROM en Linux (`preparar_emulador_gb.sh boot-rom`), la pasa como artefacto y `SConstruct` vuelve a verificar su SHA-256 antes de incrustarla.

CI ejecuta tres gates de compatibilidad:

- `godot/pruebas/emulador_dmg_smoke.gd -- <rom>`: compila y carga `dmg_only_smoke.gb`, exige flag CGB `0x00`, núcleo SameBoy y framebuffer 160×144 no uniforme;
- `godot/pruebas/emulador_gb_smoke.gd`: carga `Caza Píxeles 98` (dual-mode, flag `0x80`), prueba SRAM, framebuffer y PCM nativo a 48 kHz, y exige `supports_audio() == true`;
- `godot/pruebas/emulador_gbc_smoke.gd -- <rom>`: carga `cgb_only_smoke.gbc` (flag `0xC0`) y exige píxeles rojos y verdes puros de la paleta CGB, imposibles en un núcleo DMG.

Así, el CI de #456 cubre explícitamente los tres modos exigidos: GB clásico, dual-mode y CGB-only.
El fixture DMG usa solo registros clásicos (LCDC/BGP), de modo que el gate no depende accidentalmente de una ruta exclusiva de CGB.

Además, `emulador_sram_smoke.gd` compila y ejecuta `sram_a.gbc` y `sram_b.gbc` para validar persistencia a disco tras cierre/reapertura y aislamiento real de SRAM entre dos identidades de ROM.

— Odiseo (GPT-5.6 Sol)
