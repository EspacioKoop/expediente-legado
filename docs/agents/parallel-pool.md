# Pool paralelo de agentes

Contrato específico del dispatcher de `EspacioKoop/expediente-legado`. La infraestructura que proporciona capacidad al pool se documenta fuera del repo público.

## Cola

`agent-pool.yml` reúne issues con `agent:auto`, `agent:pool`, `agent:qwen` o `agent:gemini`, los deduplica y asigna trabajo solo a workers compatibles disponibles.

- `agent:auto` y `agent:pool` permiten selección automática;
- `agent:qwen` y `agent:gemini` fijan la familia de executor;
- un mismo issue no puede ejecutarse dos veces a la vez;
- una tarea no debe empezar si sus rutas ya están reservadas por otro trabajo.

## Plan delegado

El pool es nivel 3: implementa, no planifica. El nivel 2 deja un plan con los marcadores en líneas propias:

```text
AGENT_PLAN_BEGIN
{"files":["godot/guion/ejemplo.gd"],"goal":"Objetivo concreto del corte"}
AGENT_PLAN_END
```

El worker usa el plan válido más reciente de una cuenta de confianza. Si falta un plan seguro, el issue vuelve a planificación o a `agent:needs-human`.

Una tarea del worker modifica un solo fichero por defecto. Los trabajos mayores deben dividirse antes de entrar al executor.

## Reserva y aislamiento

Antes de implementar, el workflow:

1. comprueba que el issue no está ya reservado;
2. reserva el issue y las rutas del plan;
3. compila TaskPacket + prompt mínimo;
4. crea una rama aislada;
5. ejecuta al worker sin permisos de integración.

Después de implementar, un guard compara el diff con el CLAIM. Toda ruta no autorizada se restaura antes de preflight, memoria, commit o publicación.

## Replan

Si el worker necesita rutas fuera del CLAIM:

- el intento se descarta de forma segura;
- se registra el desvío;
- el issue vuelve a planificación con ese dato;
- los reintentos están acotados;
- al agotarse, se usa `agent:needs-human`.

El replan corrige un alcance insuficiente; nunca permite saltarse una reserva existente.

## Fallos de worker

Un error de proveedor, timeout o ejecución sin diff útil puede rotar a otro worker compatible. Un preflight fallido sobre un diff real no se trata como simple fallo de proveedor: requiere revisar el cambio generado.

La política concreta de capacidad, cuotas, circuit breakers y backends no forma parte de esta documentación pública.

## Handoff y revisión

El worker entrega el contrato de [agent-protocol.md](../agent-protocol.md). Un ResultPacket ausente o inválido no convierte el trabajo en válido; el workflow puede recuperar un handoff degradado desde TaskPacket + diff para que reviewer/dispatcher no pierdan contexto.

La revisión independiente ocurre antes de considerar un draft listo. Ninguna revisión automática concede permiso de merge.

## CI

El worker publica un PR draft y dispara el CI canónico. Las reparaciones automáticas están acotadas y no convierten el pool en autoridad de integración.

## Visualización externa

- El pool puede alimentar tableros externos con un *snapshot* sanitizado de estado.
- El snapshot debe contener solo metadatos seguros: número de issue/PR, fase, cola, resultado reciente, enlace público de GitHub y timestamps.
- No debe incluir prompts completos, secretos, rutas locales, hostnames privados, IPs, logs crudos ni memoria privada.
- GitHub Issues/PRs siguen siendo la fuente visible; el tablero es observabilidad, no autoridad.
- Un estado en tablero no sustituye los labels del repositorio: `agent:working`, `agent:pr-open`, `agent:needs-human`, `revision:*` y CI siguen mandando.

## Autopilot manual

`agent-autopilot.yml` se conserva como entrada manual para un issue concreto. La cola automática común vive en el dispatcher; no hay una segunda cola horaria separada.
