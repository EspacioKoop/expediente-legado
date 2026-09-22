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

## Estado de integración — 2026-09-22

La referencia es `main`. Un PR cerrado sin merge no cuenta como integración y una CI verde no sustituye validación humana.

El proyecto ya no está en el estado descrito por el roadmap del 14/09. Tras el saneamiento P0 se han integrado varias oleadas nuevas: correcciones de oficina/SIGA a 1080p, vida cotidiana 1998, reloj y audio contextual, huellas persistentes, identidad propia de OS98, mitologías en runtime, religión/ideologías transversales, una primera vertical literaria y la modularización inicial del Juicio 3D.

El siguiente objetivo no es “añadir sistemas porque faltan”, sino **hacer pasar un playthrough humano sobre el `main` actual y convertir sus fallos reproducibles en prioridad**.

### Recorrido, controles y legibilidad

- **Oficina/SIGA:** #1141 corrige la ronda de fallos observada a 1920×1080; #1091 confirma salida física y #1089 mantiene una salida de rescate independiente del foco.
- **Cámara:** #1095/#1097 blindan la interacción entre ratón, GUI y cámara en runtime. #396/#113 siguen siendo gates humanos de sensación y mando físico.
- **HUD/tipografía:** #780/#1126 protegen fuentes empaquetadas y #397 sigue abierto por jerarquía visual real.
- **Personajes:** #1083/#1087/#1112/#1113 mejoran presencia y legibilidad. #275/#134 siguen abiertos porque el cierre depende de observación humana, no del mero número de mallas.
- **Renderer:** el port usa **Forward+** desde #1121, con sombras, SSAO y SSIL; no documentar ya el renderer de compatibilidad como estado actual.

### SIGA, expedientes y decisiones

- #513 mantiene el objetivo de evidencia documental consultable; #1101 añade un gate visual reproducible.
- #431/#286 siguen siendo la superficie de playtest de profundidad SIGA: las capas existentes deben probarse antes de volver a ampliar el framework.
- #150 ya conecta evaluación con economía, historial y cierre de vida (#1081/#1086/#1090).
- #954 amplía decisiones con historial y aplazamientos acumulativos (#1159), sin mezclar decisión política con hechos del expediente.
- #961 añade meticulosidad contextual: microdetalles (#1169), sueño (#1155) y audio (#1187). Debe seguir siendo opt-in/contextual, no una barra universal.
- #959 ya tiene huellas persistentes y desgaste documental (#1122/#1186).

### Mundo, tiempo, audio y vida cotidiana

- **Comercio:** #676 dispone de espacios, interiores, reventa física y feedback diegético (#1088/#1127/#1132/#1134) con gate visual #1136.
- **Casa:** #677 suma objetos, recuerdos y decals propios (#1142–#1146); #1151 consolida evidencia de varias verticales cotidianas.
- **Vecindario:** #673 materializa vecinos y portal en #1144.
- **Tiempo:** #963 tiene reloj persistente e iluminación horaria (#1135/#1138).
- **Audio:** #966 progresa con ambiente por estado/hora, gestos, sueño, TV, papel y meticulosidad (#1128/#1130/#1133/#1137/#1139/#1187). #119 continúa como gate/expansión de mezcla transversal.
- **Trayecto:** #277 sigue siendo un gate humano de lectura espacial; no basta con añadir props si la calle continúa percibiéndose como pasillo.

### OS98 y Portátil Color 98

- Iconos propios y personalidad de aplicaciones avanzan en #781/#791: Catálogo, Calculadora, Bloc de notas y Correo ya tienen verticales (#1149/#1150/#1152/#1190/#1192).
- La Portátil Color 98 recibió apagado físico/afterglow y paletas propias (#1177/#1185/#1188).
- La portátil es infraestructura compartida por ROMs propias; no duplicar emulador, input, audio o persistencia para cada sistema cultural.

### Tarot, mitologías, ideologías, religión y literatura

Estas capas pueden cruzarse, pero **no son una sola estadística**.

- **Tarot:** #1029 sigue portando triggers/progresión del legado; varios desbloqueos ya están integrados (#1094/#1100/#1104/#1108/#1109).
- **Mitologías:** #1157 integra el corpus común; Mari, Yggdrasil y Popol Wuj recibieron nuevos verticales (#1164–#1166). #1171/#1174 desarrollan el contrato jungiano/mitológico transversal.
- **Ideologías:** #915–#925 son el marco. Doctrinas heredadas ya llegan al Juicio 3D (#1115), a cierres de expediente (#1124) y a prensa/radio (#1148).
- **Religión:** #916–#937 mantiene exposición, práctica, convicción y vínculo separados. JALI 98, VITRAL 98 y SARNATH 98 prueban ROM/cultura (#1158/#1163/#1168/#1170); #934 tiene un primer vertical de práctica/cultura material (#1147); #936 ya dispone de un primer contrato contextual de conflicto (#1117).
- **Literatura:** #1176 cierra el contrato de conocimiento/posesión/insight/ritual. #1178 crea la primera vertical ejecutable y #1194 alinea el legado con ese contrato. La expansión sigue en #1179–#1184.

### Juicio 3D y deuda técnica

El crecimiento de capas culturales hizo de `juicio_combate_3d.gd` un punto de concentración excesiva. #1191 es la deuda técnica activa. Ya se han extraído:

- reglas puras (#1193);
- adaptador jungiano (#1195);
- capa simbólica (#1196).

Cualquier nueva integración debe preferir módulos/contratos existentes y evitar volver a concentrar responsabilidad en el controlador de escena.

## Punto de control actual: playthrough humano sobre el main de 2026-09-22

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
- completar identidad de aplicaciones #781/#791 donde aporte legibilidad, no decoración;
- cerrar gates visuales supervivientes sin reescribir sistemas que ya funcionan.

### v0.9.0 · Vida cotidiana y capas transversales

Esta fase contiene profundidad opcional/semisistémica que debe enriquecer varias jornadas sin bloquear el núcleo:

- vida 1998 #669 y derivados;
- audio/ambiente #966/#119;
- huellas #959 y meticulosidad #961;
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
