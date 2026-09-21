# LUZ_JALI_98 — pack de arte para #932

Primer corte **solo de assets** para una micro-ROM de la Portátil Color 98. No implementa todavía el bucle completo ni el handshake de exposición cultural.

## Contenido

- `assets/jali_tiles.inc`: 16 tiles originales de 8×8 en bytes 2bpp listos para RGBDS.
- `assets/jali_tilemap.asm`: mapa 20×18 (160×144).
- `assets/jali_palette.inc`: paleta CGB de 4 colores en BGR555.
- `referencia/jali_light_puzzle_v1.svg`: referencia visual versionable sin Git LFS.
- `referencia/PROCEDENCIA.md`: origen, límites de representación y hashes.

## Dirección jugable

La pantalla propone una retícula perforada y un haz de luz. El futuro puzzle puede rotar/reordenar módulos para conducir la proyección hasta una zona objetivo. La interacción debe entenderse por geometría y luz, no por trivia doctrinal.

No hay texto sagrado, nombres divinos, iconos usados como moneda/vida/daño ni recompensa laboral. Completar la futura ROM deberá registrar únicamente **exposición cultural** mediante el contrato común de religión.

## Integración prevista

Los tres ficheros de `assets/` se pueden incluir desde una ROM RGBDS existente con `INCLUDE`. Este PR no crea un emulador, no duplica la Portátil Color 98 y no toca `Partida`.

Refs #916 #932.
