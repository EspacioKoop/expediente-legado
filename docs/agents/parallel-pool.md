# Pool paralelo de agentes

El pool anade concurrencia horizontal sin sustituir todavia al autopilot legado.

## Modelo operativo

La etiqueta `agent:pool` mete un issue en la cola paralela. **No debe coexistir con `agent:auto`** durante la transicion: el selector ignora explicitamente cualquier issue que tenga ambas etiquetas.

`agent-pool.yml` reune hasta seis issues elegibles y asigna, como maximo, una tarea por slot configurado:

- `qwen-primary`;
- `gemini`;
- `qwen-fallback-1` ... `qwen-fallback-4`.

Cada slot cuenta como capacidad 1 por tanda. Asi un endpoint con limites ajustados no recibe varias tareas simultaneas por defecto.

## Aislamiento

`agent-worker.yml` usa `concurrency` por numero de issue. Dos issues distintos pueden correr a la vez, pero dos ejecuciones del pool no pueden trabajar simultaneamente sobre el mismo issue.

El lock por issue no sustituye #182. Despues de planificar, cada worker publica un `CLAIM` con rutas concretas y vuelve a leer todas las reservas. Si detecta solape, libera su CLAIM y marca el issue para revision.

## Activacion

1. Configura al menos un proveedor: `QWEN_API_KEY`, `GEMINI_API_KEY`, o un `QWEN_FALLBACK_N_API_KEY` acompanado de `QWEN_FALLBACK_N_BASE_URL`.
2. Anade `agent:pool` al issue.
3. El evento de etiqueta lanza una tanda; ademas hay un barrido cada 15 minutos.
4. El dispatcher usa hasta seis workers disponibles.

Las etiquetas `agent:qwen` y `agent:gemini` fuerzan proveedor, no un slot concreto. Sin ellas, el selector usa el siguiente slot libre en orden determinista.

## CI

El worker abre un PR draft y ejecuta `ci.yml` mediante `workflow_dispatch`, igual que el autopilot existente. Se conserva este disparo deliberadamente: un PR creado por un workflow con `GITHUB_TOKEN` puede dejar los workflows de `pull_request` esperando aprobacion, mientras que `workflow_dispatch` evita depender de esa aprobacion.

La rama conserva el formato `agent/qwen-ISSUE-RUN` o `agent/gemini-ISSUE-RUN`, por lo que `agent-ci-repair.yml` puede seguir registrando `PR_READY` y reparando CI.

## Contexto y memoria

Cada worker conserva la jerarquia vigente: repositorio/issue/#181/#182/Normas Platino > contexto seleccionado de wiki > Deno KV > CI brain SQLite/Turso.

El context packer limita la wiki antes de planificar y se vuelve a ejecutar con las rutas reservadas antes de implementar.

## Migracion pendiente

Este corte no modifica `agent-autopilot.yml`. El siguiente paso, tras estabilizar este pool, es convertir `agent:auto` en alias del dispatcher o retirar el carril global `concurrency: agent-autopilot`. Hasta entonces, usa `agent:pool` exclusivamente para la cola paralela.
