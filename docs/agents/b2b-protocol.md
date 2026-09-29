# Protocolo B2B entre agentes

Este corte de #1866 hace explícito el handoff entre planificador, implementador,
reviewer y publicador sin sustituir los locks existentes.

## Mensajes

El esquema actual es `schema: 1` y reserva los tipos `TASK`, `CLAIM`,
`EVIDENCE`, `BLOCKER`, `QUESTION`, `RESULT`, `REVIEW` y `HANDOFF`.
Todos los mensajes incluyen `issue` y `handoff.from/to`.

- **TaskPacket (`TASK`)**: materializa objetivo, scope reservado, jerarquía de
  fuentes, condiciones de abortado y hashes SHA-256 de los artefactos que recibe
  el implementador. El CLAIM y el lease siguen siendo la autoridad de exclusión.
- **ResultPacket (`RESULT`)**: normaliza hechos, supuestos, evidencia,
  incógnitas, cambios y siguiente acción. Su cobertura es advisory: un modelo
  antiguo que no emita el bloque obtiene `missing/0%`, pero no invalida por sí
  solo un diff que haya pasado el resto de gates.
- **Review (`REVIEW`)**: envuelve el contrato histórico
  `AGENT_REVIEW_BEGIN/END` para que el siguiente actor reciba verdict,
  findings y estado del ResultPacket sin romper consumidores anteriores.

## Prompt compiler

`scripts/agent_b2b.py prompt` genera prompts por rol y proveedor. El workflow
usa el compilador para implementación y review; así Qwen y Gemini comparten la
misma jerarquía, scope y condiciones de abortado y solo difieren en su fichero
de reglas específico.

El implementador debe emitir:

```text
AGENT_RESULT_BEGIN
{"facts":[],"assumptions":[],"evidence":[],"unknowns":[],"changes":[],"next_action":"review"}
AGENT_RESULT_END
```

Se conserva además `AGENT_MEMORY_BEGIN/END` para la memoria Deno existente.

## Seguridad y autoridad

El paquete no concede permisos. La jerarquía sigue siendo repo/issue, #181,
registro activo #1713 y Normas Platino por encima de wiki y memorias. Los hashes
sirven para detectar handoffs obsoletos, no para convertir memoria en autoridad.

No se publican ResultPackets completos automáticamente: por ahora el PR solo
expone métricas de cobertura. Esto evita filtrar accidentalmente contenido de
prompts o secretos mientras se valida el protocolo.

## CLI

`agent_b2b.py` ofrece `task`, `result`, `review`, `prompt`, `validate` y
`verify`. `verify` recalcula SHA-256 y tamaño antes de entregar el TaskPacket al worker. El parser limita listas/textos y el reviewer mantiene compatibilidad
con `scripts/agent_review_contract.py`.
