# Ventana de casa — matte urbano fotorealista 1998

Este corte mejora el diorama que se ve desde el dormitorio del protagonista sin
crear un segundo sistema de exterior.

## Qué cambia

`VentanaExterior3D` conserva su único `SubViewport`, la cámara 3D, la calle,
los coches, árboles, farolas, nubes, niebla, lluvia y nieve. La línea principal
de bloques construidos con cajas —que dominaba la vista y hacía que el exterior
se leyera como una maqueta provisional— se sustituye por un matte urbano propio.

El matte muestra una segunda línea densa de viviendas de finales de los 90:
azoteas, balcones, antenas, toldos, bloques envejecidos y profundidad urbana. Se
coloca detrás de la calle procedural, de modo que los elementos volumétricos
siguen pasando por delante y el clima continúa teniendo profundidad real.

## Asset

- `godot/assets/texturas/ventana_casa_ai_98/fondo_barrio_98.webp`
- 384 × 216 px
- menos de 10 KiB
- filtrado nearest dentro del viewport 320 × 180
- sin personas, rótulos ni marcas en el recorte distribuido

La imagen matriz fue generada específicamente para el proyecto con OpenAI
ImageGen. El fichero final es un recorte del exterior urbano de esa generación,
redimensionado y comprimido para el uso de segunda línea. La ficha y el SHA-256
exacto están en `godot/assets/procedencia.json`.

## Clima

El matte no sustituye la lógica climática. `Clima.estado(dia)` sigue siendo la
fuente de verdad. Cada estado aplica un tinte distinto al fondo y conserva las
capas existentes:

- despejado: luz cálida de final de jornada;
- nublado: desaturación fría;
- lluvia: fondo más oscuro/frío + precipitación 3D;
- niebla: lavado de contraste + bancos volumétricos existentes;
- nieve: tinte frío + partículas y suelo nevado.

La reducción de movimiento sigue congelando únicamente la deriva ambiental que
ya controlaba `VentanaExterior3D`; el nuevo fondo es estático.

## Alcance

No cambia la posición de `VentanaCasa`, el controlador de jornada, gameplay,
colisiones, navegación ni persistencia. Tampoco sustituye el marco 3D de la
habitación: el matte vive detrás de él, dentro del mismo pipeline que ya usa la
ventana y el diorama del menú.
