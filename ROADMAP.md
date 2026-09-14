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

El primer playthrough humano (#9), realizado sobre la alpha generada por #270, cambió el orden del proyecto. Desde entonces `main` ha integrado un bloque amplio de correcciones y verticales para que el segundo recorrido mida el producto y no el greybox original.

### Recorrido, controles y QA

- **Partida:** #288 corrige la separación Continuar/Nueva partida; #271 queda como gate humano de persistencia real.
- **Onboarding:** #304 hace más legible el archivo, el puesto 4-B y la primera acción; #272 queda como validación humana.
- **Controles:** #305 normaliza WASD/flechas y atenúa pisadas; #306 integra menú global/preferencias y #335 remapeo visual teclado+mando. #113/#273 quedan para tacto, mando físico y presentación final.
- **Feedback de testers:** #392 integra un Parte de incidencias con diagnóstico opt-in, portapapeles/guardado local y URL externa opcional inyectada al empaquetar.

### SIGA e investigación

- #289 añade relación manual entre folios; #309 marcadores; #318 metadatos; #320 feedback de relaciones; #321/#323 anexos; #371 valida referencias/procedencia.
- #352 versiona la auditoría legado → Godot; #286 sigue abierto para profundidad/paridad adicional y para medir si el flujo deja de sentirse lectura → decisión inmediata.
- #367 conecta al careo contexto realmente descubierto por el jugador.
- #364 introduce un primer vertical jugable de archivado manual 3D.
- #339 y #369 permiten posponer la decisión política y la presentan como opción explícita; #287 queda para validar el ritmo en el siguiente playthrough.

### Interacción, espacios y presentación

- #307/#341 establecen el contrato/detector de interacción común; #345 conecta el terminal SIGA y #348 los archivadores reales.
- #353 densifica la casa con utilería procedural; #373 hace interactiva la lámpara y #393 el televisor real. #283 sigue siendo un paraguas: se amplía solo mediante objetos concretos de alto valor.
- #368 monta el corcho físico de conceptos en casa y conserva enlaces manuales.
- #314 convierte el trayecto en exterior; #331 agrupa el escaparate y #337 corrige el hook a la fase real `trayecto`. #277 queda como validación visual.
- #310 integra rostros low-poly; #317/#338 diálogo diegético; #315 el asistente-gato 2D inferior derecho. Sus issues asociados son principalmente gates visuales.
- #324 fija clima diario determinista en exteriores.
- #349 crea la primera cama de ambiente continuo de oficina y #372 la conecta al runtime. #119 sigue abierto para ampliar ambientes/mezcla y ahora pertenece a v0.9.

### Sueño y continuidad

- #301 sustituye la salida oculta por progreso onírico por objetivos; #308 hace visible 0/2 → 2/2 y reorienta al gato; #313 corrige el detector físico. #281 queda como gate humano de comprensión.
- #332 limita recompensas oníricas a pistas catalogadas: el sueño no crea hechos nuevos.
- #325/#344 aportan infraestructura poligonal/no ortogonal y familias reutilizables; #279 sigue abierto y no debe expandirse por sí mismo antes de validar la primera noche.
- #292 corrige el salto accidental de cinemáticas y #311 amplía la variación casa → sueño. #280 sigue siendo un gate de **export real**: que las transiciones se vean durante el recorrido, no solo que sus pruebas pasen.

### Vida cotidiana y extras ya integrados

- #83 mantiene la economía base; #84/#85 tienen verticales funcionales y #333 conecta la pérdida de vivienda con `home_storage` sin borrar lo llevado encima.
- #322 integra un primer vertical de trabajillos; #94 sigue abierto para equilibrio y coste sobre descanso/vida doméstica.
- #363/#365 añaden sellos persistentes internos sin recompensas mecánicas directas.
- La portátil doméstica y la emulación GB dejaron de ser solo backlog: #384/#386 aportan Caza Píxeles 98, #385 la Portátil Color 98, #387 el núcleo GB/selector y #391 corrige el reloj/smoke. #388 y #389 añaden Paper Planes 98 y Croc Riders 98. Son **extras opcionales** y no bloquean el segundo playthrough.

## Punto de control actual: segunda alpha post-playtest

El corte de 2026-09-13 toma como baseline de gameplay `main` tras #393 (`0216c7a5de49b24313f6d0c59dfbb1627744c057`). Las notas detalladas viven en [`docs/alpha-playtest-2026-09-13.md`](docs/alpha-playtest-2026-09-13.md) y se empaquetan dentro de los ZIP Linux/Windows.

Recorrido de control:

**Nueva partida → entender el archivo → usar el terminal SIGA → investigar un expediente con relaciones/capas suficientes → firmar/careo → cobrar → recorrer una calle reconocible → casa → dormir con transición visible → completar la primera noche por objetivos → despertar → alquiler/impago → cerrar y recargar conservando estado.**

### Lo que debe validar una persona

- #271 — Continuar/Nueva partida y persistencia real al cerrar/reabrir.
- #272 — archivo, puesto 4-B y primera acción comprensibles sin contexto.
- #273 — controles estándar y nivel de pisadas.
- #280 — cinemáticas/transiciones visibles en export.
- #281 — primera noche completable por objetivos sin salida oculta.
- #113 — mando físico, remapeo y foco/presentación.
- #286 — profundidad real del expediente.
- #287 — que posponer la decisión evita el ritmo precipitado observado.
- #277/#275/#276/#285 — lectura visual del trayecto, rostros, diálogo y asistente.
- #119 — ambiente audible y equilibrado en contexto.

Cualquier fallo reproducible descubierto aquí gana prioridad frente a una expansión opcional.

## Fases

### v0.6.0 · Recorrido completo

La implementación estructural del recorrido está cerrada en lo esencial. Esta milestone ya no debe absorber contenido expansivo: **su salida es el segundo playthrough humano**.

Mantener aquí únicamente trabajo que pueda bloquear o invalidar ese recorrido: plan/coordinación, #280, #286 y #287 mientras sus gates sigan abiertos. Los expedientes adicionales (#91) pasan a v0.9: hacen falta para profundidad/campaña, pero no para demostrar que una jornada completa funciona.

**Salida de fase:** una alpha post-playtest recorrida de principio a fin sin consola ni conocimiento del código, con persistencia real y sin bloqueo funcional.

### v0.7.0 · Cinemáticas y continuidad

El nombre histórico de la milestone era “Todas las cinemáticas”, pero la épica #66 ya está cerrada. El alcance efectivo pasa a ser **continuidad y puesta en escena**:

- #280 debe validarse en export real durante v0.6;
- #177 puede seguir aportando investigación/prototipos originales de dirección cuando resuelvan un problema observado;
- mejoras cinematográficas no deben reabrir infraestructura ya funcional por estética solamente.

#209 ya no pertenece aquí: los incidentes de conducta son simulación cotidiana/social y pasan a v0.9.

### v0.8.0 · Presentación, mando y accesibilidad mínima

Ya integrado:

- tipografía libre por defecto (#172);
- foco A-7 (#174);
- menú global/preferencias (#306);
- remapeo visual teclado/mando (#335);
- rostros 3D (#310), diálogo diegético (#338) y asistente-gato (#315);
- Parte de incidencias para testers (#392).

Pendiente principal:

- validar recorrido con mando físico (#113/#98);
- cerrar superficies concretas de accesibilidad que #98 mantenga abiertas;
- completar traducción del catálogo (#107);
- revisar presentación en resoluciones/exportaciones soportadas;
- continuar audio puntual/visual solo cuando mejore lectura o accesibilidad.

El ambiente continuo #119 pasa a v0.9, donde se evalúa como parte del ciclo oficina → calle → casa → sueño.

### v0.9.0 · Vida cotidiana, contenido y ambiente

La economía base ya no es un bloqueo. Esta fase reúne lo que hace que vivir varias jornadas tenga peso y variedad:

- vivienda/alquiler/impago — #84/#85;
- compras e imprevistos — #93/#96;
- trabajillos — #94, con vertical ya integrado por #322 y equilibrio aún abierto;
- gato transversal — #92;
- sueño alimentado por lo conocido — #79/#87/#89/#97;
- rediseño espacial onírico — #279 solo en cortes que ayuden a legibilidad/interacción;
- interacción ambiental — #283 por objetos concretos;
- ambiente sonoro — #119, con oficina ya cableada y otros espacios/mezcla pendientes;
- expedientes adicionales — #91, para sostener una campaña más larga sin convertirlos en gate de la alpha v0.6;
- incidentes sociales/consecuencias ambientales — #209 y derivados.

Los minijuegos y la portátil ya integrados pueden probarse aquí como contenido opcional, pero no definen la salida de fase.

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

- expansiones de colecciones/minijuegos que no estén ya integradas y no resuelvan un hallazgo;
- logros externos (#114);
- familias oníricas expansivas (#284) una vez validada la primera noche;
- arte/ambientación que no resuelva un hallazgo concreto del playtest;
- expansiones de cinemáticas o simulación que no cambien el punto de control actual.

La portátil/emulación GB ya integrada no se vuelve a tratar como trabajo base: cualquier ampliación futura debe justificar su prioridad de forma independiente.

## Ajuste de milestones — 2026-09-13

Para que GitHub y este roadmap vuelvan a decir lo mismo se han recolocado tres issues abiertos:

- #91: **v0.6 → v0.9**, porque ampliar el catálogo no bloquea el segundo recorrido;
- #209: **v0.7 → v0.9**, porque es simulación social/cotidiana, no infraestructura cinematográfica;
- #119: **v0.8 → v0.9**, porque el ambiente se valida como parte del ciclo diario y ya tiene un primer vertical de oficina integrado.

No se cierran milestones por una CI verde. Se cierran cuando su criterio de salida ha sido validado y existe un release/corte correspondiente.

## Regla para mover trabajo entre fases

1. Un bloqueo observado en #9 gana frente a expansión opcional.
2. Una mejora P1 pequeña puede adelantarse si mejora directamente el siguiente playthrough.
3. Los paraguas #279/#282/#283 se ejecutan por verticales pequeños.
4. Un issue no “sube” por tener código interesante: debe eliminar un bloqueo, una regresión o una dependencia mínima.
5. Una pieza técnicamente integrada puede seguir abierta únicamente por validación humana; eso no autoriza reescribirla sin un fallo reproducible nuevo.
6. `main` manda sobre cuerpos históricos de issues, ramas antiguas o comentarios anteriores.
7. Un extra ya integrado no se convierte por ello en requisito del recorrido principal.

## Milestones, Projects y releases

- **Milestone** = versión comprometida; se cierra con su release/corte validado.
- **Projects** = estado operativo del trabajo, no fuente única de prioridad.
- **Plan maestro #181** = orden vigente y punto de control.
- **Release/alpha** = artefacto publicado con notas que distinguen claramente qué se probó automáticamente y qué se validó de forma humana.

Si dos superficies discrepan, corrige la documentación; no mantengas dos planes paralelos.
