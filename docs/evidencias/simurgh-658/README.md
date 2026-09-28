# Evidencia de equivalencias de escala · Simurgh (#658)

Este gate convierte el último criterio visual de #658 en una comparación reproducible. Genera **seis capturas sin HUD**: cada una de las tres equivalencias aparece una vez en la capa de escritorio y otra en la capa monumental.

- `pluma_escritorio.png` ↔ `pluma_monumental.png`: pluma → pasarela.
- `archivos_escritorio.png` ↔ `archivos_monumental.png`: archivadores → cordillera.
- `lampara_escritorio.png` ↔ `lampara_monumental.png`: lámpara → nido.

El runtime marca ambos miembros de cada pareja con el mismo metadato `ancla_equivalencia`. El workflow comprueba que cada ancla existe en ambas capas, queda dentro del frustum y produce imágenes distintas. Eso evita que una refactorización conserve los nombres pero rompa la correspondencia semántica.

La evidencia **no autoaprueba** el criterio. La revisión humana debe decidir si una persona puede reconocer la relación entre escalas sin HUD, texto explicativo ni conocimiento del código.

## Qué revisar

- la silueta/color/posición relativa de la pluma siguen siendo reconocibles al convertirse en pasarela;
- la agrupación de archivadores conserva suficiente patrón al pasar a cordillera;
- la lámpara y el nido comparten una lectura espacial clara, no solo un color;
- ninguna pareja necesita flechas, etiquetas o cámara forzada para entenderse;
- con `reduccion_movimiento`, el corte entre capas mantiene la misma relación perceptiva.

Si una pareja falla, el siguiente cambio debe corregir esa equivalencia concreta antes de añadir otra capa o más decoración.

Refs #442 #650 #658 #1311.
