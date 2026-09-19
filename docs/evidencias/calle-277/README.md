# Evidencia visual de calle — #277

Este gate convierte el pendiente visual de #277 en tres capturas reproducibles del **trayecto real** (`dia.tscn`), tomadas con la cámara jugable, locale español y HUD oculto. No cambia geometría, materiales, navegación ni gameplay.

La captura general que ya genera #282 sirve como contexto transversal, pero no aísla los tres criterios propios de #277. Este gate añade:

| Captura | Qué debe poder juzgar una persona |
| --- | --- |
| `spawn_exterior.png` | Desde el spawn, el espacio se reconoce como calle/exterior por cielo, calzada, aceras, fachadas y profundidad, sin leer HUD. |
| `escaparate_crt.png` | Las CRT se entienden como aparatos dentro de un escaparate de electrodomésticos, no como pantallas arbitrarias pegadas a un pasillo. |
| `portal_casa.png` | El portal 7 y el bloque de viviendas se leen como destino doméstico al final del recorrido. |

`manifest.json` fija resolución, FOV, locale, fase, hashes y el criterio asociado a cada imagen. El runner también rechaza rótulos de `CalleIdentidad` que sigan mostrando una clave cruda `CALLE_*`, porque una evidencia con señalética sin traducir no sirve para valorar legibilidad.

## Revisión humana

Descarga el artifact `evidencia-calle-277-<sha>` del workflow **Evidencia calle 277** y revisa las tres imágenes del mismo SHA. Registra **PASS/FAIL** por captura con una frase concreta:

- `spawn_exterior`: PASS/FAIL — motivo visual observable.
- `escaparate_crt`: PASS/FAIL — motivo visual observable.
- `portal_casa`: PASS/FAIL — motivo visual observable.

El workflow comprueba que la escena real se monta, las capturas existen y son distintas, el HUD está oculto y la señalética de la capa de calle no queda en claves crudas. **No cierra #277 ni decide si la composición artística es suficiente**: ese veredicto sigue siendo humano. Un FAIL debe convertirse en un fallo reproducible sobre una de estas vistas antes de añadir más geometría por intuición.

Refs #277 #398 #282 #1066.

— Odiseo (GPT-5.6 Sol)
