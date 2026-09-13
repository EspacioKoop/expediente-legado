# SIGA-98 · Alpha post-playtest · 2026-09-13

Esta build es el segundo corte de playtesting humano posterior a la alpha generada por #270.

**Baseline de gameplay:** `main` tras #393 (`0216c7a5de49b24313f6d0c59dfbb1627744c057`).

No es una release comercial ni declara cerrados los issues de validación humana. Su objetivo es repetir el recorrido completo con los cambios integrados después del primer playthrough de #9 y convertir cualquier fallo observado en un issue concreto.

## Qué cambió desde la alpha anterior

### Inicio, controles y orientación

- **Continuar / Nueva partida** ya separan el flujo y protegen una partida existente (#271 / #288).
- El inicio de oficina hace más legible el **puesto 4-B y la primera acción** (#272 / #304).
- Movimiento estándar **WASD + flechas** y pisadas atenuadas (#273 / #305).
- Menú global, pausa, preferencias y **remapeo visual de teclado y mando** (#113 / #306 / #335).
- El menú incluye un **Parte de incidencias** para testers, con diagnóstico técnico opt-in y fallback a portapapeles/archivo local (#381 / #392).

### Expedientes SIGA e investigación

- Se pueden **relacionar manualmente dos folios** ya leídos; el juego no resuelve la relación por el jugador (#286 / #289).
- Marcadores personales, metadatos y feedback de relaciones dan más capas al expediente (#309 / #318 / #320).
- Primeros **anexos examinables** y validación de sus referencias/procedencia (#321 / #323 / #371).
- La auditoría legado → Godot quedó versionada para no perder por omisión mecánicas del SIGA histórico (#352).
- El careo puede reflejar contexto realmente descubierto durante la investigación (#367).
- Primer vertical de **archivado manual 3D**: coger una carpeta y colocarla en su archivador correcto (#157 / #364).

### Interacción 3D y espacios

- Contrato común de interacción contextual en primera persona, con acción semántica remapeable (#283 / #307 / #341).
- El terminal SIGA se usa mirando e interactuando; los archivadores reales se pueden abrir/cerrar (#345 / #348).
- La casa recibió utilería reconocible y objetos interactivos: lámpara y televisor encendibles/apagables (#353 / #373 / #393).
- El **corcho físico de conceptos** aparece en casa y permite crear/quitar enlaces manuales entre conceptos conocidos (#101 / #368).
- El trayecto funciona como exterior real, con escaparate de televisores y el hook corregido a la fase `trayecto` (#277 / #314 / #331 / #337).
- Compañeros con rostros low-poly integrados, diálogo diegético y asistente-gato abajo a la derecha (#275 / #276 / #285; #310 / #315 / #317 / #338).
- Clima diario determinista visible en exteriores (#143 / #324).
- Primer ambiente continuo de oficina conectado al cambio real de fase (#119 / #349 / #372).

### Sueño y continuidad

- La primera noche progresa por **objetivos oníricos**, no por encontrar una salida física oculta (#281 / #301).
- Feedback de progreso 0/2 → 2/2, reorientación del gato y corrección del detector físico (#308 / #313).
- La recompensa onírica se limita a pistas ya catalogadas; el sueño no inventa hechos (#89 / #332).
- Infraestructura para geometría onírica poligonal/no ortogonal y familias reutilizables; sigue siendo un área a validar visualmente, no un cierre de #279 (#325 / #344).
- Se corrigió el salto accidental de cinemáticas y se amplió la variación de casa → sueño (#280 / #292 / #311). La reproducción real de transiciones en export sigue siendo un gate humano de esta alpha.

### Vida cotidiana y decisiones

- La pérdida de vivienda descarta almacenamiento doméstico sin borrar lo que el personaje lleva encima (#84 / #333).
- Hay un primer vertical de trabajillos nocturnos; sigue pendiente validar equilibrio y coste real sobre descanso/vida doméstica (#94 / #322).
- La decisión política puede **posponerse** y la UI ofrece explícitamente «Decidir más tarde» (#287 / #339 / #369).
- Sellos internos/persistentes permiten registrar hitos como una noche improductiva sin dar dinero, pistas ni acciones (#148 / #363 / #365).

### Portátil y minijuegos opcionales

Estas piezas están integradas, pero **no forman parte del recorrido crítico de la alpha**:

- Portátil Color 98 física en casa y carpeta `user://roms` para ROMs aportadas por el jugador (#124 / #385).
- Núcleo GB real integrado mediante GDExtension, selector de ROM y smoke de export; Peanut-GB es DMG, por lo que ROMs CGB-only no son compatibles (#124 / #387 / #391).
- ROMs propias del proyecto: **Caza Píxeles 98**, **Paper Planes 98** (Nueva York 1998) y **Croc Riders 98** (El Cairo/Giza) (#384 / #386 / #388 / #389).
- No se distribuyen ROMs externas. El usuario es responsable de tener derecho a cualquier ROM añadida manualmente.

## Recorrido de prueba recomendado

1. Empezar con **Nueva partida** y comprobar que se entiende el archivo, el puesto 4-B y la primera acción sin consola ni instrucciones externas.
2. Abrir SIGA, leer varios folios, marcar alguno, examinar metadatos/anexos y crear al menos una relación manual.
3. Llegar a firma/careo y comprobar que el contexto descubierto se refleja sin resolver automáticamente el expediente.
4. Salir al trayecto: comprobar transición, lectura de calle/exterior, clima y escaparate.
5. Llegar a casa: probar lámpara, televisor, corcho y, opcionalmente, la portátil.
6. Dormir y completar la primera escena onírica por objetivos; no buscar una salida invisible.
7. Despertar, recorrer alquiler/pago o impago cuando corresponda y verificar consecuencias domésticas.
8. Cerrar el juego y **Continuar** desde varios puntos para comprobar persistencia real.
9. Abrir el menú y probar remapeo; si hay mando físico, recorrer tanto UI como 3D con él.
10. Usar **Parte de incidencias** si aparece un fallo, indicando pasos concretos para reproducirlo.

## Gates humanos que esta alpha debe resolver

- #271 — Continuar / Cancelar / Nueva partida y persistencia real tras cerrar/reabrir.
- #272 — reconocer el archivo, el puesto 4-B y la primera acción sin contexto previo.
- #273 — tacto de controles y volumen de pisadas.
- #280 — cinemáticas/transiciones realmente visibles en el export.
- #281 — primera noche comprensible y completable por objetivos.
- #113 — mando físico, conflictos de remapeo y presentación de nombres/iconos.
- #286 — comprobar si SIGA deja de sentirse como lectura → decisión inmediata.
- #277/#275/#276/#285 — validación visual del trayecto, rostros, diálogos y asistente.
- #119 — escuchar si el ambiente de oficina funciona en contexto y no domina la mezcla.

## Límites conocidos

- CI/Alpha automáticas validan importación, pruebas, lint, smoke y export; **no equivalen** a un playthrough humano, validación visual ni mando físico.
- Lámpara y televisor usan estado local de escena: al reentrar en casa vuelven a su estado inicial.
- #279/#282/#283 son paraguas todavía abiertos; hay infraestructura y verticales concretos, no cobertura total de sueño/densidad/interacción.
- La URL externa del Parte de incidencias queda vacía si el empaquetado no define `SIGA98_FEEDBACK_URL`; el texto sigue pudiéndose copiar/guardar localmente.
- La emulación incluida es DMG; no promete compatibilidad con ROMs CGB-only.

## Qué reportar

Priorizar bloqueos del recorrido, pérdida de estado, cinemáticas ausentes, controles que no permitan continuar, objetivos oníricos incomprensibles, elementos interactivos que parezcan rotos y problemas graves de legibilidad/audio. Las expansiones opcionales no deben desplazar un fallo reproducible del recorrido principal.

Refs #9 #181 #270.

— Odiseo (GPT-5.6 Sol)
