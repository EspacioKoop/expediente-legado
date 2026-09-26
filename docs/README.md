# Índice de documentación

Este directorio contiene auditorías, decisiones de diseño, investigación, evidencia y documentación de sistemas. **No todos los documentos tienen la misma autoridad**: algunos son históricos o evidencias de un corte concreto.

## Fuentes canónicas

| Área | Documento / issue | Uso |
| --- | --- | --- |
| Prioridad operativa | [#181](https://github.com/EspacioKoop/expediente-legado/issues/181) | Qué va primero y cuál es el siguiente gate |
| Reservas | [#182](https://github.com/EspacioKoop/expediente-legado/issues/182) | Coordinación de edición |
| Fases | [ROADMAP.md](../ROADMAP.md) | Dirección v0.6 → 1.0 |
| Entrada al repo | [README.md](../README.md) | Estado general, stack y comandos |
| Flujo de contribución | [AGENTS.md](../AGENTS.md), [CONTRIBUTING.md](../CONTRIBUTING.md) | Ramas, PR, CI, merge |
| Paridad SIGA | [paridad-expedientes.md](paridad-expedientes.md) | Legado → Godot para expedientes |
| Paridad ideologías | [paridad-ideologias.md](paridad-ideologias.md) | Legado político y contrato transversal |
| Paridad religión | [paridad-religion.md](paridad-religion.md) | Fronteras religión/Tarot/mitología |
| Paridad literatura | [paridad-literatura.md](paridad-literatura.md) | Legado cultural y contrato literario |
| Gramática simbólica | [design/gramatica-simbolica-siga98.md](design/gramatica-simbolica-siga98.md) | Convenciones simbólicas compartidas |
| Referencias ludonarrativas | [research/referencias-ludonarrativas.md](research/referencias-ludonarrativas.md) | Técnicas externas, riesgos y mapa de adopción; no declara features integradas |
| Procedencia de assets | `godot/assets/procedencia.json` + `docs/licencias/` | Licencia, fuente y hashes |

## Estado transversal — 2026-09-26

El índice se sincroniza con `main` hasta el commit `6ccfa4317897d70ca9462e7c92aefea41095b2bc`. Para prioridad operativa sigue mandando #181; para integración real, `main` y los PR fusionados.

Cambios materiales desde el corte anterior:

- **SIGA/OS98:** el terminal ya tiene núcleo seguro, UI física, archivos/usuarios simulados e historial (#1410/#1416/#1422/#1423);
- **investigación documental:** reconstrucciones 3D cubren los diez expedientes (#1365/#1369), y análisis/falsificación/revisión de copias añaden nuevas acciones sin reescribir la evidencia (#1426/#1429/#1431);
- **HUD/legibilidad:** #1401 conecta el HUD contextual a fases reales; #1367 refuerza contraste de menús y superficies OS98, manteniendo abiertos los gates humanos;
- **consecuencias burocráticas:** #1435/#1436 convierten errores de archivado en desorden visible y demora acotada/reversible, derivados del estado existente;
- **mundo vivo:** fauna, microgestos y respuesta a clima/hora progresan en #1398/#1404/#1409/#1412; #1363/#1420 amplían huellas de uso a equipos y tránsito;
- **personajes:** protagonista Rocketbox, mocap de compañeros y dependientes con identidad funcional avanzan en #1394/#1371/#1391;
- **sueños/mitologías:** PBR y props propios se conectan a las seis familias (#1414/#1417/#1419/#1425/#1428), Mari entra al runtime (#1427) y Baba Yaga gana arquitectura mutable por fases (#1413/#1415/#1421/#1424/#1430/#1434);
- **atrezzo cultural:** #1440 añade el bonsái inspirado en Yggdrasil y **Yggdrasil's Egg** como dressing sin desbloqueos ni economía;
- **investigación de diseño:** #1433 versiona el corpus [referencias ludonarrativas](research/referencias-ludonarrativas.md), separando técnica reutilizable de contenido protegido y de features realmente integradas.

El criterio de lectura sigue siendo el mismo: separar **hecho integrado**, **gate pendiente** y **propuesta**. Un artefacto de CI, screenshot automatizado o documento de investigación no cierra por sí solo un requisito humano.

## Auditorías y paridad

Los documentos `paridad-*.md` responden a una pregunta concreta: **qué existía en el legado y cómo se representa ahora**. No deben convertirse en roadmaps paralelos.

- [paridad-expedientes.md](paridad-expedientes.md) — comportamiento SIGA y expedientes.
- [paridad-ideologias.md](paridad-ideologias.md) — decisiones, exposición, doctrinas y final político.
- [paridad-religion.md](paridad-religion.md) — inventario negativo y límites con sistemas vecinos.
- [paridad-literatura.md](paridad-literatura.md) — inventario negativo, contrato literario y expansión posterior.

Cuando una auditoría dice “no existía”, significa que no se encontró esa capa en el corpus versionado de su corte temporal; no impide crear contenido nuevo, pero evita presentarlo como port.

## Diseño e investigación

- `design/` contiene contratos o gramáticas que pueden seguir vigentes.
- `research/` contiene investigación y referencias; sirve para informar decisiones, no para declarar una mecánica integrada.
- [research/referencias-ludonarrativas.md](research/referencias-ludonarrativas.md) — corpus transversal de juegos, cine/TV, literatura y recursos reutilizables; traduce referencias a técnicas, riesgos e issues dueños (#1432).
- `jungian_mitologia_propuesta/` contiene propuestas de la capa jungiana/mitológica.
- `audio/`, `assets/`, `visuales/` y `licencias/` agrupan documentación específica de producción.

Antes de implementar una propuesta antigua, comprobar si un issue o PR posterior ya cambió el contrato.

## Evidencia y playtests

Los archivos `alpha-playtest-*.md`, `playtest-*.md`, `validacion-*.md`, `evidencia-*.md` y `evidencias/` son **fotografías de un SHA/corte concreto**. No deben leerse como descripción del estado actual sin comprobar fecha y commit.

Regla:

1. identificar el SHA/PR que documenta la evidencia;
2. comparar con `main`;
3. si hubo cambios posteriores, repetir el gate o marcar la evidencia como histórica;
4. no cerrar un gate humano usando únicamente una prueba automatizada antigua.

## Documentos de sistemas/mundo

Entre otros:

- [comercio-barrio.md](comercio-barrio.md)
- [telefono-fijo.md](telefono-fijo.md)
- [correo-postal.md](correo-postal.md)
- [tienda-videojuegos.md](tienda-videojuegos.md)
- [casa-huella-vida.md](casa-huella-vida.md)
- [casa-sonido-domestico.md](casa-sonido-domestico.md)
- [vecinos-edificio.md](vecinos-edificio.md)
- [roms-propias.md](roms-propias.md)
- [roms-usuario.md](roms-usuario.md)
- [emulador-gb.md](emulador-gb.md)
- [emulador-gb-audio.md](emulador-gb-audio.md)

Son documentación de subsistemas o verticales; si contradicen el contrato actual de un issue/épica transversal, prevalece el contrato más reciente.

## Convenciones de mantenimiento

- Fechar bloques de “estado actual” cuando dependan del backlog.
- Separar **hecho integrado**, **gate pendiente** y **propuesta**.
- No duplicar checklists de issues en varios documentos.
- Enlazar el issue dueño en vez de copiar todo su cuerpo.
- Mantener las auditorías históricas; añadir una nota de estado actual en lugar de reescribir el pasado.
- Actualizar README/ROADMAP/#181 tras playtests grandes o una oleada material de merges.
- Corregir enlaces/números de issue cuando una épica se reorganice.
