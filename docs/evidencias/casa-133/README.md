# Evidencia visual de casa — #133

Este gate convierte el pendiente visual de #133 en tres capturas reproducibles de la **casa real** (`dia.tscn`), tomadas con la cámara jugable, locale español y HUD oculto. No modifica geometría, materiales, navegación ni gameplay.

La captura transversal de #282 sigue siendo útil como contexto, pero no aísla los criterios propios de #133. Este gate añade:

| Captura | Qué debe poder juzgar una persona |
| --- | --- |
| `entrada_vivienda.png` | Desde la entrada se entiende que el espacio es una vivienda y se distinguen usos domésticos antes de identificar cada prop. |
| `salon_dormitorio.png` | El dormitorio se lee como estancia separada pero conectada, con una transición doméstica clara y recorrido comprensible. |
| `consola_television.png` | Televisor, mueble y consola forman un rincón de ocio reconocible; la consola está visible desde una aproximación jugable del salón. |

`manifest.json` fija resolución, FOV, locale, fase, hashes y el criterio de cada imagen. El runner exige además que existan `CasaHogarCC0`, `HabitacionesCasa`, `TransicionesCasa`, `ConsolaSobremesa98` y `TelevisorCasaInteractuable`, para que una captura parcial no pueda presentarse como evidencia válida.

## Revisión humana

Descarga el artifact `evidencia-casa-133-<sha>` del workflow **Evidencia casa 133** y revisa las tres imágenes del mismo SHA. Registra **PASS/FAIL** por captura con un motivo observable:

- `entrada_vivienda`: PASS/FAIL — ¿se lee como hogar y no como sala genérica?
- `salon_dormitorio`: PASS/FAIL — ¿las estancias y su transición se entienden sin HUD?
- `consola_television`: PASS/FAIL — ¿el rincón de ocio se entiende y la consola parece alcanzable desde esa aproximación?

El workflow comprueba que la escena real se monta, las capturas existen y son distintas, el HUD está oculto y los nodos esenciales de #133 están presentes. **No cierra #133 ni decide si la composición artística es suficiente**: el veredicto sigue siendo humano. Un FAIL debe convertirse en un defecto reproducible sobre una de estas vistas antes de añadir más geometría por intuición.

Refs #133 #282 #398 #635 #685 #1093.

— Odiseo (GPT-5.6 Sol)
