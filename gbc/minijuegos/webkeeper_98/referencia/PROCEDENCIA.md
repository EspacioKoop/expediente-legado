# Procedencia — Kwaku, el guardameta

- Épica: #808. Id del catálogo: `webkeeper_98`.
- Autoría: lámina de concept art generada con el modelo de imágenes de OpenAI para EspacioKoop a petición de @eGurucharri, aprobada el 2026-09-17 (título, pantalla de juego, sprites animados, tileset 8×8, HUD y 8 paletas).
- Original: `lamina.png` (SHA-256 `1cc57e52d13790fcbf652fd894cb09138235992ed1a3a887713cae4a1eca078a`).
- Pantalla de título GBC: `gbc/minijuegos/webkeeper_98/assets/titulo_*.inc`, generada con

  ```
  python scripts/gbc_imagen_a_tiles.py gbc/minijuegos/webkeeper_98/referencia/lamina.png gbc/minijuegos/webkeeper_98/assets/titulo --recorte 4,4,394,561 --ancla-y 0.0
  ```

  8 paletas de 4 colores RGB555 asignadas por tile, tiles deduplicados con volteos y repartidos en los dos bancos de VRAM. `gbc/minijuegos/webkeeper_98/assets/titulo_previa.png` se reconstruye a partir de esos datos.
- Carga en la ROM con `PANTALLA_CGB` y `CargarPantallaCGB` (`gbc/minijuegos/comun/pantalla_cgb.asm`) solo en Game Boy Color; en Game Boy clásica se mantiene el título de texto.
- Pendiente de convertir: sprites, tileset de juego, HUD y el resto de pantallas de la lámina (#808).

No se atribuye licencia externa ni procedencia CC0: es arte original generado para este repositorio y se distribuye con su misma licencia. No incorpora logotipos ni personajes de terceros; el texto «Game Boy Color» que aparece en la lámina de Pixel Exodus es parte del marco de presentación y no se usa en la ROM.
