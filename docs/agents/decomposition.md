# Descomposición automática de issues

La descomposición separa la **planificación de tamaño** de la implementación. Sirve para issues que no caben de forma segura en un único CLAIM del pool.

## Activación

Añade `agent:decompose` al issue. El workflow `agent-decompose.yml` retira temporalmente los labels de cola para impedir que el dispatcher ejecute el issue padre a la vez.

También puede lanzarse manualmente con `workflow_dispatch` indicando el número del issue.

## Presupuesto del planner

La fase usa un único planner de solo lectura:

- Qwen cuando está disponible; Gemini solo si Qwen no lo está;
- máximo 8 turnos;
- timeout de 5 minutos en la llamada al modelo;
- sin herramientas de escritura;
- sin retry automático.

Una salida inválida no crea una segunda ronda de modelo: el padre pasa a `agent:needs-human`.

## Contrato

El planner devuelve `AGENT_DECOMPOSE_BEGIN/END`. Si el issue cabe en un único corte de hasta **8 rutas**, vuelve directamente a la cola original.

Si no cabe, puede producir entre **2 y 6 subtareas**. Cada subtarea incluye título, objetivo, rutas concretas y dependencias hacia índices anteriores. Las rutas:

- no pueden ser absolutas;
- no admiten `..`, globs ni `.github/` / `.agent-*`;
- se deduplican;
- si dos cortes comparten una ruta, el posterior debe depender explícitamente del anterior.

El validador vive en `scripts/agent_decompose.py`; el modelo no decide qué salida se acepta.

## Subissues y dependencias

Las subtareas sin dependencias entran inmediatamente en la cola del proveedor heredado (`agent:auto`, `agent:qwen` o `agent:gemini`). Las que dependen de cortes anteriores reciben `agent:blocked`.

`agent-dependency-unblock.yml` revisa los bloqueados cuando se cierra un issue y además dos veces por hora. Solo retira `agent:blocked` cuando **todas** las dependencias declaradas están cerradas.

El issue padre permanece abierto y recibe un comentario `AGENT_DECOMPOSED` con los subissues creados.

## Fallos parciales

La creación es fail-safe: si el workflow falla después de haber creado una parte de los subissues, esos hijos parciales se cierran automáticamente antes de marcar el padre como `agent:needs-human`.

La descomposición no sustituye #182. Cada subissue sigue pasando por planner/plan delegado, CLAIM, guard de rutas, preflight, reviewer acotado y CI antes de producir un PR.
