# Roadmap

Mapa de fases hasta la primera versión completa. **La prioridad operativa la fija el [plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181)**; este documento cambia más despacio y no sustituye criterios de aceptación de issues concretos.

| Dónde se mira | Qué responde |
| --- | --- |
| [Plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181) | Qué va primero ahora |
| [Registro de reservas #182](https://github.com/EspacioKoop/expediente-legado/issues/182) | Quién puede editar qué |
| [Auditoría de paridad SIGA](docs/paridad-expedientes.md) | Qué del legado existe ya en Godot |
| [Milestones](https://github.com/EspacioKoop/expediente-legado/milestones) | Qué está comprometido para una versión |
| [Releases](https://github.com/EspacioKoop/expediente-legado/releases) | Qué se ha publicado |

## Estado de integración — 2026-09-13

La referencia es `main`. Los PR cerrados sin merge no cuentan como integración y una CI verde no sustituye una validación humana.

El primer playthrough humano (#9) cambió el orden del proyecto. Desde entonces se han integrado los cortes que bloqueaban más directamente un segundo recorrido útil:

- **Sueño:** #301 sustituyó la salida oculta por progreso 3→2; #308 hizo visible 0/2→2/2 y reorientó al gato; #313 corrigió el detector físico. #281 queda principalmente como gate de comprensión humana.
- **SIGA/investigación:** #289, #309, #318, #320, #321 y #323 añadieron combinación, marcadores, metadatos, feedback y anexos. #352 versionó la auditoría legado → Godot. #286 sigue abierto para paridad/contexto adicional y playtest de profundidad.
- **Controles/menús:** #306 integró menú global, pausa, foco y preferencias; #335 añadió remapeo visual de teclado y mando. #113 queda pendiente de validación con mando físico/presentación, no de construir el sistema base.
- **Interacción 3D:** #307/#341 establecieron contrato y detector común; #345 integró el terminal SIGA y #348 archivadores reales. #283 sigue abierto para extender el patrón solo donde mejore el recorrido.
- **Trayecto:** #314 lo convirtió en exterior; #331 agrupó el escaparate; #337 corrigió el nombre de fase real (`trayecto`). Falta validación visual, no reconstruir otra calle desde cero.
- **Presentación:** #310 integró rostros 3D, #317/#338 diálogo diegético y #315 el asistente-gato 2D. Sus issues asociados son principalmente validaciones visuales.
- **Vida cotidiana:** #83 fijó la economía base; #84/#85 tienen verticales funcionales y #333 conecta la pérdida de vivienda con lo almacenado en casa. #94 mantiene un trabajillo nocturno en PR abierto, no en `main`.
- **Audio:** los efectos puntuales (`Sonido`) y la música dramática (`Musica`, #330) están separados. #119 sigue abierto para ambiente continuo y mezcla; #349 es un primer corte en draft.
- **Cinemáticas:** la épica #66 y #80 quedaron cerradas. Las transiciones base existen; #280 es ahora validación en export real.

## Fases

### v0.6.0 · Recorrido completo

La implementación estructural del recorrido está cerrada en lo esencial: archivo → investigación → firma/careo → cobro → trayecto → casa → sueño → despertar.

El trabajo restante de esta fase es **verificar el recorrido como producto**, no añadir sistemas opcionales:

- partida nueva/continuar y persistencia (#271);
- onboarding inicial (#272);
- controles/pisadas (#273);
- cinemáticas en export (#280);
- primera noche comprensible y completable por objetivos (#281);
- SIGA con suficiente profundidad para no ser lectura→decisión inmediata (#286).

**Salida de fase:** una alpha post-playtest puede recorrerse de principio a fin sin consola ni conocimiento del código y sin perder estado al cerrar/reabrir.

### v0.7.0 · Cinemáticas y continuidad

La épica #66 está cerrada y los momentos principales ya comparten infraestructura. Esta fase deja de ser “construir todas las cinemáticas” y pasa a **validar continuidad y presentación**:

- #280 debe pasar en export real;
- #177 puede seguir aportando investigación/prototipos solo cuando mejoren un problema observado;
- #135 y otras mejoras espaciales no bloquean la infraestructura cinematográfica base.

La migración estética 2D→3D no es requisito automático: se hace cuando aporte lectura o puesta en escena, no por sustituir algo funcional.

### v0.8.0 · Presentación, mando y accesibilidad mínima

Ya integrado:

- tipografía libre por defecto (#172);
- foco A-7 (#174);
- menú global y preferencias (#306);
- remapeo visual teclado/mando (#335);
- rostros 3D (#310), diálogo diegético (#338) y asistente-gato (#315) como correcciones del playtest.

Pendiente principal:

- validar el recorrido con mando físico (#113/#98);
- cerrar superficies concretas de accesibilidad que #98 mantenga abiertas;
- completar traducción del catálogo (#107) sin duplicar el mecanismo de `textos.csv`;
- revisar presentación en resoluciones/exportaciones soportadas.

### v0.9.0 · Vida cotidiana, sueño y ambiente

La economía base ya no es un bloqueo: #83 está cerrada. La fase se centra en hacer que hogar, dinero, gato, sueño y ambiente formen un ciclo coherente.

Ejes activos:

- vivienda/alquiler/impago — #84/#85;
- compras e imprevistos — #93/#96;
- trabajillos — #94, sin convertirlos en fuente infinita de dinero;
- gato transversal — #92;
- sueño alimentado por lo conocido — #79/#87/#89/#97;
- rediseño espacial onírico — #279 solo en cortes que ayuden a legibilidad/interacción;
- ambiente sonoro — #119, separado de efectos (#76) y música.

La recompensa onírica de #89 ya tiene contrato para reutilizar pistas catalogadas (#332); falta presentación/interacción concreta, no inventar información nueva.

### v1.0.0 · Primera versión completa

Objetivo: distribuir una build que sobreviva un playthrough real y cuya accesibilidad mínima esté documentada.

- exportación y publicación reproducible — #112;
- distribución pública/itch.io y preparación comercial — #99;
- playtesting humano de principio a fin — #9;
- licencias/procedencia verificadas para todo asset distribuible;
- gates de CI y revisión sin excepciones manuales ocultas.

La 1.0 no exige agotar el backlog de minijuegos, arte opcional o colecciones.

### Después de la 1.0

Permanece detrás del recorrido principal salvo que un issue demuestre dependencia real:

- minijuegos/colecciones y sistemas optativos (#148–#162, #189 y derivados);
- Game Boy Color/emulación (#124/#244 y siguientes);
- logros externos (#114);
- familias oníricas expansivas (#284) una vez validada la primera noche;
- arte/ambientación que no resuelva un hallazgo concreto del playtest;
- expansiones de cinemáticas o simulación que no cambien el punto de control actual.

## Regla para mover trabajo entre fases

1. Un bloqueo observado en #9 gana frente a expansión opcional.
2. Una mejora P1 pequeña puede adelantarse si mejora directamente el siguiente playthrough.
3. Los paraguas #279/#282/#283 se ejecutan por verticales pequeños.
4. Un issue no “sube” por tener código interesante: debe eliminar un bloqueo, una regresión o una dependencia mínima.
5. Una pieza técnicamente integrada puede seguir abierta únicamente por validación humana; eso no autoriza reescribirla sin un fallo reproducible nuevo.
6. `main` manda sobre cuerpos históricos de issues, ramas antiguas o comentarios anteriores.

## Milestones, Projects y releases

- **Milestone** = versión comprometida; se cierra con su release.
- **Projects** = estado operativo del trabajo, no fuente única de prioridad.
- **Plan maestro #181** = orden vigente y punto de control.
- **Release** = artefacto publicado con notas que distinguen claramente qué se probó automáticamente y qué se validó de forma humana.

Si dos superficies discrepan, corrige la documentación; no mantengas dos planes paralelos.
