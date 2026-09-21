# Índice de ROMs propias

Fuente de verdad: [`godot/datos/roms_propias.json`](../godot/datos/roms_propias.json). Esta página la resume. Si cambia el JSON, cambia esta página; `scripts/test_roms_propias.py` falla si alguna ROM falta aquí.

Solo entran ROMs **propias**: código de este repositorio bajo `gbc/minijuegos/<id>`. Nunca BIOS, dumps ni ROMs comerciales. Las homebrew de terceros para probar el emulador van en [`gbc-fixtures.md`](gbc-fixtures.md) (#244), y las que aporta el jugador en `user://roms`, en [`roms-usuario.md`](roms-usuario.md).

## Jugables

| id | Título | Género | Dónde se consigue | Precio | Issues |
|---|---|---|---|---|---|
| `caza_pixeles_98` | Pixel Exodus | arcade de 30 s | incluida con la consola | — | #124 #95 #384 #386 |
| `paper_planes_98` | Paper Planes 98 | vuelo; ruta Nueva York 1998 | tienda de videojuegos | 45 | #95 #388 |
| `croc_riders_98` | Croc Riders 98 | carreras; El Cairo → Giza | tienda de videojuegos | 45 | #95 #389 |
| `aquiles_98` | MYRMIDON 98 | duelo de observación; leer guardia y talón vulnerable | tienda de videojuegos | 45 | #438 #442 |
| `ryu_flow_98` | River of the Dragon | puzle de flujo; tres compuertas y cauce determinista | tienda de videojuegos | 45 | #440 #442 #542 #609 #622 #627 |
| `jali_98` | JALI 98 | puzle de luz y geometría; tres bandas de calado | tienda de videojuegos | 45 | #932 #916 #931 |
| `vitral_98` | VITRAL 98 | puzle de composición y luz; cuatro piezas de vidrio/plomo | tienda de videojuegos | 45 | #932 #916 #931 |
| `sarnath_98` | SARNATH 98 | memoria y orientación; tres rutas abstractas | tienda de videojuegos | 45 | #932 #916 #931 |

Todas son ROMs propias en modo dual CGB (`0x80`) sobre el cartucho estándar del proyecto: **MBC5 con 8 KiB de RAM y batería** (`gbc/minijuegos/comun/cartucho.mk` y `cartucho.asm`). Cada ROM llama a `IniciarCartucho` al arrancar, mapea las secciones `ROMX` con `CAMBIAR_BANCO` y carga las pantallas CGB con `CARGAR_PANTALLA_CGB`, que devuelve el banco que hubiera. Ocupan 32 KiB salvo River of the Dragon (64 KiB), y la portátil guarda la RAM de cada una en su propio `.sav`, lista para récords. Tras #808, Pixel Exodus, River of the Dragon y Kwaku, el guardameta muestran en Game Boy Color una pantalla de título a pantalla completa convertida de su lámina de concept art (`referencia/PROCEDENCIA.md`); en Game Boy clásica conservan el título de texto. Los ids y los títulos de cabecera no cambian. River of the Dragon lleva además en GBC la pantalla de juego y la de victoria de su lámina (`gbc/minijuegos/ryu_flow_98/generar_arte.py`): cada torii se abre o se cierra cambiando sus tiles, el HUD tiene paletas propias y los iconos, los dragones despiertos y los movimientos se actualizan en directo. Tiene tres niveles en GBC —1-1 día (abrir o cerrar), 1-2 amanecer (compuertas a medias) y 1-3 noche (cada compuerta arrastra a la de su derecha)— con la misma escena bajo otras paletas, un diálogo del anciano al empezar cada uno, el agua animada por brillo de paleta y la cabeza del dragón animada sobre la escena (reposo, abre el ojo al acertar una compuerta y ruge en la victoria); el handshake se escribe al superar el 1-3. En Game Boy clásica se juega solo el 1-1. `RYU FLOW` es la primera que expone además un handshake de finalización para integración diegética: completar realmente el cauce deja `0xA5` en WRAM `$C100`; arrancar, jugar a medias o salir no lo hace.

`JALI 98` reutiliza el mismo patrón técnico para una exposición cultural documentada en #932: tres bandas de calado geométrico deben manipularse hasta recomponer la proyección. Solo entonces escribe `0xA5` en `$C100`. `Jali98Vigilia` traduce ese byte al canal común de exposición de `ReligionEventos`; no registra práctica ni convicción. El diseño se documenta en `docs/religion-rom-jali-932.md` y parte de un jali mogol concreto del Met (1993.67.1), sin copiar su patrón.

`VITRAL 98` demuestra que ese observer común no está acoplado a una única tradición: cuatro piezas abstractas de vidrio/plomo deben recomponerse siguiendo una lógica de diseño de taller. El contrato técnico es el mismo (`$C100 = 0xA5` solo al completar), pero la procedencia cambia a vidriera cristiana medieval europea documentada por el V&A. No reproduce escenas religiosas; registra exposición cultural mediante `Vitral98Vigilia`. Véase `docs/religion-rom-vitral-932.md`.

`SARNATH 98` cambia de mecánica: el jugador observa y memoriza tres secuencias de rumbo abstractas. No reproduce el plano de Sarnath ni una ruta histórica; la documentación UNESCO de 2026 se usa para fijar la procedencia del sitio y su condición serial. `Sarnath98Vigilia` registra exposición cultural budista solo tras completar las tres rondas. Véase `docs/religion-rom-sarnath-932.md`.

## En proyecto

Contrapartes de vigilia de los sueños mitológicos (#435, #442). Permanecen fuera de tienda, consola y build de runtime hasta que su vertical pueda activarse. Una entrada `en_proyecto` **puede tener ya una fuente prototipo** compilable en CI aislado: eso no la convierte en contenido jugable del runtime.

| id | Título | Sueño | Idea / estado | Issues |
|---|---|---|---|---|
| `ariadna_labertinto_98` | Ariadne, el hilo del laberinto | Minotauro | laberinto de archivo; ya existe su cartucho 3D en casa | #437 #512 |
| `uruk_98` | URUK 98 | Gilgamesh | ciudad mínima y tablilla que reconstruir | #436 |
| `hydra_loop_98` | HYDRA LOOP | Hidra | **fuente prototipo jugable**: cortar hace brotar dos cabezas; sellar un nodo exige haber leído dos cabezas suyas; tres niveles y handshake `$C100 = 0xA5` al romper el bucle | #439 #600 |
| `webkeeper_98` | Kwaku, el guardameta | Anansi akan | **fuente prototipo jugable**: Kwaku, una araña-portero, disputa tres partidos breves; amagos legibles, telaraña de emergencia, reintento local y handshake solo al ganar la final | #748 #656 #442 |
| `duat_98` | DUAT 98 | Duat | cámaras y contrapesos | #441 |

`HYDRA LOOP` tiene ya fuente prototipo en `gbc/minijuegos/hydra_loop_98` (portada de `gbc/minijuegos/hydra_loop`) y se compila y prueba con PyBoy en el workflow GBC. Sigue fuera del runtime: `HidraVigilia` no lee todavía su handshake.

`WEBKEEPER 98` abre el género **deportivo / portero arcade**. El debut pide 3 paradas de 6, el segundo partido 4 de 8 y la final 5 de 9. Los amagos cambian de destino visual antes del tiro con una ventana de reacción explícita; tras dos derrotas en el mismo partido se activa una ayuda que muestra directamente el destino real. Perder repite solo el encuentro actual. La ROM mantiene `$C100 == 0` durante arranque, derrotas y victorias parciales, y escribe `0xA5` únicamente al completar la final. Sigue `en_proyecto`: aún no se vende ni activa `anansi_akan` desde el runtime.

`RYU FLOW` salió de esta lista tras #609/#622: su fuente RGBDS es reproducible, el core puede leer su memoria sin efectos laterales y el índice la incluye en el build de runtime. Se mantiene en la tienda, igual que las demás ROMs jugables no incluidas, para respetar el contrato de una sola ROM de serie. `RyuFlowVigilia`, montado desde la casa real, observa la cabecera `RYUFLOW98` y solo cuando `$C100 == 0xA5` registra `dragon_japones` mediante `SemillasOniricas`; el emulador y la consola siguen sin conocer ese handshake concreto.

## Qué hace el índice

- **Build de runtime:** `scripts/preparar_emulador_gb.sh rom` compila solo las entradas `jugable` y las deja en `godot/roms/<id>.gbc`. Una fuente prototipo que siga `en_proyecto` queda fuera de ese build.
- **CI GBC:** `.github/workflows/gbc-fixtures.yml` puede compilar e inspeccionar también fuentes prototipo para demostrar que son reproducibles sin exponerlas al juego.
- **Tienda:** `TiendaVideojuegos.catalogo()` vende las jugables con precio (`RomsPropias.a_la_venta()`).
- **Consola:** la Portátil Color 98 y la consola de sobremesa muestran las `incluida` más las compradas en la jornada (`RomsPropias.en_consola`), siempre que el artefacto exista en la build.
- **Sueños:** la fuente de semilla de una ROM es `RomsPropias.fuente_semilla(id)` (`rom:<id>`). El cartucho ARIADNA del Minotauro ya la usa. `RYU FLOW` consume ese mismo contrato desde `RyuFlowVigilia`; comprarla o arrancarla por sí solo no registra nada: hace falta resolver el cauce.

## Añadir una ROM

1. **Reservar:** abrir o usar su issue y añadir la entrada al JSON como `en_proyecto`, con un `id` definitivo (`^[a-z0-9_]+$`, que no se cambia después).
2. **Crear un prototipo de fuente, si procede:** `gbc/minijuegos/<id>/` con `Makefile` (`ROM := build/<id>.gbc`), `README.md` y, si puede, `test_rom.py`. Mientras siga `en_proyecto`, mantener `rom` vacío, `precio: 0` e `incluida: false`.
3. **Validarlo en CI:** una fuente prototipo puede añadirse a `gbc-fixtures.yml` sin entrar todavía en el runtime.
4. **Declararla jugable:** cuando las dependencias del vertical estén liberadas, pasarla a `jugable`, rellenar `rom: res://roms/<id>.gbc` y fijar `precio` o `incluida`.
5. **Documentarla:** reflejar el cambio de estado en esta página.

`scripts/test_roms_propias.py` comprueba:

- que cada carpeta con `Makefile` de `gbc/minijuegos` tiene una entrada indexada con `fuente` y viceversa;
- que una entrada `en_proyecto` puede tener fuente, cabecera y modo CGB, pero no ruta de runtime, precio ni inclusión;
- que toda fuente declarada se valida en el workflow GBC;
- que toda `rom:<id>` o `res://roms/<id>.gbc` citada en `godot/guion` existe en el índice;
- que esta página lista todas las ROMs;
- con RGBDS instalado, que cualquier fuente declarada compila con la cabecera y modo CGB del índice.
