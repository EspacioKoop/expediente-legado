# Roadmap

Mapa de fases hasta la primera versión completa. **La prioridad operativa la fija el [plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181)**; este documento resume estado, gates y dirección. Los criterios de aceptación siguen viviendo en cada issue.

| Dónde se mira | Qué responde |
| --- | --- |
| [Plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181) | Qué va primero ahora |
| [Registro de reservas #182](https://github.com/EspacioKoop/expediente-legado/issues/182) | Quién puede editar qué |
| [Índice de documentación](docs/README.md) | Qué documento es canónico para cada sistema |
| [Paridad SIGA](docs/paridad-expedientes.md) | Qué del legado existe ya en Godot |
| [Paridad ideologías](docs/paridad-ideologias.md) | Qué se recuperó y qué se generalizó |
| [Paridad religión](docs/paridad-religion.md) | Límites con Tarot/mitología y expansión nueva |
| [Paridad literatura](docs/paridad-literatura.md) | Contrato y frontera legado → expansión |
| [Milestones](https://github.com/EspacioKoop/expediente-legado/milestones) | Qué está comprometido para una versión |
| [Releases](https://github.com/EspacioKoop/expediente-legado/releases) | Qué se ha publicado |

## Estado de integración — 2026-09-26

La referencia es `main`, con corte documental en `6ccfa4317897d70ca9462e7c92aefea41095b2bc`. Un PR cerrado sin merge no cuenta como integración y una CI verde no sustituye validación humana.

Desde el corte del 22/09 el proyecto ha añadido profundidad en varias superficies sin cambiar la regla de prioridad: **un fallo reproducible del recorrido base gana frente a una expansión opcional**. La oleada reciente refuerza herramientas de investigación, OS98/SIGA, consecuencias burocráticas, fauna/huellas y dirección onírica.

### Recorrido, HUD y personajes

- #1401 implementa el HUD contextual de #397: los recursos dependen de la fase en vez de ocupar siempre la pantalla. #397 sigue necesitando evaluación humana de jerarquía/legibilidad.
- #1367 mejora contraste de menús y superficies OS98; no sustituye el gate visual global.
- #1394 lleva el avatar Rocketbox al protagonista; #1371 y #1391 mejoran animación/presencia de compañeros y dependientes. #275/#134 siguen siendo gates humanos.
- #396/#113 continúan como gates de cámara, foco y mando físico.

### Investigación, SIGA-98 y documentos

- #1365/#1369 completan reconstrucciones 3D documentales para los diez expedientes actuales. Deben leerse como **punto de vista de una fuente**, nunca como verdad omnisciente.
- #1410/#1416/#1422/#1423 convierten el terminal SIGA en una superficie jugable: parser ficticio, UI diegética, archivos temporales simulados, usuarios e historial. Todo permanece aislado de filesystem/red/procesos reales.
- #1426/#1429/#1431 añaden análisis, falsificación temporal y revisión narrativa de copias, con resultados deterministas y sin reescribir la evidencia original.
- #1435/#1436 conectan archivado incorrecto con desorden visible y demora breve de búsqueda, ambos derivados del mismo estado y recuperables al corregir.
- #286/#431/#513 siguen siendo los gates de profundidad: la siguiente pregunta es si estas herramientas mejoran la investigación real durante una partida, no cuántas capas existen.

### Mundo, persistencia y vida cotidiana

- #1398/#1404/#1409/#1412 añaden fauna ambiental, microgestos, acabado y respuesta a hora/clima.
- #1363 y #1420 amplían #959 con huellas de equipos domésticos y tránsito repetido sin crear un sistema paralelo.
- #1418 amplía el golf a tres hoyos como vertical autónomo; sigue fuera de los requisitos de release.
- #1440 añade el bonsái inspirado en Yggdrasil y **Yggdrasil's Egg** como atrezzo diegético sin desbloqueos ni economía.

### Sueños y presentación

- #1414/#1417/#1419/#1425 conectan materiales y props PBR propios a las seis familias de #435; #1428 añade evidencia visual reproducible para las familias que no tenían capturador dedicado.
- #1427 integra el pack visual de Mari al runtime.
- #1413/#1415/#1421/#1424/#1430/#1434 desarrollan Baba Yaga como arquitectura mutable y legible sin mover la navegación al mismo sistema visual.
- #1433 versiona el corpus transversal de referencias ludonarrativas. Es investigación aplicable a issues dueños, no un permiso para abrir features por mera inspiración.

### Deuda técnica y disciplina de integración

La regla tras la modularización inicial del Juicio 3D se mantiene: sistemas transversales deben consumir contratos pequeños y estado existente, no concentrar más responsabilidad en controladores de escena. El mismo criterio aplica ahora a terminal, reconstrucciones, huellas y consecuencias de archivado.

Ninguna evidencia automatizada nueva cierra por sí sola un criterio que exija persona, GPU real, mando físico o export.

## Punto de control actual: playthrough humano sobre el main de 2026-09-26

Recorrido mínimo a validar:

**Nueva partida → entender el archivo → localizar y usar SIGA → abrir/leer documentación real del expediente → relacionar/decidir/careo → cobrar → salir físicamente de la oficina → recorrer el trayecto → entrar en casa → interactuar con vida cotidiana/inventario → dormir → resolver la primera noche por objetivos → despertar → comprobar economía/estado → guardar/cerrar/continuar.**

### Gates que necesitan persona o export real

- **#9** — playthrough end-to-end.
- **#396/#113** — tacto de cámara, foco, ratón y mando físico.
- **#397/#780** — jerarquía visual y legibilidad real a 1080p.
- **#275/#134** — NPCs reconocibles y presencia mínima desde cámara normal.
- **#277** — trayecto legible como exterior/espacio urbano.
- **#395/#280** — continuidad/cinemáticas en export.
- **#431/#513/#286** — profundidad de expediente y documentos realmente consultables.
- **#793** — foco/salida de SIGA-98 en condiciones reales.
- **#119/#966** — mezcla audible y adaptativa en contexto.
- **#112** — export/publicación cuando vuelva a activarse la entrega pública.

Un fallo reproducible de este recorrido gana prioridad frente a una expansión opcional.

## Fases

### v0.6.0 · Recorrido completo y legible

Objetivo: demostrar que el núcleo ya implementado se puede jugar sin conocimiento del código.

Incluye únicamente trabajo capaz de invalidar el pase:

- entrada, cámara, foco, salida y persistencia;
- SIGA/documentos/careo suficientes para investigar;
- HUD y tipografía legibles;
- personajes y espacios reconocibles;
- trayecto, casa y sueño conectados;
- correcciones P0 encontradas por #9.

**Salida de fase:** playthrough humano sin consola ni bloqueo, con persistencia real y sin fallo P0 que impida evaluar el juego.

### v0.7.0 · Continuidad, puesta en escena y combate mantenible

- validar #395/#280 sobre export real;
- avanzar #177 solo donde exista una necesidad observada;
- cerrar la modularización #1191 antes de seguir acumulando reglas en Juicio 3D;
- mantener sistemas culturales como adaptadores/consumidores, no lógica embebida en escenas.

**Salida de fase:** transiciones comprensibles y Juicio/combate sin un controlador monolítico que bloquee nuevas integraciones.

### v0.8.0 · Presentación, mando, accesibilidad y OS98

Ya existen preferencias, remapeo, cámara configurable, HUD unificado y tipografías empaquetadas.

Pendiente principal:

- validación física de #113/#396;
- superficies concretas de accesibilidad (#98);
- revisión 1080p y resoluciones soportadas;
- validar en flujo real la identidad de aplicaciones #781/#791 y el terminal SIGA #956, priorizando legibilidad y navegación sobre decoración;
- cerrar gates visuales supervivientes sin reescribir sistemas que ya funcionan.

### v0.9.0 · Vida cotidiana y capas transversales

Esta fase contiene profundidad opcional/semisistémica que debe enriquecer varias jornadas sin bloquear el núcleo:

- vida 1998 #669 y derivados;
- audio/ambiente #966/#119;
- huellas #959, meticulosidad #961 y consecuencias espaciales de archivado #965;
- gato #787, inventario #97 y sueño #79;
- mitologías #650/#1171/#1174;
- ideologías #915–#925;
- religión #916/#930–#937;
- literatura #1175/#1179–#1184;
- expedientes adicionales y contenido cultural que reutilice contratos existentes.

**Regla de fase:** ninguna vertical transversal debe crear una segunda `Partida`, un segundo emulador, otro sistema de diálogo o un nuevo “alignment” global.

### v1.0.0 · Primera versión completa

Objetivo: distribuir una build que sobreviva un playthrough real y cuya accesibilidad/licencias estén documentadas.

- exportación y publicación reproducible — #112;
- distribución pública/itch.io y preparación comercial — #99, cuando se reactive;
- playtesting humano de principio a fin — #9;
- licencias/procedencia verificadas para todo asset distribuible;
- CI y revisión sin excepciones manuales ocultas;
- documentación canónica coherente con `main`.

La 1.0 no exige agotar el backlog de minijuegos, ROMs, arte opcional ni todas las familias culturales.

### Después de la 1.0

- nuevas ROMs y colecciones que no resuelvan un hallazgo;
- familias oníricas adicionales;
- expansiones sociales/culturales no necesarias para el recorrido base;
- arte/ambientación sin un problema concreto de legibilidad o identidad;
- logros/plataformas externas no necesarias para distribuir la primera versión.

## Regla para mover trabajo entre fases

1. Un bloqueo observado en #9 gana frente a expansión opcional.
2. Una mejora pequeña puede adelantarse si resuelve directamente el siguiente playthrough.
3. Los paraguas grandes se ejecutan por verticales pequeños y se cierran por evidencia transversal.
4. Un issue no sube de prioridad por tener código interesante.
5. Una pieza integrada puede seguir abierta únicamente por validación humana; eso no autoriza reescribirla sin fallo reproducible.
6. `main` manda sobre cuerpos históricos, ramas antiguas o documentación fechada.
7. Un extra integrado no se convierte automáticamente en requisito de release.
8. Los sistemas transversales deben reutilizar contratos; si necesitan flags especiales en cada escena, la arquitectura debe revisarse.
9. La deuda técnica que impide integrar con seguridad (como #1191) puede ganar prioridad antes de ampliar contenido.
10. Si documentación, milestone y #181 discrepan, hay que corregir la discrepancia; no mantener planes paralelos.

## Milestones, Projects y releases

- **Milestone** = versión comprometida; se cierra con release/corte validado.
- **Projects** = estado operativo, no fuente única de prioridad.
- **Plan maestro #181** = orden vigente y siguiente punto de control.
- **Roadmap** = mapa de fases y gates.
- **Release/alpha** = artefacto concreto con SHA y notas que separan pruebas automáticas de validación humana.

Este documento debe revisarse tras cada playtest grande o cuando una oleada de merges cambie de forma material el alcance del siguiente corte.
