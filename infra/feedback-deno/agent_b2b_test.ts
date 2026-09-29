import { handleAgentB2B, type AgentB2BActor } from "./agent_b2b.ts";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function assertEquals<T>(actual: T, expected: T, message: string): void {
  if (actual !== expected) {
    throw new Error(message + ": esperado " + String(expected) + ", obtenido " + String(actual));
  }
}

async function call(
  kv: Deno.Kv,
  path: string,
  body: Record<string, unknown>,
  actor: AgentB2BActor,
): Promise<{ status: number; data: Record<string, unknown> }> {
  const url = new URL("https://b2b.test/api/agent-pool/b2b/" + path);
  const response = await handleAgentB2B(url, kv, body, actor);
  return { status: response.status, data: await response.json() };
}

function worker(run = "run-worker-1"): AgentB2BActor {
  return { role: "worker", run_id: run };
}

function dispatcher(run = "run-dispatcher-1"): AgentB2BActor {
  return { role: "dispatcher", run_id: run };
}

function question(extra: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    schema: 1,
    task_id: "EspacioKoop/expediente-legado#1870@abcdef123456",
    message_type: "QUESTION",
    recipient: "reviewer",
    idempotency_key: "question-1",
    subject: "Validar regex",
    body: "Confirma si el patrón cubre el workflow real.",
    evidence: ["tests/test_workflow.py reproduce el caso"],
    blocking: true,
    ...extra,
  };
}

async function withKv(fn: (kv: Deno.Kv) => Promise<void>): Promise<void> {
  const kv = await Deno.openKv(":memory:");
  try {
    await fn(kv);
  } finally {
    kv.close();
  }
}

Deno.test("send e inbox conservan identidad, tipo y correlación", async () => {
  await withKv(async (kv) => {
    const sent = await call(kv, "send", question(), worker());
    assertEquals(sent.status, 201, "send");
    const message = sent.data.message as Record<string, unknown>;
    assertEquals(message.message_type, "QUESTION", "tipo");
    assertEquals(message.sender, "worker:run-worker-1", "sender derivado del actor");
    assertEquals(message.recipient, "reviewer", "destino");
    assertEquals(message.correlation_id, message.message_id, "correlación por defecto");

    const inbox = await call(
      kv,
      "inbox",
      {
        schema: 1,
        recipient: "reviewer",
        task_id: question().task_id,
      },
      worker("run-reviewer"),
    );
    assertEquals(inbox.status, 200, "inbox");
    const messages = inbox.data.messages as Array<Record<string, unknown>>;
    assertEquals(messages.length, 1, "un mensaje");
    assertEquals(messages[0].message_id, message.message_id, "mismo mensaje");
  });
});

Deno.test("idempotency key no duplica mensajes", async () => {
  await withKv(async (kv) => {
    const first = await call(kv, "send", question(), worker());
    const second = await call(kv, "send", question(), worker("run-worker-retry"));
    assertEquals(first.status, 201, "primer send");
    assertEquals(second.status, 200, "retry idempotente incluso en otro run");
    const one = first.data.message as Record<string, unknown>;
    const two = second.data.message as Record<string, unknown>;
    assertEquals(one.message_id, two.message_id, "mismo id");
    assertEquals(second.data.deduplicated, true, "marcado como deduplicado");

    const inbox = await call(
      kv,
      "inbox",
      { schema: 1, recipient: "reviewer", task_id: question().task_id },
      worker("run-reviewer"),
    );
    assertEquals((inbox.data.messages as unknown[]).length, 1, "sin duplicados");
  });
});

Deno.test("ACK consume inbox pero conserva idempotencia", async () => {
  await withKv(async (kv) => {
    const sent = await call(kv, "send", question(), worker());
    const message = sent.data.message as Record<string, unknown>;
    const ack = await call(
      kv,
      "ack",
      {
        schema: 1,
        recipient: "reviewer",
        task_id: message.task_id,
        message_id: message.message_id,
      },
      worker("run-reviewer"),
    );
    assertEquals(ack.status, 200, "ack");
    assertEquals(ack.data.acknowledged, true, "ack real");

    const empty = await call(
      kv,
      "inbox",
      { schema: 1, recipient: "reviewer", task_id: message.task_id },
      worker("run-reviewer"),
    );
    assertEquals((empty.data.messages as unknown[]).length, 0, "inbox vacío");

    const retry = await call(kv, "send", question(), worker());
    assertEquals(retry.status, 200, "retry tras ack");
    assertEquals(retry.data.deduplicated, true, "sigue deduplicado");
    assertEquals(retry.data.acknowledged, true, "sabe que ya se consumió");

    const stillEmpty = await call(
      kv,
      "inbox",
      { schema: 1, recipient: "reviewer", task_id: message.task_id },
      worker("run-reviewer"),
    );
    assertEquals((stillEmpty.data.messages as unknown[]).length, 0, "no reaparece");
  });
});

Deno.test("misma idempotency key no puede cambiar destinatario", async () => {
  await withKv(async (kv) => {
    assertEquals((await call(kv, "send", question(), worker())).status, 201, "primer send");
    const conflict = await call(
      kv,
      "send",
      question({ recipient: "dispatcher" }),
      worker(),
    );
    assertEquals(conflict.status, 409, "conflicto");
    assertEquals(conflict.data.error, "idempotency_conflict", "motivo");
  });
});

Deno.test("roles aíslan inboxes y smoke no puede enviar", async () => {
  await withKv(async (kv) => {
    await call(kv, "send", question({ recipient: "dispatcher" }), worker());

    const forbidden = await call(
      kv,
      "inbox",
      { schema: 1, recipient: "dispatcher", task_id: question().task_id },
      worker(),
    );
    assertEquals(forbidden.status, 403, "worker no lee dispatcher");

    const allowed = await call(
      kv,
      "inbox",
      { schema: 1, recipient: "dispatcher", task_id: question().task_id },
      dispatcher(),
    );
    assertEquals(allowed.status, 200, "dispatcher sí lee");
    assertEquals((allowed.data.messages as unknown[]).length, 1, "mensaje visible");

    const smoke = await call(
      kv,
      "send",
      question({ idempotency_key: "smoke-1" }),
      { role: "smoke", run_id: "smoke-run" },
    );
    assertEquals(smoke.status, 403, "smoke no envía");
  });
});

Deno.test("BLOCKER fuerza blocking aunque el emisor lo omita", async () => {
  await withKv(async (kv) => {
    const sent = await call(
      kv,
      "send",
      question({
        message_type: "BLOCKER",
        idempotency_key: "blocker-1",
        blocking: false,
      }),
      worker(),
    );
    assertEquals(sent.status, 201, "blocker");
    const message = sent.data.message as Record<string, unknown>;
    assertEquals(message.blocking, true, "blocking semántico");
  });
});

Deno.test("rechaza secretos obvios y schema incorrecto", async () => {
  await withKv(async (kv) => {
    const secret = await call(
      kv,
      "send",
      question({
        idempotency_key: "secret-1",
        body: "Authorization: Bearer abcdefghijklmnopqrstuvwxyz",
      }),
      worker(),
    );
    assertEquals(secret.status, 400, "secreto");
    assertEquals(secret.data.error, "sensitive_payload", "motivo secreto");

    const badSchema = await call(
      kv,
      "send",
      question({ schema: 2, idempotency_key: "schema-2" }),
      worker(),
    );
    assertEquals(badSchema.status, 400, "schema");
  });
});

Deno.test("TTL se acota y el inbox queda ordenado cronológicamente", async () => {
  await withKv(async (kv) => {
    const before = Date.now();
    const first = await call(
      kv,
      "send",
      question({ idempotency_key: "ttl-1", ttl_seconds: 1 }),
      worker(),
    );
    const message = first.data.message as Record<string, unknown>;
    const expires = Date.parse(String(message.expires_at));
    assert(expires - before >= 5 * 60 * 1000 - 1000, "TTL mínimo de cinco minutos");
    assert(expires - before <= 5 * 60 * 1000 + 5000, "TTL mínimo acotado");

    await call(
      kv,
      "send",
      question({
        idempotency_key: "ttl-2",
        message_type: "EVIDENCE",
        body: "Segundo mensaje",
      }),
      worker(),
    );
    const inbox = await call(
      kv,
      "inbox",
      { schema: 1, recipient: "reviewer", task_id: question().task_id },
      worker("run-reviewer"),
    );
    const messages = inbox.data.messages as Array<Record<string, unknown>>;
    assertEquals(messages.length, 2, "dos mensajes");
    assert(
      Number(messages[0].created_ms) <= Number(messages[1].created_ms),
      "orden cronológico",
    );
  });
});
