const B2B_TYPES = new Set([
  "QUESTION",
  "BLOCKER",
  "EVIDENCE",
  "HANDOFF",
  "RESULT",
  "REVIEW",
]);
const B2B_RECIPIENTS = new Set(["dispatcher", "worker", "reviewer"]);
const B2B_TTL_DEFAULT_MS = 2 * 60 * 60 * 1000;
const B2B_TTL_MIN_MS = 5 * 60 * 1000;
const B2B_TTL_MAX_MS = 24 * 60 * 60 * 1000;
const B2B_INBOX_LIMIT = 50;

export interface AgentB2BActor {
  role: "dispatcher" | "worker" | "smoke";
  run_id: string;
}

interface AgentB2BDedupe {
  message_id: string;
  recipient: "dispatcher" | "worker" | "reviewer";
}

export interface AgentB2BMessage {
  schema: 1;
  message_id: string;
  task_id: string;
  message_type:
    | "QUESTION"
    | "BLOCKER"
    | "EVIDENCE"
    | "HANDOFF"
    | "RESULT"
    | "REVIEW";
  sender: string;
  recipient: "dispatcher" | "worker" | "reviewer";
  correlation_id: string;
  reply_to: string;
  subject: string;
  body: string;
  evidence: string[];
  blocking: boolean;
  created_ms: number;
  created_at: string;
  expires_at: string;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
      "referrer-policy": "no-referrer",
    },
  });
}

function cleanText(value: unknown, max: number): string {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, max);
}

function cleanToken(value: unknown, max: number): string {
  const token = cleanText(value, max);
  return /^[A-Za-z0-9._:/#@-]+$/.test(token) ? token : "";
}

function cleanEvidence(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .slice(0, 8)
    .map((item) => cleanText(item, 500))
    .filter(Boolean);
}

function looksSensitive(value: string): boolean {
  return /(gh[pousr]_|github_pat_|sk-[A-Za-z0-9]|Bearer\s+[A-Za-z0-9._-]{12,}|-----BEGIN [A-Z ]*PRIVATE KEY-----)/i
    .test(value);
}

function requestedTtlMs(value: unknown): number {
  const seconds = Number(value);
  if (!Number.isFinite(seconds)) return B2B_TTL_DEFAULT_MS;
  return Math.min(
    B2B_TTL_MAX_MS,
    Math.max(B2B_TTL_MIN_MS, Math.round(seconds * 1000)),
  );
}

function messageKey(
  recipient: string,
  taskId: string,
  messageId: string,
): Deno.KvKey {
  return ["agent_pool", "b2b", "message", recipient, taskId, messageId];
}

function inboxKey(
  recipient: string,
  taskId: string,
  createdMs: number,
  messageId: string,
): Deno.KvKey {
  return ["agent_pool", "b2b", "inbox", recipient, taskId, createdMs, messageId];
}

function dedupeKey(
  sender: string,
  taskId: string,
  idempotencyKey: string,
): Deno.KvKey {
  return ["agent_pool", "b2b", "dedupe", sender, taskId, idempotencyKey];
}

function canRead(actor: AgentB2BActor, recipient: string): boolean {
  if (actor.role === "dispatcher") return recipient === "dispatcher";
  if (actor.role === "worker") return recipient === "worker" || recipient === "reviewer";
  return false;
}

async function sendMessage(
  kv: Deno.Kv,
  raw: unknown,
  actor: AgentB2BActor,
): Promise<Response> {
  if (actor.role === "smoke") {
    return json({ ok: false, error: "forbidden" }, 403);
  }
  if (!raw || typeof raw !== "object") {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const input = raw as Record<string, unknown>;
  const taskId = cleanToken(input.task_id, 240);
  const type = cleanText(input.message_type, 24).toUpperCase();
  const recipient = cleanText(input.recipient, 24);
  const idempotency = cleanToken(input.idempotency_key, 120);
  const correlation = cleanToken(input.correlation_id, 120);
  const replyTo = cleanToken(input.reply_to, 120);
  const subject = cleanText(input.subject, 160);
  const body = cleanText(input.body, 4000);
  const evidence = cleanEvidence(input.evidence);
  const blocking = input.blocking === true || type === "BLOCKER";
  const runId = cleanToken(actor.run_id, 100);

  if (
    input.schema !== 1 ||
    !taskId ||
    !B2B_TYPES.has(type) ||
    !B2B_RECIPIENTS.has(recipient) ||
    !idempotency ||
    !runId ||
    (!subject && !body && evidence.length === 0)
  ) {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const sensitiveText = [subject, body, ...evidence].join("\n");
  if (looksSensitive(sensitiveText)) {
    return json({ ok: false, error: "sensitive_payload" }, 400);
  }

  const sender = actor.role + ":" + runId;
  const ttlMs = requestedTtlMs(input.ttl_seconds);
  const dedupe = dedupeKey(actor.role, taskId, idempotency);

  for (let attempt = 0; attempt < 5; attempt += 1) {
    const existing = await kv.get<AgentB2BDedupe>(dedupe);
    if (existing.value) {
      if (existing.value.recipient !== recipient) {
        return json({ ok: false, error: "idempotency_conflict" }, 409);
      }
      const current = await kv.get<AgentB2BMessage>(
        messageKey(recipient, taskId, existing.value.message_id),
      );
      if (current.value) {
        return json({ ok: true, deduplicated: true, message: current.value });
      }
      return json({
        ok: true,
        deduplicated: true,
        acknowledged: true,
        message_id: existing.value.message_id,
      });
    }

    const now = Date.now();
    const messageId = crypto.randomUUID();
    const message: AgentB2BMessage = {
      schema: 1,
      message_id: messageId,
      task_id: taskId,
      message_type: type as AgentB2BMessage["message_type"],
      sender,
      recipient: recipient as AgentB2BMessage["recipient"],
      correlation_id: correlation || messageId,
      reply_to: replyTo,
      subject,
      body,
      evidence,
      blocking,
      created_ms: now,
      created_at: new Date(now).toISOString(),
      expires_at: new Date(now + ttlMs).toISOString(),
    };

    const committed = await kv.atomic()
      .check(existing)
      .set(messageKey(recipient, taskId, messageId), message, { expireIn: ttlMs })
      .set(inboxKey(recipient, taskId, now, messageId), messageId, { expireIn: ttlMs })
      .set(dedupe, { message_id: messageId, recipient }, { expireIn: ttlMs })
      .commit();

    if (committed.ok) {
      return json({ ok: true, deduplicated: false, message }, 201);
    }
  }

  return json({ ok: false, error: "message_race" }, 409);
}

async function inbox(
  kv: Deno.Kv,
  raw: unknown,
  actor: AgentB2BActor,
): Promise<Response> {
  if (!raw || typeof raw !== "object") {
    return json({ ok: false, error: "invalid_request" }, 400);
  }
  const input = raw as Record<string, unknown>;
  const recipient = cleanText(input.recipient, 24);
  const taskId = cleanToken(input.task_id, 240);
  const requestedLimit = Number(input.limit);
  const limit = Number.isInteger(requestedLimit)
    ? Math.min(B2B_INBOX_LIMIT, Math.max(1, requestedLimit))
    : 20;

  if (
    input.schema !== 1 ||
    !B2B_RECIPIENTS.has(recipient) ||
    !taskId
  ) {
    return json({ ok: false, error: "invalid_request" }, 400);
  }
  if (!canRead(actor, recipient)) {
    return json({ ok: false, error: "forbidden" }, 403);
  }

  const prefix: Deno.KvKey = ["agent_pool", "b2b", "inbox", recipient, taskId];

  const messages: AgentB2BMessage[] = [];
  for await (const entry of kv.list<string>({ prefix }, { limit: limit * 2 })) {
    const key = entry.key;
    const indexedTask = String(key[4] ?? "");
    const messageId = String(entry.value ?? "");
    if (!indexedTask || !messageId) continue;
    const current = await kv.get<AgentB2BMessage>(
      messageKey(recipient, indexedTask, messageId),
    );
    if (!current.value) {
      await kv.delete(key);
      continue;
    }
    messages.push(current.value);
    if (messages.length >= limit) break;
  }

  messages.sort((a, b) =>
    a.created_ms - b.created_ms || a.message_id.localeCompare(b.message_id)
  );
  return json({ ok: true, messages });
}

async function acknowledge(
  kv: Deno.Kv,
  raw: unknown,
  actor: AgentB2BActor,
): Promise<Response> {
  if (!raw || typeof raw !== "object") {
    return json({ ok: false, error: "invalid_request" }, 400);
  }
  const input = raw as Record<string, unknown>;
  const recipient = cleanText(input.recipient, 24);
  const taskId = cleanToken(input.task_id, 240);
  const messageId = cleanToken(input.message_id, 120);

  if (
    input.schema !== 1 ||
    !taskId ||
    !messageId ||
    !B2B_RECIPIENTS.has(recipient)
  ) {
    return json({ ok: false, error: "invalid_request" }, 400);
  }
  if (!canRead(actor, recipient)) {
    return json({ ok: false, error: "forbidden" }, 403);
  }

  const key = messageKey(recipient, taskId, messageId);
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const current = await kv.get<AgentB2BMessage>(key);
    if (!current.value) {
      return json({ ok: true, acknowledged: false });
    }
    const committed = await kv.atomic()
      .check(current)
      .delete(key)
      .delete(inboxKey(recipient, taskId, current.value.created_ms, messageId))
      .commit();
    if (committed.ok) {
      return json({ ok: true, acknowledged: true });
    }
  }

  return json({ ok: false, error: "message_race" }, 409);
}

export async function handleAgentB2B(
  url: URL,
  kv: Deno.Kv,
  raw: unknown,
  actor: AgentB2BActor,
): Promise<Response> {
  if (url.pathname === "/api/agent-pool/b2b/send") {
    return await sendMessage(kv, raw, actor);
  }
  if (url.pathname === "/api/agent-pool/b2b/inbox") {
    return await inbox(kv, raw, actor);
  }
  if (url.pathname === "/api/agent-pool/b2b/ack") {
    return await acknowledge(kv, raw, actor);
  }
  return json({ ok: false, error: "not_found" }, 404);
}
