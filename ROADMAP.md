# Roadmap

Mapa de fases hasta la primera versión completa. **La prioridad operativa la fija el [plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181)**; este documento cambia más despacio y no sustituye criterios de aceptación de issues concretos.

| Dónde se mira | Qué responde |
| --- | --- |
| [Plan maestro #181](https://github.com/EspacioKoop/expediente-legado/issues/181) | Qué va primero ahora |
| [Registro de reservas #182](https://github.com/EspacioKoop/expediente-legado/issues/182) | Quién puede editar qué |
| [Auditoría de paridad SIGA](docs/paridad-expedientes.md) | Qué del legado existe ya en Godot |
| [Milestones](https://github.com/EspacioKoop/expediente-legado/milestones) | Qué está comprometido para una versión |
| [Releases](https://github.com/EspacioKoop/expediente-legado/releases) | Qué se ha publicado |

## Estado de integración — 2026-09-14

La referencia es `main`. Los PR cerrados sin merge no cuentan como integración y una CI verde no sustituye una validación humana.

El segundo playtest humano, realizado sobre la alpha #237 / PR #394, **falló el gate de experiencia** aunque CI y export fueran verdes. El recorrido estaba disponible, pero la build seguía leyendo como prototipo/greybox por cámara, HUD, identidad espacial, materiales, densidad, personajes y puesta en escena. Desde entonces se ha integrado un saneamiento P0 amplio. El siguiente corte debe medir ese saneamiento; no debe reabrir sistemas ya implementados sin un fallo reproducible.

### Recorrido, cámara, HUD y QA

- **Partida:** #288 corrige Continuar/Nueva partida; #271 sigue siendo gate humano de persistencia real.
- **Onboarding:** #304 mejora archivo, puesto 4-B y primera acción; #272 sigue siendo validación humana.
- **Movimiento/cámara:** #305 normalizó WASD/flechas y pisadas; #405 cubre el núcleo técnico de #396 con ratón y stick derecho, sensibilidad e inversión Y persistentes, deadzone, aceleración/frenado y captura de cursor. #396/#113/#273 quedan para sensación, mando físico y presentación.
- **HUD/diálogo:** #406 concentra prioridades en `HUDLayer`, sustituye frases por proximidad por interacción explícita con NPC y conserva atribución de hablante; #453 elimina el bloque de estado permanente fuera del archivo. #397/#276 siguen abiertos por lectura visual humana.
- **Feedback de testers:** #392 integra Parte de incidencias con diagnóstico opt-in, portapapeles/guardado local y URL externa opcional.

### SIGA, investigación y decisiones

- #289 añade relación manual entre folios; #309 marcadores; #318 metadatos; #320 feedback de relaciones; #321/#323 anexos; #371 valida referencias/procedencia.
- #352 versiona la auditoría legado → Godot y #367 conecta al careo contexto realmente descubierto. #286 se valida ahora mediante playtest específico: no hay que añadir mecánicas por inercia.
- #364 introduce archivado manual 3D.
- #339/#369 permiten posponer la decisión política; #477 exige contexto nuevo antes de volver a decidir. #287 queda como gate de ritmo y comprensión, no como excusa para otra capa genérica.

### Interacción, densidad y personajes

- #307/#341 establecen el contrato/detector común; #345 conecta el terminal SIGA y #348 los archivadores reales.
- #400 ya tiene un vertical reactivo en cada espacio principal: casa (#407), oficina (#423), sueño (#424) y calle (#433). El issue paraguas queda principalmente como **validación visual humana transversal** de densidad y respuesta.
- #465 sustituye dos proxies domésticos de alto valor por una cama y un cuenco reconocibles, anclados a las coordenadas reales de gameplay. #282 sigue abierto para lectura/densidad global.
- #445 añade respiración ambiental mínima y un gesto selectivo de orientación, respetando reducción de movimiento. #134 sigue abierto por validación humana y posible segundo corte solo si el playtest lo justifica.
- #275 continúa siendo un gate visual importante: la existencia de una malla low-poly no demuestra por sí sola que los rostros funcionen desde frente, 3/4 y perfil.

### Identidad espacial y materiales

- **Oficina:** #412 introduce perfiles reutilizables de melamina, metal pintado y ABS sobre el shader PSX común.
- **Casa:** #420 consolida la distribución doméstica; #427 añade madera, tejido y acero de cocina propios sin assets binarios nuevos.
- **Trayecto:** #429 añade cielo exterior y dos capas de profundidad urbana; #449 materializa fachadas con revoco urbano procedural sin cambiar navegación.
- **Sueño:** la geometría poligonal/no ortogonal y el dressing reactivo ya tienen infraestructura y verticales integrados (#325/#344/#424), pero #279/#398/#399 mantienen el gate de identidad/material final y captura sin HUD.
- #398 es la regla transversal de composición; #399 la de superficies. Ambos se cierran por lectura humana de los cuatro espacios, no por contar PRs.

### Cinemáticas y tratamiento visual

- #410 reemplaza la entrada inicial de cuatro inserts 2D por una secuencia 3D sobre la oficina real.
- #428 hace casa → sueño mediante tres planos 3D sobre la casa real y conserva el mismo estado al terminar o saltar.
- #395 ya no necesita volver a implementar esas dos secuencias: faltan captura/vídeo en export y pase humano de legibilidad/ritmo.
- #470 cerró #115 con comparativas controladas de oficina y sueño, manteniendo `dithering=0.65`; HUD, visor y documentos permanecen fuera del shader espacial.

### Sueño y continuidad

- #301 sustituye salida oculta por progreso por objetivos; #308 hace visible 0/2 → 2/2 y reorienta al gato; #313 corrige el detector físico. #281 queda como gate humano de comprensión.
- #332 limita recompensas oníricas a pistas catalogadas: el sueño no crea hechos nuevos.
- #280 sigue siendo un gate de **export real** para transiciones y continuidad, ahora complementado por las secuencias 3D de #410/#428.

### Vida cotidiana y extras ya integrados

- #83 mantiene la economía base; #84/#85 tienen verticales funcionales y #333 conecta pérdida de vivienda con `home_storage` sin borrar lo llevado encima.
- #322 integra un primer vertical de trabajillos; #94 sigue abierto para equilibrio.
- #363/#365 añaden sellos persistentes internos sin recompensa mecánica directa.
- La portátil, la emulación GB, minijuegos y otros verticales opcionales ya presentes en `main` **no pasan a ser gates de v0.6 por estar integrados**. La expansión adicional permanece detrás del saneamiento P0 salvo autorización explícita de prioridad.

## Punto de control actual: saneamiento P0 antes del siguiente corte humano

Ya no usamos como baseline vigente el SHA previo al segundo playtest. El siguiente candidato debe cortarse desde un `main` donde los cambios P0 necesarios estén integrados y sus workflows verdes, y debe registrar el SHA exacto en las notas de alpha. Hasta entonces, no conviene fijar aquí un hash que envejezca con cada merge.

Recorrido de control:

**Nueva partida → entender el archivo → mover cámara libremente y localizar interacciones → usar SIGA → investigar un expediente con relaciones/capas suficientes → firmar/careo → cobrar → recorrer una calle inequívocamente exterior → entrar en una casa reconocible → ver la transición 3D a sueño → completar la primera noche por objetivos → despertar → alquiler/impago → cerrar y recargar conservando estado.**

### Lo que debe validar una persona

- **#396/#113/#273** — ratón, stick derecho, sensibilidad, foco, remapeo y tacto con mando físico.
- **#397/#276** — ninguna capa de HUD tapa diálogo/prompt/tutorial; los NPC conversables se entienden sin llenar la pantalla de iconos.
- **#398/#399** — oficina, calle, casa y sueño se reconocen sin HUD también por arquitectura, profundidad y materiales.
- **#282/#400** — hay suficiente densidad 3D e interacción para que los espacios se sientan usados, no una colección de demos aisladas.
- **#275/#134** — compañeros coherentes desde varios ángulos y con presencia mínima, sin caras pegadas ni sensación de maniquí.
- **#395/#280** — entrada y casa → sueño se ven, se entienden, pueden saltarse y terminan en el mismo estado en una export real.
- **#271/#272** — nueva/continuar, persistencia y onboarding funcionan sin conocimiento previo.
- **#281** — la primera noche se resuelve por objetivos sin buscar una salida invisible.
- **#286** — el expediente se percibe como investigación ligera real y no como lectura → decisión inmediata.
- **#287** — posponer y madurar una decisión política evita el ritmo precipitado sin bloquear el flujo.
- **#119** — ambiente audible y equilibrado en contexto cuando corresponda al corte.

Cualquier fallo reproducible encontrado aquí gana prioridad frente a expansión opcional. Un gate que pasa se documenta; no se reabre por preferencia estética sin una regresión concreta.

## Fases

### v0.6.0 · Recorrido completo

La estructura del recorrido está cerrada en lo esencial, pero el segundo playtest demostró que “completable” no bastaba. v0.6 contiene ahora el **saneamiento P0 de experiencia** necesario para que el siguiente recorrido humano mida un juego y no un greybox.

Mantener aquí únicamente trabajo que pueda invalidar ese pase: cámara/control, HUD, identidad espacial/material, densidad/personajes, continuidad prioritaria y los gates funcionales del recorrido. Los expedientes adicionales (#91), colecciones y extras no son requisito de salida.

**Salida de fase:** una alpha recorrida de principio a fin sin consola ni conocimiento del código, con persistencia real, espacios legibles, control cómodo, sin bloqueos funcionales y sin hallazgos P0 de presentación que impidan evaluar el juego.

### v0.7.0 · Cinemáticas y continuidad

Las dos secuencias P0 que bloqueaban el siguiente pase ya tienen verticales 3D integrados (#410 y #428). Antes de expandir la puesta en escena:

- #395/#280 deben pasar captura/vídeo y validación humana en export real;
- #177 puede aportar investigación/prototipos originales solo cuando resuelvan un problema observado;
- las nuevas cinemáticas deben reutilizar mundo, props y estado del gameplay, y no reabrir infraestructura estable por estética solamente.

#209 sigue fuera de esta fase: los incidentes de conducta son simulación cotidiana/social y pertenecen a v0.9.

### v0.8.0 · Presentación, mando y accesibilidad mínima

Ya integrado, entre otros:

- tipografía libre por defecto (#172);
- foco A-7 (#174);
- menú global/preferencias (#306);
- remapeo visual teclado/mando (#335);
- cámara configurable (#405);
- HUDLayer/diálogo interactivo (#406) y reducción de HUD permanente (#453);
- Parte de incidencias para testers (#392).

Pendiente principal:

- validar recorrido con mando físico (#113/#98/#396);
- cerrar superficies concretas de accesibilidad que #98 mantenga abiertas;
- completar traducción del catálogo (#107);
- revisar presentación en resoluciones/exportaciones soportadas;
- cerrar gates visuales que sobrevivan al pase v0.6 sin convertir esta fase en una reescritura del arte.

El ambiente continuo #119 se evalúa principalmente como parte del ciclo oficina → calle → casa → sueño en v0.9.

### v0.9.0 · Vida cotidiana, contenido y ambiente

La economía base ya no es un bloqueo. Esta fase reúne lo que hace que vivir varias jornadas tenga peso y variedad:

- vivienda/alquiler/impago — #84/#85;
- compras e imprevistos — #93/#96;
- trabajillos — #94, con vertical ya integrado y equilibrio aún abierto;
- gato transversal — #92;
- sueño alimentado por lo conocido — #79/#87/#89/#97;
- familias/variación onírica — #279/#284 solo cuando la primera noche ya sea legible;
- interacción ambiental — #283/#400 por objetos y situaciones concretas, no otra arquitectura genérica;
- ambiente sonoro — #119;
- expedientes adicionales — #91;
- incidentes sociales/consecuencias ambientales — #209 y derivados.

Los minijuegos, la portátil y otros extras ya integrados pueden probarse aquí como contenido opcional, pero no definen la salida de fase.

### v1.0.0 · Primera versión completa

Objetivo: distribuir una build que sobreviva un playthrough real y cuya accesibilidad mínima esté documentada.

- exportación y publicación reproducible — #112;
- distribución pública/itch.io y preparación comercial — #99;
- playtesting humano de principio a fin — #9;
- licencias/procedencia verificadas para todo asset distribuible;
- gates de CI y revisión sin excepciones manuales ocultas.

La 1.0 no exige agotar el backlog de minijuegos, arte opcional o colecciones.

### Después de la 1.0

Permanece detrás del recorrido principal salvo dependencia demostrada:

- expansiones de colecciones/minijuegos que no resuelvan un hallazgo;
- logros externos (#114);
- familias oníricas expansivas (#284) una vez validada la primera noche;
- arte/ambientación que no resuelva un hallazgo concreto del playtest;
- expansiones de cinemáticas o simulación que no cambien el punto de control actual.

Una pieza opcional ya integrada no se vuelve a tratar como trabajo base: cualquier ampliación futura debe justificar su prioridad de forma independiente.

## Ajuste de milestones — 2026-09-13

Para que GitHub y este roadmap vuelvan a decir lo mismo se recolocaron tres issues abiertos:

- #91: **v0.6 → v0.9**, porque ampliar el catálogo no bloquea el recorrido;
- #209: **v0.7 → v0.9**, porque es simulación social/cotidiana, no infraestructura cinematográfica;
- #119: **v0.8 → v0.9**, porque el ambiente se valida como parte del ciclo diario y ya tiene un primer vertical de oficina integrado.

El saneamiento P0 posterior al segundo playtest no revierte ese ajuste: añade gates de experiencia a v0.6, no contenido expansivo.

No se cierran milestones por una CI verde. Se cierran cuando su criterio de salida ha sido validado y existe un release/corte correspondiente.

## Regla para mover trabajo entre fases

1. Un bloqueo observado en #9 gana frente a expansión opcional.
2. Una mejora P1 pequeña puede adelantarse si mejora directamente el siguiente playthrough.
3. Los paraguas #279/#282/#283/#400 se ejecutan por verticales pequeños y se cierran por evidencia transversal.
4. Un issue no “sube” por tener código interesante: debe eliminar un bloqueo, una regresión o una dependencia mínima.
5. Una pieza técnicamente integrada puede seguir abierta únicamente por validación humana; eso **no autoriza reescribirla** sin un fallo reproducible nuevo.
6. `main` manda sobre cuerpos históricos de issues, ramas antiguas o comentarios anteriores.
7. Un extra ya integrado no se convierte por ello en requisito del recorrido principal.
8. Si el backlog opcional vuelve a crecer mientras los gates P0 siguen abiertos, #181 tiene prioridad y debe aplicarse como cortafuegos.

## Milestones, Projects y releases

- **Milestone** = versión comprometida; se cierra con su release/corte validado.
- **Projects** = estado operativo del trabajo, no fuente única de prioridad.
- **Plan maestro #181** = orden vigente y punto de control.
- **Release/alpha** = artefacto publicado con notas que distinguen claramente qué se probó automáticamente y qué se validó de forma humana.

Si dos superficies discrepan, corrige la documentación; no mantengas dos planes paralelos.
