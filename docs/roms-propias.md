# Índice de ROMs propias

Fuente de verdad: [`godot/datos/roms_propias.json`](../godot/datos/roms_propias.json). Esta página la resume. Si cambia el JSON, cambia esta página; `scripts/test_roms_propias.py` falla si alguna ROM falta aquí.

Solo entran ROMs **propias**: código de este repositorio compilado con RGBDS desde `gbc/minijuegos/<id>`. Nunca BIOS, dumps ni ROMs comerciales. Las homebrew de terceros para probar el emulador van en [`gbc-fixtures.md`](gbc-fixtures.md) (#244), y las que aporta el jugador en `user://roms`, en [`roms-usuario.md`](roms-usuario.md).

## Jugables

| id | Título | Género | Dónde se consigue | Precio | Issues |
|---|---|---|---|---|---|
| `caza_pixeles_98` | Caza Píxeles 98 | arcade de 30 s | incluida con la consola | — | #124 #95 #384 #386 |
| `paper_planes_98` | Paper Planes 98 | vuelo; ruta Nueva York 1998 | tienda de videojuegos | 45 | #95 #388 |
| `croc_riders_98` | Croc Riders 98 | carreras; El Cairo → Giza | tienda de videojuegos | 45 | #95 #389 |
| `ryu_flow_98` | RYU FLOW | puzle de flujo; tres compuertas | tienda de videojuegos | 45 | #440 #442 #542 |

Las cuatro son de 32 KiB y modo dual CGB (`0x80`). Ninguna concede recompensas sistémicas por jugar. En `RYU FLOW`, arrancar y salir no cuenta como finalización: el micro-objetivo exige manipular las tres compuertas y resolver el cauce. El marcador local de completado queda preparado para #442, pero este corte todavía no activa la semilla Ryū ni modifica el selector nocturno.

## En proyecto

Contrapartes de vigilia de los sueños mitológicos (#435, #442). Tienen issue pero todavía no tienen fuente: no se compilan, no se venden y no aparecen en la consola.

| id | Título | Sueño | Idea | Issues |
|---|---|---|---|---|
| `ariadna_labertinto_98` | ARIADNA | Minotauro | laberinto de archivo; ya existe su cartucho 3D en casa | #437 #512 |
| `uruk_98` | URUK 98 | Gilgamesh | ciudad mínima y tablilla que reconstruir | #436 |
| `hydra_loop_98` | HYDRA LOOP | Hidra | cortar cabezas empeora todo hasta dar con el nodo común | #439 |
| `duat_98` | DUAT 98 | Duat | cámaras y contrapesos | #441 |
| `aquiles_98` | Sin título (Aquiles) | Aquiles | un rival que solo reacciona en un punto; título por decidir | #438 |

## Qué hace el índice

- **Build:** `scripts/preparar_emulador_gb.sh rom` compila todas las `jugable` y las deja en `godot/roms/<id>.gbc`. La exportación ya incluye `roms/*.gbc`. El workflow `gbc-fixtures` también las compila e inspecciona.
- **Tienda:** `TiendaVideojuegos.catalogo()` vende las jugables con precio (`RomsPropias.a_la_venta()`).
- **Consola:** la Portátil Color 98 y la consola de sobremesa muestran las `incluida` más las compradas en la jornada (`RomsPropias.en_consola`), siempre que el artefacto exista en la build.
- **Sueños:** la fuente de semilla de una ROM es `RomsPropias.fuente_semilla(id)` (`rom:<id>`). El cartucho ARIADNA del Minotauro ya la usa. `RYU FLOW` conserva su `mito` en el índice, pero su evento de finalización no se conecta aún a #442.

## Añadir una ROM

1. **Reservar:** abrir o usar su issue y añadir la entrada al JSON como `en_proyecto`, con un `id` definitivo (`^[a-z0-9_]+$`, que no se cambia después).
2. **Crear la fuente:** `gbc/minijuegos/<id>/` con `Makefile` (`ROM := build/<id>.gbc`), `README.md` y, si puede, `test_rom.py`.
3. **Declararla jugable:** pasarla a `jugable` con `fuente`, `rom`, `cabecera` (título del header, máximo 15 caracteres), `cgb`, y `precio` o `incluida`.
4. **Compilarla en el workflow:** añadirla a `.github/workflows/gbc-fixtures.yml`.
5. **Documentarla:** añadir su fila en esta página.

`scripts/test_roms_propias.py` comprueba:

- que cada carpeta de `gbc/minijuegos` está en el índice y viceversa;
- que toda `rom:<id>` o `res://roms/<id>.gbc` citada en `godot/guion` existe en el índice;
- que el workflow compila las jugables;
- que esta página lista todas las ROMs;
- con RGBDS instalado, que la cabecera compilada coincide con la declarada.
