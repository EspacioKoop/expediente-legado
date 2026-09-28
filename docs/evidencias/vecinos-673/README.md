# Evidencia visual · vecinos y portal (#673)

Este gate genera evidencia reproducible del portal real para la **revisión humana** pendiente de #673. No sustituye el recorrido con teclado/mando ni autoaprueba el cierre del issue.

## Artifact

El workflow **Evidencia vecinos 673** ejecuta `dia.tscn` con la cámara jugable, oculta el HUD y genera:

- `manuela.png`: jornada 7, con Manuela, tablón y felpudo en el mismo encuadre;
- `repartidor.png`: jornada 8, con repartidor, paquete equivocado y tablón;
- `manifest.json`: jornada, presencias activas, distancia a cámara, proyección de los objetivos y SHA-256 de cada captura.

Las jornadas son deliberadamente fijas para que una revisión posterior compare el mismo estado del portal. El workflow falla si un objetivo esperado desaparece o queda fuera del frustum, pero esa comprobación solo evita artifacts vacíos: **no autoaprueba** escala, composición ni legibilidad.

## Qué revisar

Sobre `manuela.png`:

- la figura se reconoce como presencia humana secundaria sin dominar la calle;
- tablón y felpudo siguen siendo legibles como elementos distintos;
- la escala no invade puerta, recorrido ni señalética del portal.

Sobre `repartidor.png`:

- repartidor y paquete se distinguen desde cámara jugable;
- el paquete se percibe recogible sin parecer un objetivo principal obligatorio;
- la composición deja libre el acceso y no tapa elementos de #277.

Después del artifact sigue siendo obligatorio el pase en movimiento con teclado y **mando físico**, incluida la recogida del paquete y la comprobación de `reduccion_movimiento`.

## Pass/fail humano

**Pasa** si ambos encuadres se leen como vida ambiental del edificio, las proporciones son plausibles y ningún elemento compite con navegación o señalética.

**Falla** si una figura parece un proxy desproporcionado, el paquete no se identifica, se tapa el recorrido o el portal se vuelve visualmente confuso. En ese caso el siguiente PR debe corregir el defecto observado, no ampliar el roster.

Refs #277 #398 #669 #672 #673.
