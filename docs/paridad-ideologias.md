# Paridad de ideologías: legado → Godot

## Estado posterior al corte — 2026-09-22

La auditoría histórica sigue siendo la referencia para saber qué se recuperó del legado. La expansión transversal ya tiene varios consumidores reales: doctrinas heredadas en Juicio 3D (#1115), huella ideológica en cierres de expediente (#1124) y exposición diferenciada mediante prensa/radio (#1148).

La épica #915 y sus sub-issues #919–#925 continúan siendo el contrato de evolución. Estos avances **generalizan** el legado; no convierten exposición mediática en elección ni establecen un alignment único.

Seguimiento de #918 y base de #915/#919.

## Alcance

Esta auditoría trata **ideología como comportamiento y estado**, no solo como apariciones de la palabra `ideologia`.

Fuentes revisadas:

- `backend/src/main/resources/static/js/prometeo-logic.js`;
- `backend/src/main/resources/static/js/prometeo-ui.js`;
- `backend/src/test/js/prometeo-logic.test.js`;
- `godot/guion/prometeo.gd`;
- `godot/guion/historias.gd`;
- `godot/guion/combate.gd`;
- `godot/datos/prometeo.json`;
- pruebas Godot de Prometeo/historias/combate;
- #45, #537, #915 y sus sub-issues.

La regla de migración es la misma que en la paridad general del proyecto: **que algo no tenga todavía superficie Godot no significa que se haya descartado**.

## Vocabulario canónico

Los cuatro IDs heredados siguen siendo claves técnicas internas:

- `comunismo`;
- `socialdemocrata`;
- `centrista`;
- `neoliberal`.

No constituyen una clase del personaje ni deben exponerse necesariamente como etiquetas de UI.

Desde #919 se distinguen tres canales:

1. **elección**: algo que el jugador hace o defiende explícitamente;
2. **exposición**: algo que lee, ve o escucha;
3. **lectura social**: interpretación que hace un actor sobre un evento observable.

Ningún canal sustituye a otro.

## Matriz de paridad

| Concepto | Fuente legado | Equivalente Godot actual | Estado | Decisión / destino |
| --- | --- | --- | --- | --- |
| Cuatro ejes políticos | `prometeo-ui.js`, `prometeo-logic.js` | `Prometeo.EJES` | **Portado** | Se conservan como IDs internos. #919 los reutiliza sin convertirlos en `alignment`. |
| Ocho historias de Tarot | `HISTORIAS_CARTAS` | `prometeo.json` + `Historias` | **Portado** | Siguen siendo el primer corpus de decisiones. |
| Una salida por eje en cada historia | UI legado | `Historias.vista()` + catálogo | **Portado** | Se conserva. No obliga a que todas las decisiones futuras tengan cuatro opciones. |
| 2 opciones útiles / 2 de confusión por historia | `UTILIDAD_CARTAS` | `Prometeo.UTILIDAD_CARTAS` | **Portado** | Se conserva como contrato situacional. |
| Cada eje útil exactamente en 4/8 historias | test Vitest #45 | prueba Godot | **Portado y probado** | Regla anti-moralizante del corpus heredado. |
| Elecciones políticas por vuelta | `historiasCartas` + reset | `historias_cartas` + `reiniciar_vuelta()` | **Portado** | #919 añade un canal general para decisiones fuera de Tarot, sin duplicar las historias. |
| Recuento por eje | `contarPuntosPorEje()` | `Prometeo.puntos_por_eje()` | **Portado** | Se mantiene para compatibilidad. #919 añade recuento sobre la vista transversal. |
| Eje ganador | `calcularEjeGanador()` | `Prometeo.eje_ganador()` | **Portado con deuda** | El empate cae por orden de enum. #925 debe sustituir esa lectura en el cierre transversal. |
| Empate/pluralidad real | no existía | `Prometeo.ejes_dominantes()` desde #919 | **Generalizado** | Devuelve todos los ejes empatados; no cambia todavía el final legado. |
| Secuela útil vs. confusión | UI/logic legado | `Historias._secuela()` | **Portado** | Sigue afectando orientación de la investigación, no la verdad de los hechos. |
| Puntos políticos como equipamiento | #45 / lógica legado | `Historias.cargas()` | **Portado** | Sigue limitado a historias hasta que #921 migre consumidores al contrato común. |
| Asamblea | #45 | `Combate` | **Portado** | Empate con presión favorable; identidad funcional a conservar en #921. |
| Mesa de diálogo | #45 | `Combate` | **Portado** | Neutraliza la ronda; identidad funcional a conservar en #921. |
| Comisión de seguimiento | #45 | `Combate` | **Portado** | Revela la próxima jugada; identidad funcional a conservar en #921. |
| Externalizar | #45 | `Combate` | **Portado** | Aumenta lo que está en juego; identidad funcional a conservar en #921. |
| Uso de doctrinas en Juicio por Combate 3D | no existía en el corte web original | rituales 3D actuales sin doctrina ideológica general | **Pendiente / expansión** | #921. Debe usar tags comunes, no matriz manual ideología×Tarot×mito. |
| Final político visible | `LINEAS_FINAL_POLITICO` / modal web | Godot conserva `final_politico_mostrado` y cálculo de eje | **Parcial** | #925 debe recuperar presentación y generalizarla a trayectoria/pluralidad. |
| `disciplina-de-partido` | lógica + catálogo legado | definición en `prometeo.json` | **Parcial** | Auditar/conectar concesión en #925. No premiar una ideología concreta. |
| `instinto-de-archivo` | lógica + catálogo legado | definición en `prometeo.json` | **Parcial** | Preservar el concepto: utilidad contextual sin consistencia ideológica. |
| `metodo-del-descarte` y patrones similares | lógica + catálogo legado | definiciones de catálogo | **Parcial** | #925 decide qué patrones siguen teniendo sentido con más decisiones. |
| Reset político de una nueva vida laboral | `reiniciarEstadoPerRunEnEstado()` | `Prometeo.reiniciar_vuelta()` | **Portado** | #919 amplía el reset a elecciones nuevas, exposición activa y lecturas sociales. |
| Exposición mediática separada de elección | no existía como contrato común | prensa/medios existen como verticales separadas | **Nuevo contrato** | #919/#922. Leer una fuente nunca vota por el jugador. |
| Reacción de NPCs a decisiones conocidas | no existía como sistema común | infraestructura de diálogo/NPC ya existe | **Pendiente** | #920 consume eventos observables; no telepatía sobre un contador. |
| Ideología en expedientes fuera de Tarot | no existía como modelo general | decisiones de expediente sin contrato ideológico común | **Pendiente** | #924. Los hechos permanecen invariantes; cambia qué se hace con ellos. |
| Cuatro marcos de prensa | concepto de #537, derivado de #45 | ecosistema de prensa Godot | **Parcial / vertical propio** | #922 conecta exposición y hechos compartidos sin convertir una cabecera en verdad canónica. |
| Ideología en sueño | no existía como sistema transversal | gramática simbólica/mitologías ya existen | **Pendiente** | #923: modificar reglas/relaciones, no habitaciones con consignas. |
| Historial de trayectoria entre vueltas | logros y flags dispersos | memoria/meta-progresión ya existe para otros sistemas | **Pendiente** | #925 decide qué resumen sobrevive sin arrastrar un alignment permanente. |

## Qué recuperamos literalmente y qué recuperamos como concepto

### Se mantiene como regla funcional

- los cuatro IDs internos;
- las ocho historias;
- la matriz de utilidad situacional;
- las elecciones per-run;
- las cuatro doctrinas de combate;
- el principio «la run política es parte del equipamiento»;
- el reset de una nueva vida laboral;
- los patrones/logros que describen conducta, sujetos a reconexión en #925.

### Se generaliza

- `historias_cartas` deja de ser la única forma posible de decisión ideológica;
- el tally deja de ser la única lectura posible de la trayectoria;
- el combate ideológico deja de estar limitado al duelo burocrático;
- la política deja de aparecer únicamente cuando se encuentra una carta;
- medios, diálogo y sueño pasan a ser consumidores del mismo contrato, sin copiar estado.

### No se arrastra sin revisión

- el desempate «gana el primer eje del array»;
- un final reducido a una única etiqueta cuando haya pluralidad real;
- cualquier supuesto de que consumir un medio equivale a adoptar su marco;
- una matriz rígida de cuatro respuestas en cada decisión futura;
- bonuses pasivos globales por pertenecer a un eje.

## Contrato de compatibilidad introducido por #919

El primer corte transversal no migra destructivamente el estado antiguo.

`Prometeo.elecciones_ideologicas(estado)` construye una vista común:

```text
historias_cartas["la-luna"] = "centrista"
    ↓
{id: "tarot:la-luna", fuente: "tarot", eje: "centrista", ...}

elecciones_ideologicas_run[]
    ↓
eventos nuevos de expedientes/otras verticales
```

Las historias siguen siendo fuente de verdad de sí mismas. El adaptador **no escribe de vuelta** en `historias_cartas` ni modifica todavía cargas, finales o persistencia existente.

Esto permite migrar vertical por vertical:

1. #924 registra una decisión nueva;
2. #920 consume el evento en diálogo;
3. #921 decide cuándo las cargas de combate pasan a leer el contrato común;
4. #922 registra exposición separada;
5. #923 consume elección y exposición con semántica distinta;
6. #925 sustituye la lectura final heredada sin romper antes el recorrido actual.

## Reset y persistencia

Política inicial:

| Canal | Duración |
| --- | --- |
| `historias_cartas` | vuelta, como hasta ahora |
| `elecciones_ideologicas_run` | vuelta |
| `exposicion_ideologica_hoy` | jornada; también se limpia al reiniciar vuelta |
| `lecturas_sociales` | vuelta por defecto |
| historial/meta-logros | solo cuando #925 defina qué merece persistir |

No se introduce todavía una etiqueta política permanente entre vidas laborales.

## Neutralidad sistémica que deben preservar los consumidores

La capa permite representar consecuencias y desacuerdo, pero sus reglas no necesitan elegir una postura universalmente correcta.

Por tanto:

- la utilidad sigue siendo contextual;
- hechos y pistas del expediente no dependen del eje;
- exposición no concede puntos ni doctrina;
- un NPC solo reacciona a hechos que pueda conocer;
- combate usa técnicas situacionales, no «debilidades ideológicas» de enemigos;
- empate y pluralidad son estados representables;
- los finales resumen acciones concretas antes de sintetizar patrones.

## Issues destino

- #919 — contrato común y migración progresiva;
- #920 — diálogo, relaciones y lectura social;
- #921 — combate y doctrinas;
- #922 — medios/cultura y exposición;
- #923 — sueño y gramática simbólica;
- #924 — decisiones de expediente;
- #925 — finales, logros y lectura de trayectoria.

## Criterio de cierre de #918

Con esta matriz, cada concepto ideológico detectado en el legado queda clasificado como:

- portado;
- parcial;
- generalizado;
- pendiente con issue destino.

No queda ningún comportamiento relevante identificado que deba considerarse descartado por omisión.
