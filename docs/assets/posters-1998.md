# Pósteres de oficina de 1998

Seis imágenes generadas con IA, proporcionadas por el usuario y autorizadas
expresamente para integrarse en SIGA-98 en el encargo [#443](https://github.com/EspacioKoop/expediente-legado/issues/443).
La herramienta, el modelo y la fecha de generación no se han especificado.
No se atribuye autoría humana, dominio público ni licencia CC0. La autorización
de uso en este juego no equivale a conceder una licencia abierta independiente.

El texto forma parte de los diseños suministrados: se conserva literalmente,
sin conectarlo a pistas, expedientes, calendario ni acciones del juego.
Las texturas contienen español y no cambian con el idioma de la interfaz.

## Recortes reproducibles

Fuente: `posters-1998.png`, 1024 × 1536 píxeles, SHA-256:

`5f5a6f91ddf8d37cd636352823183612b3fe86a7ffd27cabe4530ec6634046ed`

Coordenadas Pillow `(izquierda, arriba, derecha, abajo)`, extremo derecho e
inferior exclusivos. Solo se recortan separaciones y bordes externos de la
lámina; no se redibuja, reescala ni recompone el contenido. Los márgenes impresos
propios de cada diseño se conservan. La lámina original no se distribuye.

| Textura | Diseño | Recorte | Resolución |
| --- | --- | --- | --- |
| poster-1998-01.png | La información es de todos | (2, 2, 335, 743) | 333 × 741 |
| poster-1998-02.png | El futuro ya está en su mesa | (348, 2, 678, 743) | 330 × 741 |
| poster-1998-03.png | Asamblea de personal | (691, 2, 1022, 743) | 331 × 741 |
| poster-1998-04.png | Tómese cinco minutos | (2, 756, 335, 1524) | 333 × 768 |
| poster-1998-05.png | Cineclub del viernes | (348, 756, 678, 1524) | 330 × 768 |
| poster-1998-06.png | ¿Está preparado su equipo? | (691, 756, 1022, 1524) | 331 × 768 |

Cada recorte se obtiene con `Image.open(origen).crop(caja).save(destino)` de
Pillow. Los PNG originales recortados se versionan con Git LFS; el registro
`godot/assets/procedencia.json` incluye hash de cada textura y del origen.

## Montaje

`PostersOficina` añade seis planos con UV completas, proporción de la textura,
material mate iluminado y mipmaps. Se separan de las caras interiores del muro
para evitar parpadeo por coplanaridad y no añaden colisiones ni interacción.
El controlador de utilería los monta solo en `archivo`, una vez por mundo.

- Información y cursos: pared norte, junto a los puestos.
- Asamblea y cineclub: pared norte, a la derecha del tablón existente.
- Descanso: pared sur, encima del rincón de café y fuera de las ventanas.
- Año 2000: pared oeste, junto a los puestos y lejos de la salida.

Las alturas y anchuras se verifican en la prueba Godot; no se modifica la
geometría de la oficina ni sus recorridos.

## Verificación

Godot 4.7.2: importación, 662 comprobaciones de suite, 145 de recorrido y
arranque correctos. La regresión nueva ejecuta la escena diaria real con datos
temporales: 61 comprobaciones de montaje, seis texturas distintas, proporción,
mipmaps, orientación hacia dentro, techo, idempotencia y filtro de fase.
Python: 451 pruebas; Java: 47; frontend: 28. Checkstyle, PMD y SpotBugs correctos.
Lint/formato pasan con la exclusión de dependencias de `ci.yml`; los comandos
sobre el árbol entero señalan únicamente guiones de terceros en `.deps`.
No hay cobertura instrumentada de GDScript configurada.

Se han inspeccionado renders de la escena real con Godot 4.7.2, cámara colocada
para la revisión y HUD oculto, sin usar partidas personales:

![Pared de avisos](../capturas/posters-oficina-avisos.png)
![Rincón de café y pared oeste](../capturas/posters-oficina-cafe.png)

Esto verifica colocación y visibilidad; no constituye un playthrough humano,
prueba con mando físico ni validación de una exportación final. Las figuras y
rótulos preexistentes de compañeros no forman parte de este cambio.
