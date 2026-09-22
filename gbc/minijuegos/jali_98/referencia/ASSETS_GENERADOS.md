# Assets generados para JALI 98

Este pack visual suplementa la ROM `jali_98` integrada por #1158. No crea otra ROM ni cambia el handshake, la solución del puzzle o el contrato de exposición cultural.

## Ficheros

- `../assets/jali_art_tiles.inc`: 16 tiles originales de 8×8 en datos 2bpp.
- `../assets/jali_art_tilemap.asm`: composición de referencia 20×18 / 160×144.
- `../assets/jali_art_palette.inc`: paleta CGB de cuatro colores.
- `jali_light_puzzle_v1.svg`: referencia visual vectorial de la composición.

Los datos no sustituyen automáticamente los tiles semánticos que usa actualmente `main.asm`; quedan como material de arte listo para una revisión visual posterior de JALI 98 sin mezclar esa revisión con la lógica ya validada.

## Procedencia

Arte original generado para EspacioKoop en esta conversación con OpenAI y postprocesado determinista local el 2026-09-21. La fuente raster de trabajo fue `jali_light_puzzle_160x144.png`, SHA-256 `3438bb30d5767725b2b49d0cb84b439a37f8ce88bfa2a944b0fbc08712774829`.

El PNG no se versiona porque `*.png` usa Git LFS y este flujo no puede subir de forma segura el objeto LFS. El SVG y los datos RGBDS son textuales.

## Frontera de representación

Se conserva la documentación ya fijada por #1158: geometría, calado, luz y sombra; sin texto coránico, nombres divinos, caligrafía sagrada ni símbolos convertidos en pickups. El pack no implica práctica ni convicción.

Refs #932 #1158.
