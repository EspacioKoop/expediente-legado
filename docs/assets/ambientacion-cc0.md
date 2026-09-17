# Ambientación CC0 — estado de integración SIGA-98

Seguimiento principal: #216.

Última comprobación del estado: **2026-09-17**.

Este documento es la fuente de verdad **versionada** del catálogo de ambientación CC0. El issue #216 conserva decisiones, discusión y descubrimiento; aquí se registra qué está realmente integrado, qué está solo documentado y qué falta para considerar cerrada la épica.

## Regla de integración

Un pack no cuenta como integrado por estar enlazado o investigado. Para pasar a `integrado` debe existir un corte pequeño y reproducible en una escena real, con:

- fuente y licencia verificables;
- procedencia por fichero o por geometría derivada, con hash cuando corresponda;
- adaptación visual SIGA-98;
- ninguna dependencia del pack completo;
- sin logos/señalética dudosa;
- física, IA e interacción solo si forman parte explícita del diseño;
- coste acotado o medido;
- binarios bajo LFS cuando corresponda.

Los elementos de fondo deben seguir siendo secundarios: niebla, distancia, paleta, escala, sombras y silueta se usan para que den profundidad sin competir con objetivos interactivos.

## Estado comprobado

| Familia | Issue | Estado | Evidencia / siguiente paso |
| --- | ---: | --- | --- |
| Modular Train Pack | #217 | **integrado** | PR #236: vagón + vía originales de Quaternius, procedencia/SHA-256 y montaje lejano sin colisión/IA/interacción. |
| Godot Skies | #224 | **integrado** | PR #235: shader CC0 adaptado, preset propio y montaje real en la escena diaria. |
| Retro Urban Kit | #295 | **parcial avanzado** | PRs #402, #415 y #603: toldo, banco, farola y barrera como geometría adaptada; 8 instancias en el trayecto. Sigue pendiente la validación visual humana/captura específica que cierre #295. |
| Ultimate Nature Pack | #229 | **integrado / cerrado** | PR #418: 4 OBJ/MTL originales, procedencia/SHA-256, shader PSX y 8 instancias de periferia. |
| Retro PSX Street Furniture | #222 | **pendiente / opcional** | Ya no es requisito automático para #216: usar solo si una captura/playtest detecta un hueco concreto que #295/#225 no cubren. |
| Traffic Road Assets | #225 | **integrado, pendiente aceptación visual** | PR #507: conos, barrera y tapas CC0 con GLB/atlas en LFS, procedencia, captura y coste medido. |
| PSX Style Cars | #230 | **integrado, pendiente aceptación visual** | PR #526: 3 coches GLB CC0, procedencia/SHA-256/LFS, colisión simple, capturas y presupuesto de triángulos. |
| Ultimate Buildings Pack | #218 | **integrado** | PR #693: 4 edificios reales OBJ/MTL, procedencia/SHA-256, shader PSX y 4 instancias lejanas medidas. |
| Stylized Tree Pack | #219 | **integrado** | PR #704: 3 modelos, 6 instancias, procedencia/SHA-256, shader PSX y captura desde cámara del jugador. |
| Chill Vibes Art Jam 4 | #220 | **pendiente / opcional** | Solo integrar si una escena de servicio/almacén necesita props que no cubran #228 u otros assets ya presentes. |
| Downtown City MegaKit | #221 | **pendiente / despriorizado** | La calle ya tiene skyline, edificios reales, coches, naturaleza, tren y mobiliario. No importar el megakit salvo hueco visual demostrado. |
| School Classrooms Asset Pack | #223 | **documentado** | PR #484 fija selección, licencia, época, LFS y procedencia. No importar si #294 cubre la oficina; reservar piezas escolares para una necesidad real. |
| Office low poly pack | #226 | **suplido por #294** | La necesidad de oficina queda cubierta por PR #499 con 9 GLB del PSX Style Office Pack, procedencia/SHA-256, LFS y captura. |
| Low poly household goods | #227 | **integrado** | PR #532: 13 GLB CC0 en casa, procedencia/SHA-256/LFS, shader PSX, colisiones simples y capturas antes/después. |
| Free Industrial 3D Models | #228 | **parcial integrado** | PR #430: 4 referencias reconstruidas como geometría low-poly, shader PSX y zona de servicio real; falta validación visual humana si se quiere cerrar el sub-issue. |
| Horror Texture Pack | #231 | **infraestructura preparada** | PR #479 añade `DecalCompat`; todavía no se ha importado una textura concreta del pack porque faltaba un binario verificable con hash. |

## Fuentes posteriores que ya forman parte de la estrategia

#216 ha crecido más allá de la lista original. Los siguientes issues son alternativas o extensiones preferentes cuando resuelven mejor un hueco real:

- #294 — PSX Style Office Pack: **integrado** mediante PR #499; es la familia principal de oficina.
- #295 — Retro Urban Kit: integración urbana principal de bajo coste; falta validación visual final del corte.
- #296 — PSX Going Medieval / Fantasy Props: soporte del castillo onírico de #284; no es requisito de cierre de #216.
- #297 — Kenney UI Audio: extensión sonora CC0, cerrada; comparte política de procedencia pero no cuenta como ambientación 3D.
- #298 — Kubasta: fuente CC0 para terminales; complemento tipográfico, no sustituto del criterio visual 3D.

## Orden de ejecución actualizado

No completar porcentajes del catálogo por inercia. El orden útil a partir del estado actual es:

1. **validación visual de calle**: revisar una captura/playtest con tren, skyline/edificios, árboles/naturaleza, Retro Urban, Traffic Road y coches simultáneos;
2. **cerrar o acotar sub-issues ya implementados** (#225, #228, #230, #295) según esa validación humana;
3. **oficina y casa**: no importar más familias salvo hueco concreto; #499 y #532 ya cubren el gate funcional de #216;
4. **materiales/desgaste**: #231 solo si mejora una superficie real bajo las reglas de #399;
5. **packs aún pendientes** (#220/#221/#222/#223/#226): tratarlos como opciones, no como checklist obligatoria.

Esto evita convertir #216 en una colección de packs sin uso jugable.

## Presupuesto y benchmark conjunto

El criterio de rendimiento combinado ya dispone de infraestructura reproducible mediante #493 / PR #524:

- baseline y ambientación CC0 completa se ejecutan con la misma cámara/configuración;
- se registran draw calls, objetos, primitivas, tiempo de proceso y memoria estática;
- se generan capturas sin HUD para ambos modos;
- el workflow corre en PRs relevantes, manualmente y de forma periódica.

El benchmark no debe interpretarse como validación estética ni sustituye una pasada humana de la calle.

## Gate de cierre de #216

Estado actual del gate:

- [x] existe al menos una integración real de fondo con geometría externa y procedencia: #217/#236;
- [x] existe un cielo/preset CC0 adaptado y montado: #224/#235;
- [x] existe una integración urbana PSX real y suficientemente variada como para evaluarla: #295/#402/#415/#603, #225/#507, #230/#526, #218/#693;
- [x] oficina y casa tienen al menos una familia CC0 realmente integrada: #294/#499 y #227/#532;
- [x] existe benchmark combinado reproducible: #493/#524;
- [x] existen capturas comparables de integraciones reales: benchmark combinado, casa antes/después y capturas específicas de tráfico/coches/arbolado;
- [x] las integraciones usadas como evidencia registran procedencia/hash y respetan LFS cuando corresponde;
- [x] los sub-issues cerrados usados como evidencia tienen PR de entrega enlazable (#217/#236, #224/#235, #229/#418);
- [ ] validar visualmente en alpha que la calle, con las familias combinadas, es suficientemente densa y coherente sin parecer una suma de packs;
- [ ] tras esa validación, cerrar/acotar los sub-issues que sigan abiertos por aceptación humana y decidir si #216 puede cerrarse como épica.

A día de hoy, el cierre de #216 no necesita otra importación por defecto: necesita **validación visual del conjunto y limpieza de seguimiento**.

## Qué no hacer

- importar un pack completo para “tenerlo disponible”;
- añadir un asset porque sea más detallado si no mejora lectura, tono o profundidad;
- usar una escena demo de terceros como composición final;
- convertir señalética, logos o props contemporáneos en foco visual sin revisión;
- mezclar una nueva fuente con cambios de gameplay no relacionados;
- cerrar #216 solo porque el catálogo tenga muchas fuentes: el criterio es **integración útil, medida y validada visualmente**.

— Odiseo (GPT-5.6 Sol)
