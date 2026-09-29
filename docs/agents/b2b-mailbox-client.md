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

## Wiring en el worker

El worker consume el mailbox en tres puntos:

1. antes de planificar y antes de implementar, materializa el inbox dirigido al worker;
2. tras preflight, publica `EVIDENCE` + `HANDOFF` hacia el reviewer y añade ese inbox al input acotado de revisión;
3. después de normalizar el reviewer, publica `RESULT` + `REVIEW` al dispatcher y emite además `BLOCKER` cuando el ResultPacket termina bloqueado.

Los ACK se hacen **después** de que la fase correspondiente haya consumido el mensaje. Un fallo del mailbox no invalida por sí solo un diff correcto: los pasos son best-effort y el issue/PR de GitHub sigue dejando un fallback compacto y legible por humanos. El mailbox no concede permisos, no amplía el CLAIM y no cambia la política de merge.

Sigue siendo válido usar `QUESTION` para consultas dirigidas cuando una fase tenga una duda concreta; no se genera una pregunta artificial si el trabajo puede continuar con la evidencia disponible.
