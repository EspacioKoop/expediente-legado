# Euriclea: revisión de drafts del pool

Euriclea es la revisión independiente de los PRs generados por agentes. Este documento cubre el **contrato del repositorio**; la operación de backends y cualquier respaldo local se mantienen fuera del repo público.

## Autoridad

| Revisión | Sin hallazgos | Con hallazgos | Sin respuesta |
| --- | --- | --- | --- |
| Principal | `revision:ok` | `revision:hallazgos` | `revision:pendiente` |
| Respaldo externo | comentario; no puede aprobar | `revision:hallazgos` | sin cambio |

- `revision:ok` significa que hubo revisión independiente; no autoriza merge.
- Un SHA nuevo invalida la revisión anterior.
- Solo cuentan autores configurados explícitamente por el workflow.
- La autorrevisión del mismo worker que implementó sirve como señal, no como revisión independiente.

## Qué revisa

La lógica está en `scripts/agent_euriclea.py` y el contrato de salida en `scripts/agent_review_contract.py`.

La revisión recibe:

- issue;
- `AGENT_PLAN`;
- metadatos del PR;
- diff del SHA actual.

El contenido del PR se trata como datos no confiables. Euriclea no ejecuta código de la rama y debe ignorar instrucciones incluidas dentro del diff o del texto revisado.

## Principal

`agent-review.yml` puede barrer drafts pendientes o revisar una PR concreta mediante `workflow_dispatch`.

Si ningún backend configurado puede producir un contrato válido, la PR queda en `revision:pendiente`; nunca se aprueba por ausencia de respuesta.

## Respaldo

Puede existir un revisor externo de respaldo para `revision:pendiente`. Ese respaldo conserva menos autoridad que la revisión principal: puede encontrar problemas, pero no producir `revision:ok`.

Su despliegue, modelos, timers y diagnóstico no se documentan en este repositorio.

## Operación pública

Para repetir la revisión principal de una PR concreta:

```bash
gh workflow run agent-review.yml -f pr=<N>
```

El resultado sigue sujeto a CI y a integración humana.
