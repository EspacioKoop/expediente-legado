# Evidencia vida cotidiana 1998 — #672 #674 #677

Este gate reúne en un mismo SHA la evidencia visual de tres verticales que ya
comparten recorrido e inventario. No añade contenido al juego ni crea estado de
QA dentro de la partida.

El workflow **Evidencia vida 1998 672 674 677** publica el artifact
`evidencia-vida-1998-<sha>` con cuatro PNG y un `manifest.json`.

| Captura | Revisión humana |
| --- | --- |
| `buzon_portal.png` | El buzón se localiza junto al portal, se reconoce como objeto interactivo y no invade el paso. |
| `publicacion_encontrable.png` | `Manual de Casa — edición 98` se reconoce como publicación física sobre el sofá y tiene una escala razonable para enfocarla. |
| `acumulacion_tres_fuentes.png` | La estantería presenta la acumulación doméstica sin clipping, amontonamiento ilegible ni apariencia de colección puntuable. |
| `calendario_nevera.png` | El objeto recibido por correo se lee como calendario/imán colocado sobre la nevera y no como un plano flotante arbitrario. |

El manifiesto fija además tres objetos presentes realmente en
`Inventario.HOME_STORAGE`, cada uno procedente de un productor distinto:

- `lampara_verde_usada` → `comercio_barrio` (#676);
- `postal_iman_calendario` → `correo_postal` (#672);
- `manual_casa_98` → `publicaciones_encontrables_98` (#674).

Esto permite verificar el criterio de #677 de **tres fuentes reales** sin
fixtures de presentación ni flags paralelos. La captura no simula una colección:
los tres objetos pasan por `Inventario`, y la casa deriva su presentación de
`home_storage`.

## Revisión humana

Registrar **PASS/FAIL** por captura sobre el mismo SHA, indicando un motivo
observable. El workflow comprueba que existen las imágenes, que son distintas y
que el estado usado contiene tres orígenes canónicos; no decide calidad visual.

Además de las imágenes, hacer una pasada breve en el build del mismo SHA:

1. En `trayecto`, enfocar el buzón y abrir/cerrar el lector una vez con teclado
   y otra con mando.
2. Recoger una publicación encontrable y comprobar que no reaparece mientras
   siga en `carried` o `home_storage`.
3. En casa, abrir una publicación guardada, cambiar de pieza, cambiar tamaño de
   texto y cerrar con teclado y con mando.
4. Repetir el recorrido con `reduccion_movimiento`: puede reducir animación,
   pero no debe retirar información, el buzón, la publicación ni los objetos de
   casa.

Un FAIL debe indicar la captura o secuencia concreta y el defecto observado
(escala, clipping, foco, contraste, input, etc.) para que el siguiente corte sea
acotado.

Este gate **no cierra automáticamente** #672, #674 ni #677. Las capturas son
evidencia reproducible; el cierre requiere el pase humano de presentación y
controles que sigue pendiente en esos verticales.
