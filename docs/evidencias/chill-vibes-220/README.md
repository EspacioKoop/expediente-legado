# Evidencia · palé y caja de Chill Vibes en la zona de servicio (#220)

Capturas del corte que activa por Git LFS `shipping_pallet.glb` y `crate.glb`.
Con ambos presentes, `IndustrialCC0` sustituye el trolley procedural de #228
por el lote de Chill Vibes. No sustituyen el pase humano de #398 sobre la calle.

## Cómo se hicieron

- GPU real (`DISPLAY=:0`, Forward+, Vulkan, Intel ADL-N), no xvfb.
- Mismo arranque que `godot/pruebas/capturar_calle_277.gd`: `dia.tscn` real,
  fase `trayecto`, cámara jugable y sin HUD. Solo cambian las posiciones de
  cámara. El viewport salió a 1797×1011 por el escalado del escritorio, no a
  1280×720.

## Qué se ve

| Captura | Jugador | Lectura |
| --- | --- | --- |
| `con-glb-frontal.png` | (2,2; 0; -0,4) mirando al hueco de servicio | bobina, cuadro eléctrico y caja apilada sobre el palé a la derecha |
| `con-glb-acera.png` | (3,2; 0; 1,8) desde la acera | se distinguen las tablas del palé bajo la caja; sin interpenetración |

## Límites

- Antes del arreglo de este corte la caja atravesaba el palé, que casi no se
  veía. Esa versión no se conserva como evidencia: era un defecto, no un estado
  de referencia.
- Ajeno a este corte: al fondo, sobre la calzada, aparecen planos negros que ya
  estaban antes de activar los GLB.
