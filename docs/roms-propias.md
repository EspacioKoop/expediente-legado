# Índice de ROMs propias

Fuente de verdad: [`godot/datos/roms_propias.json`](../godot/datos/roms_propias.json). Esta página la resume. Si cambia el JSON, cambia esta página; `scripts/test_roms_propias.py` falla si alguna ROM falta aquí.

Solo entran ROMs **propias**: código de este repositorio bajo `gbc/minijuegos/<id>`. Nunca BIOS, dumps ni ROMs comerciales. Las homebrew de terceros para probar el emulador van en [`gbc-fixtures.md`](gbc-fixtures.md) (#244), y las que aporta el jugador en `user://roms`, en [`roms-usuario.md`](roms-usuario.md).

## Jugables

| id | Título | Género | Dónde se consigue | Precio | Issues |
|---|---|---|---|---|---|
| `caza_pixeles_98` | Caza Píxeles 98 | arcade de 30 s | incluida con la consola | — | #124 #95 #384 #386 |
| `paper_planes_98` | Paper Planes 98 | vuelo; ruta Nueva York 1998 | tienda de videojuegos | 45 | #95 #388 |
| `croc_riders_98` | Croc Riders 98 | carreras; El Cairo → Giza | tienda de videojuegos | 45 | #95 #389 |
| `aquiles_98` | MYRMIDON 98 | duelo de observación; leer guardia y talón vulnerable | tienda de videojuegos | 45 | #438 #442 |
| `ryu_flow_98` | RYU FLOW | puzle de flujo; tres compuertas y cauce determinista | incluida con la consola | — | #440 #442 #542 #609 #622 |

Todas son ROMs propias de 32 KiB y modo dual CGB (`0x80`). `RYU FLOW` es la primera que expone además un handshake de finalización para integración diegética: completar realmente el cauce deja `0xA5` en WRAM `$C100`; arrancar, jugar a medias o salir no lo hace.

## En proyecto

Contrapartes de vigilia de los sueños mitológicos (#435, #442). Permanecen fuera de tienda, consola y build de runtime hasta que su vertical pueda activarse. Una entrada `en_proyecto` **puede tener ya una fuente prototipo** compilable en CI aislado: eso no la convierte en contenido jugable del runtime.

| id | Título | Sueño | Idea / estado | Issues |
|---|---|---|---|---|
| `ariadna_labertinto_98` | ARIADNA | Minotauro | laberinto de archivo; ya existe su cartucho 3D en casa | #437 #512 |
| `uruk_98` | URUK 98 | Gilgamesh | ciudad mínima y tablilla que reconstruir | #436 |
| `hydra_loop_98` | HYDRA LOOP | Hidra | cortar cabezas empeora todo hasta dar con el nodo común | #439 |
| `duat_98` | DUAT 98 | Duat | cámaras y contrapesos | #441 |

`RYU FLOW` salió de esta lista tras #609/#622: su fuente RGBDS es reproducible, el core puede leer su memoria sin efectos laterales y el índice la incluye en el build de runtime. `RyuFlowVigilia`, montado desde la casa real, observa la cabecera `RYUFLOW98` y solo cuando `$C100 == 0xA5` registra `dragon_japones` mediante `SemillasOniricas`; el emulador y la consola siguen sin conocer ese handshake concreto.

## Qué hace el índice

- **Build de runtime:** `scripts/preparar_emulador_gb.sh rom` compila solo las entradas `jugable` y las deja en `godot/roms/<id>.gbc`. Una fuente prototipo que siga `en_proyecto` queda fuera de ese build.
- **CI GBC:** `.github/workflows/gbc-fixtures.yml` puede compilar e inspeccionar también fuentes prototipo para demostrar que son reproducibles sin exponerlas al juego.
- **Tienda:** `TiendaVideojuegos.catalogo()` vende las jugables con precio (`RomsPropias.a_la_venta()`).
- **Consola:** la Portátil Color 98 y la consola de sobremesa muestran las `incluida` más las compradas en la jornada (`RomsPropias.en_consola`), siempre que el artefacto exista en la build.
- **Sueños:** la fuente de semilla de una ROM es `RomsPropias.fuente_semilla(id)` (`rom:<id>`). El cartucho ARIADNA del Minotauro ya la usa. `RYU FLOW` consume ese mismo contrato desde `RyuFlowVigilia`; arrancar la ROM por sí solo no registra nada.

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
