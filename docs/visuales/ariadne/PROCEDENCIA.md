# Procedencia — Ariadne, el hilo del laberinto

- Épica: #808. Id del catálogo: `ariadna_labertinto_98`.
- Autoría: lámina de concept art generada con el modelo de imágenes de OpenAI para EspacioKoop a petición de @eGurucharri, aprobada el 2026-09-17 (título, pantalla de juego, sprites animados, tileset 8×8, HUD y 8 paletas).
- Original: `lamina.png` (SHA-256 `cb405c31b41087d6e7c360cfa273fe52e995acbfaa64b0cb4e375864ebd0293e`).
- Pantalla de título GBC: `docs/visuales/ariadne/titulo_*.inc`, generada con

  ```
  python scripts/gbc_imagen_a_tiles.py docs/visuales/ariadne/lamina.png docs/visuales/ariadne/titulo --recorte 10,37,431,527 --ancla-y 0.25
  ```

  8 paletas de 4 colores RGB555 asignadas por tile, tiles deduplicados con volteos y repartidos en los dos bancos de VRAM. `docs/visuales/ariadne/titulo_previa.png` se reconstruye a partir de esos datos.
- Todavía no hay ROM: los datos quedan preparados para cuando se programe.
- Pendiente de convertir: sprites, tileset de juego, HUD y el resto de pantallas de la lámina (#808).

No se atribuye licencia externa ni procedencia CC0: es arte original generado para este repositorio y se distribuye con su misma licencia. No incorpora logotipos ni personajes de terceros; el texto «Game Boy Color» que aparece en la lámina de Pixel Exodus es parte del marco de presentación y no se usa en la ROM.
