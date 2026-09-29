# Cliente del mailbox B2B de agentes (#1870)

`infra/feedback-deno/agent_b2b.ts` ya expone el transporte dirigido en Deno KV. `scripts/agent_b2b_mailbox.py` es el adaptador cliente reutilizable para workflows: evita repetir bloques de `curl`, validación y obtención OIDC cada vez que una fase necesite enviar, leer o confirmar un mensaje.

## Frontera

El cliente no sustituye leases, CLAIM/RELEASE ni el protocolo de TaskPacket/ResultPacket. Solo transporta mensajes `QUESTION`, `BLOCKER`, `EVIDENCE`, `HANDOFF`, `RESULT` y `REVIEW` entre `dispatcher`, `worker` y `reviewer`.

La autenticación usa el OIDC efímero de GitHub Actions con audiencia `siga98-agent-pool`. El token se envía solo en `Authorization` y no se serializa en payloads ni salidas.

## Uso

La URL puede ser la variable ya existente `SIGA98_FEEDBACK_FALLBACK_URL`; el cliente elimina `/api/report` antes de llamar al control-plane.

```bash
python3 scripts/agent_b2b_mailbox.py send \
  --task-id 'EspacioKoop/expediente-legado#1870@abc123' \
  --type HANDOFF \
  --recipient reviewer \
  --idempotency-key 'run-123:handoff-reviewer' \
  --subject 'Implementación lista para revisar' \
  --evidence 'python3 -m unittest: OK'
```

```bash
python3 scripts/agent_b2b_mailbox.py inbox \
  --recipient reviewer \
  --task-id 'EspacioKoop/expediente-legado#1870@abc123' \
  --output /tmp/reviewer-inbox.json
```

```bash
python3 scripts/agent_b2b_mailbox.py ack \
  --recipient reviewer \
  --task-id 'EspacioKoop/expediente-legado#1870@abc123' \
  --message-id '<message_id>'
```

## Seguridad y límites

- exige HTTPS para el gateway;
- valida tipos, destinatarios e identificadores antes de abrir red;
- rechaza localmente patrones evidentes de credenciales;
- conserva la idempotencia del servidor mediante `idempotency_key`;
- no imprime el OIDC ni lo incluye en el cuerpo JSON;
- limita evidencia a 8 entradas y deja que el servidor aplique TTL y tamaños definitivos.

## Siguiente corte de wiring

Cuando el PR que modifica `agent-worker.yml` deje libre ese archivo, el wiring puede ser pequeño: materializar el inbox antes de implementer/reviewer, enviar `BLOCKER` o `QUESTION` cuando haya una dependencia real, transportar `EVIDENCE/HANDOFF` al reviewer y hacer ACK solo después de haber materializado el mensaje. El comentario GitHub compacto se mantiene como fallback visible para humanos, no como bus primario.
