# Ambientación CC0 — estado de integración SIGA-98

Seguimiento principal: #216.

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
| Modular Train Pack | #217 | **integrado** | PR #236: vagón + vía originales de Quaternius, procedencia/SHA-256, montaje lejano sin colisión/IA/interacción. |
| Godot Skies | #224 | **integrado** | PR #235: shader CC0 adaptado, preset propio y montaje real en la escena diaria. |
| Retro Urban Kit | #295 | **parcial** | PRs #402 y #415: una pieza fuente (`detail-awning-small.glb`) convertida a geometría del proyecto y reutilizada en dos toldos. Falta llegar a 6–10 piezas y captura/medición conjunta. |
| Ultimate Nature Pack | #229 | **cerrado** | El issue está marcado `completed`; antes de reutilizarlo como evidencia de #216 hay que enlazar el PR/commit de entrega si existe. |
| Retro PSX Street Furniture | #222 | **pendiente** | Candidato prioritario para completar la calle con piezas pequeñas de bajo coste. |
| Traffic Road Assets | #225 | **pendiente** | Existe ficha técnica en `docs/assets/traffic-road-assets.md`; no equivale por sí sola a integración. |
| PSX Style Cars | #230 | **pendiente** | Existe ficha técnica en `docs/assets/psx-style-cars.md`; integrar solo coches útiles para fondo/aparcamiento/tráfico simple. |
| Ultimate Buildings Pack | #218 | **pendiente** | Reservar para skyline/fachadas lejanas si #295 no cubre la profundidad necesaria. |
| Stylized Tree Pack | #219 | **pendiente** | Vegetación de fondo; evitar aspecto excesivamente cartoon. |
| Chill Vibes Art Jam 4 | #220 | **pendiente** | Props de servicio/almacén como dressing secundario. |
| Downtown City MegaKit | #221 | **pendiente** | Solo si sigue faltando masa urbana después de #295/#218; evitar importar el kit entero. |
| School Classrooms Asset Pack | #223 | **pendiente** | Existe ficha técnica en `docs/assets/school-classrooms-styloo.md`; usar para completar huecos concretos, no como escena completa. |
| Office low poly pack | #226 | **pendiente** | Complementario a #294; no duplicar piezas si el pack PSX de oficina ya cubre el hueco. |
| Low poly household goods | #227 | **pendiente / bloqueado por binarios verificables** | La casa necesita selección pequeña con ZIP/ficheros verificables y hashes antes de abrir integración real. |
| Free Industrial 3D Models | #228 | **pendiente** | Útil para mantenimiento, sótanos y zonas de servicio cuando exista una escena que lo necesite. |
| Horror Texture Pack | #231 | **pendiente** | Debe entrar subordinado a #399 como desgaste/material, no como estética de terror dominante. |

## Fuentes posteriores que ya forman parte de la estrategia

#216 ha crecido más allá de la lista original. Los siguientes issues son alternativas o extensiones preferentes cuando resuelven mejor un hueco real:

- #294 — PSX Style Office Pack: pack principal propuesto para oficina antes de #223/#226.
- #295 — Retro Urban Kit: pack principal actual para calle/fondos urbanos.
- #296 — PSX Going Medieval / Fantasy Props: soporte del castillo onírico de #284.
- #297 — Kenney UI Audio: extensión sonora CC0, ya cerrada; no cuenta como ambientación 3D pero comparte política de procedencia.
- #298 — Kubasta: fuente CC0 para terminales; complemento tipográfico, no sustituto del criterio visual 3D.

## Orden de ejecución

Mientras #398 siga abierto, el catálogo se prioriza por problemas visibles de la alpha y no por completar porcentajes del listado:

1. **calle**: terminar #295 y completar solo los huecos necesarios con #222/#225/#230/#218;
2. **oficina**: #294 como familia principal; #223/#226 solo si faltan piezas específicas;
3. **casa**: #227 cuando haya binarios verificables y procedencia reproducible;
4. **materiales/desgaste**: #231 bajo las reglas de #399;
5. **periferia/servicio/sueño**: #219/#220/#221/#228/#296 únicamente cuando una escena concreta los justifique.

Esto evita convertir #216 en una colección de packs sin uso jugable.

## Presupuesto y benchmark conjunto

La optimización local no basta para cerrar el criterio de rendimiento de #216. #415 acota el aporte actual de Retro Urban a dos instancias de una superficie, sin sombras, pero falta medir una escena con varias familias simultáneas.

La medición conjunta queda separada en #493. El benchmark debe comparar una misma vista/configuración con baseline y ambientación CC0 combinada, y registrar como mínimo draw calls más una métrica temporal disponible o una explicación reproducible de por qué no puede automatizarse. También debe incluir captura antes/después sin HUD.

No usar estimaciones como si fueran medidas reales.

## Gate de cierre de #216

#216 no debería cerrarse hasta que se cumplan, como mínimo, estos puntos:

- [x] existe al menos una integración real de fondo con geometría externa y procedencia: #217/#236;
- [x] existe un cielo/preset CC0 adaptado y montado: #224/#235;
- [x] existe una integración urbana PSX real, aunque todavía incompleta: #295/#402/#415;
- [ ] la calle alcanza un corte suficientemente denso sin parecer un catálogo de packs;
- [ ] oficina y casa tienen al menos una familia CC0 realmente integrada cuando sea necesaria para #398;
- [ ] existe benchmark combinado reproducible: #493;
- [ ] hay captura(s) comparables que demuestren que los assets se integran con el tratamiento SIGA-98;
- [ ] no quedan binarios externos sin procedencia/hash/LFS cuando aplique;
- [ ] cualquier sub-issue cerrado que se use como evidencia tiene PR/commit de entrega enlazado.

## Qué no hacer

- importar un pack completo para “tenerlo disponible”;
- añadir un asset porque sea más detallado si no mejora lectura, tono o profundidad;
- usar una escena demo de terceros como composición final;
- convertir señalética, logos o props contemporáneos en foco visual sin revisión;
- mezclar una nueva fuente con cambios de gameplay no relacionados;
- cerrar #216 solo porque el catálogo tenga muchas fuentes: el criterio es **integración útil y medida**.

— Odiseo (GPT-5.6 Sol)
