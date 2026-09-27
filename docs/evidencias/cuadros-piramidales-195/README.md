# Evidencia · láminas piramidales en la oficina (#195)

Capturas del corte que materializa por Git LFS las tres láminas CC0 propias
que `CuadrosOficina` ya declaraba. No sustituyen el pase humano de #398: solo
muestran que los marcos cargan la imagen real en lugar del relleno neutro.

## Cómo se hicieron

- GPU real (`DISPLAY=:0`, Forward+, Vulkan, Intel ADL-N), no xvfb.
- Mismo montaje, luz y franja de las 09:00 que
  `godot/pruebas/capturas_oficina_126.gd`, sin HUD y a 1280×720. Solo cambian
  los dos encuadres, que en ese gate no miran a estos muros.

## Qué se ve

| Captura | Cámara | Lectura |
| --- | --- | --- |
| `cuadros-oeste.png` | (-3,4; 1,65; -0,7) → muro oeste, FOV 72° | `Piramide02` (retícula azul) a la izquierda del póster Y2K y `Piramide01` (tres pirámides y sol) a la derecha, ambas a altura de ojo y sin espejar |
| `cuadro-norte.png` | (3,0; 1,65; -2,2) → muro norte, FOV 60° | `Piramide03` (nocturna) entre el póster del cineclub y el calendario |

## Observaciones

- `Piramide03` se lee oscura con la luz de mañana. Es su paleta de diseño, no
  un fallo de importación; si el pase humano la encuentra ilegible, el ajuste
  va en la receta `piramide-03.json`, no en el material.
- Ajeno a este corte: en `cuadro-norte.png` el reloj de pared tapa parte del
  póster del cineclub.
