# HYDRA_LOOP — assets GBC para #439

Primer corte de arte reutilizable para la contraparte de vigilia de la familia onírica **Hidra**.

Este directorio **no implementa todavía la ROM ni activa `semilla_onirica_hidra`**. Solo deja una portada y sus datos gráficos en un formato que RGBDS puede consumir sin depender de assets comerciales.

## Contenido

- `referencia/hydra_loop_title_v1.svg`: portada 160×144 derivada del asset visual generado para el issue.
- `assets/title_tiles.asm`: 251 tiles únicos de 8×8 en formato Game Boy 2bpp.
- `assets/title_tilemap.asm`: mapa visible 20×18.
- `assets/title_palette.inc`: paleta GBC de 4 colores en BGR555.
- `referencia/PROCEDENCIA.md`: trazabilidad del original y de la conversión.

## Integración RGBDS

Con LCD apagada, copia `HydraLoopTitleTiles` a `$8000`, `HydraLoopTitleMap` a las primeras 20 columnas de cada una de las 18 filas del BG map y carga `HydraLoopTitlePalette` como BG palette 0.

El tilemap está deduplicado y usa 251 índices, por lo que cabe en un banco normal de 256 tiles. No requiere VRAM bank 1.

La imagen se redujo primero a 80×72 y se reconstruyó a 160×144 con píxel doble. Esto mantiene legibilidad retro y evita exceder el límite de 256 tiles únicos.

## Alcance

Este corte sirve como base visual para la ROM `HYDRA_LOOP` propuesta en #439: la lógica futura debe conservar la regla determinista de que atacar cabezas/síntomas multiplica el problema y actuar sobre el nodo común detiene la regeneración.

Refs #439 #435 #95 #124.
