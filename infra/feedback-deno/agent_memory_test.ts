// Regresión ejecutable del contrato de memoria de agentes (#1756).
// Usa KV en memoria y nunca llega a la red: los tokens con forma de JWT
// fallan al decodificarse antes de pedir las claves de GitHub.
import { handleAgentMemory } from "./agent_memory.ts";

const REPO = "EspacioKoop/expediente-legado";
const TOKEN = "t".repeat(40);

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function assertEquals<T>(actual: T, expected: T, message: string): void {
  if (actual !== expected) {
    throw new Error(`${message}: esperado ${expected}, obtenido ${actual}`);
  }
}

async function call(
  kv: Deno.Kv,
  path: string,
  body: unknown,
  token: string | null = TOKEN,
): Promise<{ status: number; data: Record<string, unknown> }> {
  const headers: Record<string, string> = { "content-type": "application/json" };
  if (token !== null) headers.authorization = "Bearer " + token;
  const url = new URL("https://memoria.test/api/agent-memory/" + path);
  const response = await handleAgentMemory(
    new Request(url, { method: "POST", headers, body: JSON.stringify(body) }),
    url,
    kv,
    REPO,
  );
  return { status: response.status, data: await response.json() };
}

function leccion(extra: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    schema: 1,
    kind: "leccion",
    provider: "claude",
    summary: 'tr() depende del locale: fija set_locale("es") en las pruebas de textos.',
    tags: ["godot", "i18n"],
    paths: ["godot/pruebas/pruebas.gd"],
    ...extra,
  };
}

async function withKv(
  token: string | undefined,
  fn: (kv: Deno.Kv) => Promise<void>,
): Promise<void> {
  const previous = Deno.env.get("AGENT_MEMORY_NIVEL2_TOKEN");
  if (token === undefined) Deno.env.delete("AGENT_MEMORY_NIVEL2_TOKEN");
  else Deno.env.set("AGENT_MEMORY_NIVEL2_TOKEN", token);
  const kv = await Deno.openKv(":memory:");
  try {
    await fn(kv);
  } finally {
    kv.close();
    if (previous === undefined) Deno.env.delete("AGENT_MEMORY_NIVEL2_TOKEN");
    else Deno.env.set("AGENT_MEMORY_NIVEL2_TOKEN", previous);
  }
}

Deno.test("sin token configurado el nivel 2 queda cerrado", async () => {
  await withKv(undefined, async (kv) => {
    const { status } = await call(kv, "remember", leccion());
    assertEquals(status, 401, "remember sin token de servidor");
  });
});

Deno.test("un token de servidor corto no habilita el nivel 2", async () => {
  await withKv("corto", async (kv) => {
    const { status } = await call(kv, "remember", leccion(), "corto");
    assertEquals(status, 401, "token por debajo del mínimo");
  });
});

Deno.test("rechaza token ausente, erróneo o con forma de JWT", async () => {
  await withKv(TOKEN, async (kv) => {
    assertEquals((await call(kv, "search", { schema: 1 }, null)).status, 401, "sin cabecera");
    assertEquals((await call(kv, "search", { schema: 1 }, "x".repeat(40))).status, 401, "erróneo");
    assertEquals((await call(kv, "search", { schema: 1 }, "a.b.c")).status, 401, "JWT falso");
  });
});

Deno.test("el nivel 2 guarda una lección permanente y la encuentra", async () => {
  await withKv(TOKEN, async (kv) => {
    const saved = await call(kv, "remember", leccion());
    assertEquals(saved.status, 201, "remember");
    const memory = saved.data.memory as Record<string, unknown>;
    assertEquals(memory.kind, "leccion", "tipo");
    assertEquals(memory.issue, 0, "lección sin issue");
    assertEquals(memory.expires_at, null, "sin caducidad");
    assertEquals(memory.source, "nivel2:claude", "origen");

    for (
      const query of [
        { schema: 1, query: "locale de las pruebas" },
        { schema: 1, tags: ["i18n"] },
        { schema: 1, paths: ["godot/pruebas"] },
      ]
    ) {
      const found = await call(kv, "search", query);
      assertEquals(found.status, 200, "search");
      const memories = found.data.memories as Array<Record<string, unknown>>;
      assertEquals(memories.length, 1, "resultados para " + JSON.stringify(query));
      assertEquals(memories[0].id, memory.id, "misma lección");
    }

    const nothing = await call(kv, "search", { schema: 1, query: "sombras paraboloide" });
    assertEquals((nothing.data.memories as unknown[]).length, 0, "sin coincidencias");
  });
});

Deno.test("el nivel 2 no escribe como el pool ni cuela secretos", async () => {
  await withKv(TOKEN, async (kv) => {
    assertEquals(
      (await call(kv, "remember", leccion({ provider: "qwen" }))).status,
      400,
      "proveedor del pool",
    );
    assertEquals(
      (await call(
        kv,
        "remember",
        leccion({ summary: "usa ghp_abcdefghijklmnopqrstuvwx para todo" }),
      ))
        .status,
      400,
      "secreto",
    );
    assertEquals(
      (await call(kv, "remember", leccion({ summary: "corta" }))).status,
      400,
      "resumen demasiado corto",
    );
  });
});

Deno.test("un episodio de nivel 2 exige issue y caduca", async () => {
  await withKv(TOKEN, async (kv) => {
    const sinIssue = await call(kv, "remember", leccion({ kind: "episodio" }));
    assertEquals(sinIssue.status, 400, "episodio sin issue");

    const conIssue = await call(kv, "remember", leccion({ kind: "episodio", issue: 1756 }));
    assertEquals(conIssue.status, 201, "episodio con issue");
    const memory = conIssue.data.memory as Record<string, unknown>;
    assertEquals(memory.kind, "episodio", "tipo");
    assert(typeof memory.expires_at === "string", "el episodio caduca");
  });
});

Deno.test("forget retira una lección y solo una vez", async () => {
  await withKv(TOKEN, async (kv) => {
    const saved = await call(kv, "remember", leccion());
    const id = (saved.data.memory as Record<string, unknown>).id;

    assertEquals((await call(kv, "forget", { schema: 1, id })).status, 200, "forget");
    assertEquals((await call(kv, "forget", { schema: 1, id })).status, 404, "segunda vez");
    assertEquals((await call(kv, "forget", { schema: 1, id: "../x" })).status, 404, "id inválido");

    const found = await call(kv, "search", { schema: 1, tags: ["i18n"] });
    assertEquals((found.data.memories as unknown[]).length, 0, "ya no aparece");
  });
});
