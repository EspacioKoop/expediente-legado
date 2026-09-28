# Pool paralelo de agentes

El pool es la cola operativa común de agentes y aporta concurrencia horizontal de hasta seis workers. El workflow `agent-autopilot.yml` queda como entrada manual para un issue concreto.

## Modelo operativo

`agent-pool.yml` reúne issues etiquetados con `agent:auto`, `agent:pool`, `agent:qwen` o `agent:gemini`, los deduplica y asigna, como máximo, una tarea por slot configurado. `agent:pool` queda como alias compatible; puede coexistir con `agent:auto` sin duplicar la tarea.

Los labels `agent:qwen` y `agent:gemini` fuerzan proveedor. Para `agent:auto`/`agent:pool`, Kev puede indicar una preferencia blanda entre los workers disponibles; si el slot preferido no está libre, el dispatcher usa otro disponible.

Slots:

- `qwen-primary`;
- `gemini`;
- `qwen-fallback-1` ... `qwen-fallback-4`.

Cada slot cuenta como capacidad 1 por tanda. Asi un endpoint con limites ajustados no recibe varias tareas simultaneas por defecto.

## Niveles y plan delegado

El pool es el **nivel 3**. Por encima están el coordinador (nivel 1) y las sesiones asistidas de Claude/ChatGPT (nivel 2). Planificar es trabajo del nivel 2: el planificador barato del pool apenas cumplía el contrato de plan (#1636).

Para delegar un issue, el nivel 2 deja el plan en el cuerpo o en un comentario, con los marcadores en líneas propias. Se pega **sin** la valla de código del ejemplo: un marcador dentro de un bloque de código se trata como documentación, no como encargo.

```text
AGENT_PLAN_BEGIN
{"files": ["godot/guion/ejemplo.gd", "godot/pruebas/pruebas_ejemplo.gd"], "goal": "Objetivo concreto del corte"}
AGENT_PLAN_END
```

Después añade `agent:auto`. El worker (`scripts/agent_delegated_plan.py`) toma el plan válido más reciente de cuentas `OWNER`/`MEMBER`/`COLLABORATOR` que no sean bots, **omite el planificador** y sigue el circuito normal: validación de rutas, CLAIM en #182, implementación, guard, preflight y PR draft. Para corregir el plan basta un comentario nuevo. Si el plan se queda corto de rutas, el replan acaba en `agent:needs-human` y el nivel 2 lo amplía.

Sin plan delegado, el pool planifica como siempre.

## Aislamiento

`agent-worker.yml` usa `concurrency` por numero de issue. Dos issues distintos pueden correr a la vez, pero dos ejecuciones del pool no pueden trabajar simultaneamente sobre el mismo issue.

El lock por issue no sustituye #182. Despues de planificar, cada worker publica un `CLAIM` con rutas concretas y vuelve a leer todas las reservas. Si detecta solape, libera su CLAIM y marca el issue para revision.

## Activacion

1. Configura al menos un proveedor: `QWEN_API_KEY`, `GEMINI_API_KEY`, o un `QWEN_FALLBACK_N_API_KEY` acompañado de `QWEN_FALLBACK_N_BASE_URL`.
2. Añade `agent:auto` o `agent:pool`; usa `agent:qwen` / `agent:gemini` cuando el proveedor deba ser obligatorio.
3. El evento de etiqueta lanza una tanda; además hay un barrido cada 15 minutos.
4. El dispatcher usa hasta seis workers disponibles, deduplicando cada issue.

## Replan ante salidas del CLAIM

Después de la implementación, el worker ejecuta un guard provider-agnostic. Si Qwen o Gemini modifican rutas no incluidas en el plan/CLAIM:

1. restaura esas rutas antes de preflight, memoria, commit o push;
2. libera la reserva del intento descartado;
3. publica `AGENT_POOL_REPLAN` con las rutas observadas;
4. reejecuta el mismo issue/proveedor para que el planner amplíe el corte y vuelva a comprobar #182.

Se permiten como máximo **dos replans** por issue. Si el modelo vuelve a salir del alcance, el issue pasa a `agent:needs-human`. Este mecanismo recupera errores de planificación; no autoriza a saltarse una reserva existente.

## CI

El worker abre un PR draft y ejecuta `ci.yml` mediante `workflow_dispatch`, igual que el autopilot existente. Se conserva este disparo deliberadamente: un PR creado por un workflow con `GITHUB_TOKEN` puede dejar los workflows de `pull_request` esperando aprobacion, mientras que `workflow_dispatch` evita depender de esa aprobacion.

La rama conserva el formato `agent/qwen-ISSUE-RUN` o `agent/gemini-ISSUE-RUN`, por lo que `agent-ci-repair.yml` puede seguir registrando `PR_READY` y reparando CI.

## Contexto y memoria

Cada worker conserva la jerarquia vigente: repositorio/issue/#181/#182/Normas Platino > contexto seleccionado de wiki > Deno KV > CI brain SQLite/Turso.

El context packer limita la wiki antes de planificar y se vuelve a ejecutar con las rutas reservadas antes de implementar.

## Autopilot manual

La migración de cola ya está completada: `agent:auto` entra por este dispatcher. `agent-autopilot.yml` no escucha labels ni hace polling horario; se conserva para `workflow_dispatch` manual, donde se indica explícitamente el issue y puede elegirse `provider=auto`, Qwen o Gemini.
