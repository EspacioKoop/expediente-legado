# Procedencia — River of the Dragon (龍の川)

- Épica: #808. Id del catálogo: `ryu_flow_98`.
- Autoría: lámina de concept art generada con el modelo de imágenes de OpenAI para EspacioKoop a petición de @eGurucharri, aprobada el 2026-09-17 (título, pantalla de juego, sprites animados, tileset 8×8, HUD y 8 paletas).
- Original: `lamina.png` (SHA-256 `c4a0e1d15dd7a74a0427f9d98f235c8c54b96f958faf196df9e95fed09c4e0d5`).
- Pantalla de título GBC: `gbc/minijuegos/ryu_flow_98/assets/titulo_*.inc`, generada con

  ```
  python scripts/gbc_imagen_a_tiles.py gbc/minijuegos/ryu_flow_98/referencia/lamina.png gbc/minijuegos/ryu_flow_98/assets/titulo --recorte 16,37,449,531 --ancla-y 0.3
  ```

  8 paletas de 4 colores RGB555 asignadas por tile, tiles deduplicados con volteos y repartidos en los dos bancos de VRAM. `gbc/minijuegos/ryu_flow_98/assets/titulo_previa.png` se reconstruye a partir de esos datos.
- Carga en la ROM con `PANTALLA_CGB` y `CargarPantallaCGB` (`gbc/minijuegos/comun/pantalla_cgb.asm`) solo en Game Boy Color; en Game Boy clásica se mantiene el título de texto.
- Pantalla de juego y de victoria: `assets/juego_*` y `assets/victoria_*`, más `assets/sprites_*` (cifras y cursor), generados con `python gbc/minijuegos/ryu_flow_98/generar_arte.py` a partir de los paneles «Gameplay» y «Amanecer». El texto del HUD, sus iconos de torii, las cifras y el cursor se redibujan a mano con fuentes de píxel propias, porque reducidos desde la lámina no se leían.
- Pendiente de convertir: sprites animados del dragón, tileset de juego para más niveles, cuadro de diálogo y el panel de noche (#808).

No se atribuye licencia externa ni procedencia CC0: es arte original generado para este repositorio y se distribuye con su misma licencia. No incorpora logotipos ni personajes de terceros; el texto «Game Boy Color» que aparece en la lámina de Pixel Exodus es parte del marco de presentación y no se usa en la ROM.
