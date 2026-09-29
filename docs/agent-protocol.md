# Protocolo B2B de agentes · v1

El pool mantiene GitHub/CI como fuente autoritativa y usa mensajes estructurados para
evitar que cada capa vuelva a reinterpretar la tarea desde cero.

## Sobres admitidos

Todo mensaje entre capas debe llevar explícitamente 'schema: 1' y un 'message_type' de esta lista:
'TASK', 'CLAIM', 'EVIDENCE', 'BLOCKER', 'QUESTION', 'RESULT', 'REVIEW' o
'HANDOFF'. El texto libre puede acompañar al sobre, pero no sustituye sus campos
cuando el consumidor espera un contrato.

## TaskPacket

Antes de ejecutar el worker final, 'scripts/agent_protocol.py task' materializa
'.agent-task-packet.json'. Contiene identificador estable de tarea, SHA base,
versión de Normas Platino, asignación provider/worker, prioridad de fuentes, capas
de contexto, rutas permitidas, presupuesto de scope, criterios de aceptación
extraíbles del issue y condiciones de abortado.

Las capas son:

- **L0:** contrato y plan. Siempre se leen.
- **L1:** issue/contexto seleccionado/Normas Platino. Se consulta para implementar.
- **L2:** wiki completa y memorias. Solo cuando L0+L1 no bastan.

El prompt final se compila desde el TaskPacket. Qwen y Gemini reciben adaptadores de
edición distintos sin cambiar el contrato canónico; además se añaden restricciones de
dominio derivadas de las rutas (por ejemplo Godot 4.x, no rebajar assertions de tests
o no registrar secretos en backend/infra).

## ResultPacket

El worker termina con 'AGENT_RESULT_BEGIN' / 'AGENT_RESULT_END' y JSON con:
'task_id', 'base_sha', estado, resumen, hechos, supuestos, verificaciones,
incógnitas, cambios, evidencia, pendientes y siguiente acción.

Hechos y verificaciones deben ser observables. Las inferencias van a 'assumptions';
lo que siga abierto va a 'unknowns' o 'unresolved'.

Durante el rollout v1 un ResultPacket inválido **no bloquea por sí solo** la PR:
se registra como pérdida de handoff para no degradar capacidad por una migración de
formato. El CLAIM, el preflight, el diff y CI siguen siendo gates reales.

## Métricas

'agent_protocol.py result' calcula dos señales:

- 'contract_coverage_pct': presencia de campos obligatorios del ResultPacket.
- 'handoff_loss_proxy_pct': proxy de pérdida entre TaskPacket y resultado. Comprueba
  task/base SHA, cobertura de rutas cambiadas, evidencia, siguiente acción y cobertura
  del contrato.

No son una evaluación de calidad del código. Sirven para detectar workers/adaptadores
que pierden contexto o producen handoffs incompletos.

El dispatcher agrega además telemetría histórica desde metadatos compactos de PRs
generados por el pool: promedio de handoff loss, tasa de ResultPacket válido, tasa de
reviews con findings y un `rework_rate_pct` proxy. Este último se activa cuando el
reviewer reportó findings o el PR necesitó más de un commit; por tanto no debe
interpretarse como una medida definitiva de calidad.

La ventana usa como máximo los 50 PRs más recientes por worker. En v1 estas señales se
adjuntan al inventario del dispatcher y se registran, pero **no modifican el score de
routing**: primero deben acumular evidencia suficiente y demostrar estabilidad.

## Coordinación

Los leases de Deno KV y el registro central de reservas de rutas siguen siendo la
autoridad de exclusión. El protocolo B2B describe intención/evidencia; no reemplaza
locks técnicos. Ante contradicción, manda el estado actual del repositorio/CI, luego
issue y fuentes canónicas del proyecto, y después memorias auxiliares.
