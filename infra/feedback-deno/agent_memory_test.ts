import { handleAgentMemory } from "./agent_memory.ts";

const TOKEN = "nivel2-test-token-1756";
const REPOSITORY = "EspacioKoop/expediente-legado";

function assert(condition: unknown, message = "assertion failed"): asserts condition {
  if (!condition) throw new Error(message);
}

function assertEquals(actual: unknown, expected: unknown, message = "values differ") {
  const left = JSON.stringify(actual);
  const right = JSON.stringify(expected);
  if (left !== right) {
    throw new Error(`${message}: actual=${left} expected=${right}`);
  }
}

async function post(
  kv: Deno.Kv,
  path: string,
  payload: unknown,
  bearer: string | null = TOKEN,
  configuredToken = TOKEN,
): Promise<Response> {
  const headers = new Headers({ "content-type": "application/json" });
  if (bearer !== null) headers.set("authorization", `Bearer ${bearer}`);
  const request = new Request(`https://memory.invalid/api/agent-memory/${path}`, {
    method: "POST",
    headers,
    body: JSON.stringify(payload),
  });
  return await handleAgentMemory(
    request,
    new URL(request.url),
    kv,
    REPOSITORY,
    configuredToken,
  );
}

Deno.test("nivel2: leccion durable, búsqueda por palabras y forget", async () => {
  const kv = await Deno.openKv(":memory:");
  try {
    const remember = await post(kv, "remember", {
      schema: 1,
      kind: "leccion",
      author: "odiseo",
      issue: 1756,
      summary: "La memoria durable de agentes usa Deno KV como archivo común verificable.",
      tags: ["infra", "memoria"],
      paths: ["infra/feedback-deno/agent_memory.ts"],
    });
    assertEquals(remember.status, 201);
    const created = await remember.json();
    assert(created.ok === true);
    assert(created.memory.kind === "leccion");
    assert(created.memory.author === "odiseo");
    assertEquals(created.memory.expires_at, null);
    const id = String(created.memory.id);

    const stored = [];
    for await (
      const entry of kv.list({ prefix: ["agent_memory", "lesson"] })
    ) {
      stored.push(entry.value);
    }
    assertEquals(stored.length, 1);

    const search = await post(kv, "search", {
      schema: 1,
      query: "archivo durable deno",
    });
    assertEquals(search.status, 200);
    const found = await search.json();
    assertEquals(found.memories.length, 1);
    assertEquals(found.memories[0].id, id);

    const forget = await post(kv, "forget", { schema: 1, id });
    assertEquals(forget.status, 200);

    const empty = await post(kv, "search", {
      schema: 1,
      query: "archivo durable deno",
    });
    assertEquals((await empty.json()).memories.length, 0);
  } finally {
    kv.close();
  }
});

Deno.test("nivel2: token ausente o incorrecto falla cerrado", async () => {
  const kv = await Deno.openKv(":memory:");
  try {
    const payload = { schema: 1, query: "memoria" };
    assertEquals((await post(kv, "search", payload, TOKEN, "")).status, 401);
    assertEquals((await post(kv, "search", payload, "incorrecto")).status, 401);
    assertEquals((await post(kv, "search", payload, null)).status, 401);
  } finally {
    kv.close();
  }
});

Deno.test("nivel2: solo escribe lecciones de autores permitidos y sin secretos", async () => {
  const kv = await Deno.openKv(":memory:");
  try {
    const base = {
      schema: 1,
      kind: "leccion",
      issue: 1756,
      tags: ["infra"],
      paths: ["infra/feedback-deno/agent_memory.ts"],
    };
    const episodio = await post(kv, "remember", {
      ...base,
      kind: "episodio",
      author: "odiseo",
      summary: "Este intento no debe poder escribir un episodio temporal del pool.",
    });
    assertEquals(episodio.status, 400);

    const autor = await post(kv, "remember", {
      ...base,
      author: "otro",
      summary: "Este autor no pertenece al conjunto explícito de agentes de nivel dos.",
    });
    assertEquals(autor.status, 400);

    const secreto = await post(kv, "remember", {
      ...base,
      author: "codex",
      summary: "Nunca persistir credenciales como Bearer abcdefghijklmnopqrstuvwxyz123456.",
    });
    assertEquals(secreto.status, 400);
  } finally {
    kv.close();
  }
});
