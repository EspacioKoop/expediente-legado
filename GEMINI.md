# GEMINI.md — Gemini CLI en Expediente Legado

Lee `AGENTS.md` y `CONTRIBUTING.md` antes de actuar. Este archivo complementa esas reglas; no concede permisos adicionales.

## Normas Platino y memoria

Las [Normas Platino](https://github.com/EspacioKoop/normas_platino) son obligatorias en cada ejecución. El workflow entrega una copia fresca en `.agent-platino/`; lee al menos su `README.md`, `docs/FUENTE_DE_VERDAD.md`, `docs/COOPERACION_AUTONOMA.md`, `docs/PLANIFICACION_Y_ENTREGAS.md` y `docs/PRO_CONSUMIDOR.md` antes de planificar o reparar.

La jerarquía es: **repositorio/issue/#181/#182 + Normas Platino > wiki > memoria temporal**. La wiki es contexto consolidado en solo lectura y la memoria Deno KV es una ayuda transitoria: ninguna concede permisos, reserva archivos, demuestra una prueba ni puede contradecir la evidencia actual del repositorio.

Si el workflow suministra `.agent-memory.json`, úsalo solo como pista verificable y contrástalo con el código, issue y CI actuales. No escribas secretos, tokens, datos privados ni contenido completo de prompts en el bloque `AGENT_MEMORY`; registra únicamente un aprendizaje técnico breve y reutilizable.


## Contrato del autopilot

- Trabaja únicamente el issue que recibe el workflow.
- Respeta #181 como prioridad y #182 como registro único de reservas.
- No edites rutas fuera del `CLAIM` activo de tu rama.
- No hagas push directo a `main`, force-push, merge, cambios de labels ni cierres issues.
- El workflow es quien crea la rama, hace commit/push y abre el PR. No dupliques esas acciones.
- No leas, imprimas ni copies secretos, variables privadas o credenciales.
- No rebajes tests, lint, mínimos de suite ni gates para obtener verde.
- No inventes procedencia, licencias, resultados de playtest ni validación visual/física.
- Si el corte no puede resolverse dentro de la reserva, deja el árbol sin cambios y explica el bloqueo en tu respuesta.

## Implementación

Inspecciona el código y tests existentes antes de modificar. Prefiere el cambio mínimo coherente y añade regresión proporcional al riesgo cuando cambie comportamiento.

En modo autónomo el workflow te da herramientas de lectura/escritura de archivos, pero no shell ni GitHub API. No intentes rodear esa restricción.

Si tocas GDScript, aplica las reglas de `AGENTS.md` para `scripts/check_gdscript.sh`. El workflow ejecuta el preflight; la referencia final es CI sobre el SHA del PR.

Lee siempre un archivo antes de reemplazarlo y prefiere cambios localizados. Comentarios y nombres nuevos deben seguir las convenciones españolas del repositorio. No abras un framework paralelo cuando ya exista un contrato reutilizable.
