# Agentes autónomos

Este documento describe **solo el contrato de agentes de este repositorio**. La topología doméstica, inventario de proveedores, routing privado, timers locales y runbooks reutilizables se mantienen fuera del repo público.

## Entradas de trabajo

La cola reconoce estas labels:

- `agent:auto`: trabajo automático con cualquier worker compatible disponible;
- `agent:pool`: alias compatible de la misma cola;
- `agent:qwen`: exige la familia Qwen;
- `agent:gemini`: exige Gemini;
- `agent:decompose`: requiere planificación de nivel 2 antes de implementar;
- `agent:working`: ejecución activa;
- `agent:pr-open`: ya existe un draft generado;
- `agent:needs-human`: no hay un corte automático seguro o se agotó la recuperación.

El workflow manual `agent-autopilot.yml` permite ejecutar un issue concreto sin convertirlo en una segunda cola.

## Flujo

1. El nivel 2 inspecciona issue, repo y Normas Platino y materializa un `AGENT_PLAN` acotado.
2. El dispatcher elige un worker compatible y evita duplicar un issue ya reservado.
3. El worker recibe un `TaskPacket` y un prompt compilado; no vuelve a planificar el proyecto.
4. Se normaliza el diff contra el CLAIM y se restauran cambios fuera de alcance.
5. El worker entrega un `ResultPacket`; si omite el formato, el workflow puede recuperar un sobre degradado solo con hechos autoritativos, sin marcar el contrato como válido.
6. Se ejecuta preflight proporcional y revisión independiente.
7. Se publica un PR **draft** y se ejecuta CI.
8. La integración sigue siendo humana.

## Plan delegado

El formato canónico está documentado en [agents/parallel-pool.md](agents/parallel-pool.md). Por defecto una tarea automática debe ser pequeña y explícita; el nivel 2 divide trabajos mayores antes de entregarlos a un worker final.

## Protocolo B2B

El contrato planner → worker → reviewer está en [agent-protocol.md](agent-protocol.md).

Propiedades obligatorias:

- versión explícita;
- SHA base;
- rutas autorizadas;
- objetivo y criterios de aceptación;
- separación entre hechos, supuestos, verificaciones e incógnitas;
- evidencia y siguiente acción;
- ausencia de secretos y razonamiento interno.

Un error de formato no autoriza a publicar ni integrar: CLAIM, diff, preflight, revisión y CI siguen siendo las barreras técnicas.

## Autoridad de contexto

La prioridad es:

1. código y tests actuales;
2. issue y plan actual;
3. #181, #1713 y Normas Platino;
4. contexto auxiliar seleccionado por las herramientas del repo.

Memoria, wiki, métricas o respuestas de modelos pueden orientar; nunca sustituyen el estado actual del código, el issue ni CI.

## Frontera de proveedores

El repositorio contiene adaptadores y workflows para workers configurables, pero **no documenta aquí**:

- red o máquinas que prestan inferencia;
- endpoints privados;
- inventario real de cuentas/proveedores;
- tiers y cuotas personales;
- timers o fallback doméstico;
- runbooks de alta/baja de proveedores.

La interfaz necesaria para Actions es el propio workflow y sus inputs/variables; el despliegue que hay detrás no forma parte del contrato público del juego.

## Seguridad y límites

- ningún modelo recibe credenciales de push;
- los workers no hacen commit, push, PR ni merge por su cuenta;
- el workflow restaura cambios fuera del CLAIM;
- un draft no equivale a integración;
- CI verde no sustituye revisión ni validación humana;
- no se automatizan gates visuales, mando físico ni decisiones narrativas;
- no hay auto-merge.

La guía normativa general sigue en [AGENTS.md](../AGENTS.md) y [CONTRIBUTING.md](../CONTRIBUTING.md).
