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
- Niveles 1-2 y 1-3: `assets/juego_paletas_amanecer.inc` y `assets/juego_paletas_noche.inc` llevan a la escena el color de los paneles «Amanecer» y «Noche · lluvia» (transferencia de media y desviación por canal); `assets/juego_agua.inc`, los brillos del agua. El cuadro de diálogo usa el retrato del anciano del panel «HUD / Interfaz», reducido a 32×32.
- Dragón animado: `dragon_sprites.png` (SHA-256 `650aad5974f2bc254ac53db87c38ff5eb8c1a230260bc04735a2f936e020df3a`), hoja de sprites generada con el modelo de imágenes de OpenAI a petición de @eGurucharri el 2026-09-17, pedida ya a resolución nativa de Game Boy Color con una paleta de tres colores sobre magenta (cabeza en reposo y despertando, cuerpo, cola y rugido). `generar_arte.py` ajusta cada píxel a esa paleta, reduce por moda la cabeza a 32×24 y el rugido a 48×40, deduplica tiles y exporta `assets/dragon_*`. Se usan cuatro fotogramas de reposo, el ojo cerrado y abierto del despertar y los dos del rugido; el cuerpo, la cola y el despertar intermedio quedan sin usar por espacio en VRAM.
- Los sprites de dragón de `lamina.png` no se usan: pintados a unos 90 px, a tamaño GBC quedaban ilegibles.

No se atribuye licencia externa ni procedencia CC0: es arte original generado para este repositorio y se distribuye con su misma licencia. No incorpora logotipos ni personajes de terceros; el texto «Game Boy Color» que aparece en la lámina de Pixel Exodus es parte del marco de presentación y no se usa en la ROM.
