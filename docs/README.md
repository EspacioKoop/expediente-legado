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
| Procedencia de assets | `godot/assets/procedencia.json` + `docs/licencias/` | Licencia, fuente y hashes |

## Estado transversal — 2026-09-22

Las capas que más han cambiado desde la documentación del 14/09 son:

- **mundo 1998**: comercio, reventa, vecinos, objetos domésticos y evidencia visual;
- **tiempo/audio**: reloj persistente, iluminación por hora y ambiente adaptativo;
- **OS98/Portátil Color 98**: identidad de aplicaciones, paletas y acabado físico;
- **mitologías/Jung**: corpus runtime y nuevos adaptadores;
- **ideologías**: doctrinas en Juicio, decisiones y medios;
- **religión**: ROMs culturales, práctica material y conflicto contextual;
- **literatura**: contrato transversal nuevo y primera vertical ejecutable;
- **deuda técnica**: modularización de `juicio_combate_3d.gd`.

Para el estado exacto de prioridad, usar #181; para saber qué está realmente integrado, usar `main` y los PR fusionados.

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
