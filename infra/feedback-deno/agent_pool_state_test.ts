import { handleAgentPool } from "./agent_pool_state.ts";

const REPO = "EspacioKoop/expediente-legado";
const keys = await crypto.subtle.generateKey(
  {
    name: "RSASSA-PKCS1-v1_5",
    modulusLength: 2048,
    publicExponent: new Uint8Array([1, 0, 1]),
    hash: "SHA-256",
  },
  true,
  ["sign", "verify"],
) as CryptoKeyPair;
const jwk = { ...await crypto.subtle.exportKey("jwk", keys.publicKey), kid: "pool-test" };

function igual(actual: unknown, esperado: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(esperado)) {
    throw new Error(`Esperado ${JSON.stringify(esperado)}, obtenido ${JSON.stringify(actual)}`);
  }
}

function base64(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes)).replace(/=/g, "").replace(/\+/g, "-").replace(
    /\//g,
    "_",
  );
}

async function llamar(
  kv: Deno.Kv,
  ruta: string,
  body: Record<string, unknown>,
  run = "run-1",
  role = "worker",
) {
  const encode = (data: unknown) => base64(new TextEncoder().encode(JSON.stringify(data)));
  const workflow = role === "worker" ? "agent-worker.yml" : "agent-pool.yml";
  const unsigned = encode({ alg: "RS256", kid: jwk.kid }) + "." + encode({
    iss: "https://token.actions.githubusercontent.com",
    aud: "siga98-agent-pool",
    exp: Math.floor(Date.now() / 1000) + 300,
    repository: REPO,
    run_id: run,
    workflow_ref: `${REPO}/.github/workflows/${workflow}@refs/heads/main`,
  });
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    keys.privateKey,
    new TextEncoder().encode(unsigned),
  );
  const url = new URL("https://pool.test/api/agent-pool/" + ruta);
  const request = new Request(url, {
    method: "POST",
    headers: { authorization: "Bearer " + unsigned + "." + base64(new Uint8Array(signature)) },
    body: JSON.stringify({ schema: 1, ...body }),
  });
  const response = await handleAgentPool(request, url, kv, REPO);
  return { status: response.status, data: await response.json() };
}

function tarea(issue: number, worker = "qwen-primary") {
  return {
    issue,
    worker,
    provider: "qwen",
    branch: `agent/qwen-${issue}-1`,
    files: [`scripts/${issue}.py`],
  };
}

async function conKv(fn: (kv: Deno.Kv) => Promise<void>) {
  const kv = await Deno.openKv(":memory:");
  const original = globalThis.fetch;
  globalThis.fetch = () => Promise.resolve(Response.json({ keys: [jwk] }));
  try {
    await fn(kv);
  } finally {
    globalThis.fetch = original;
    kv.close();
  }
}

Deno.test("slot: dos issues concurrentes solo adquieren un mismo worker", async () => {
  await conKv(async (kv) => {
    const resultados = await Promise.all([
      llamar(kv, "acquire", tarea(1), "run-1"),
      llamar(kv, "acquire", tarea(2), "run-2"),
    ]);
    igual(resultados.map((r) => r.status).sort(), [201, 409]);
    igual(resultados.find((r) => r.status === 409)!.data.error, "worker_conflict");
    const leases = [];
    for await (const entry of kv.list({ prefix: ["agent_pool", "lease"] })) {
      leases.push(entry.value);
    }
    igual(leases.length, 1);
  });
});

Deno.test("slot: workers independientes arrancan a la vez", async () => {
  await conKv(async (kv) => {
    const resultados = await Promise.all([
      llamar(kv, "acquire", tarea(1, "qwen-primary")),
      llamar(kv, "acquire", tarea(2, "qwen-fallback-1")),
    ]);
    igual(resultados.map((r) => r.status), [201, 201]);
  });
});

Deno.test("slot: renovar mientras otro adquiere conserva al dueno", async () => {
  await conKv(async (kv) => {
    const creado = await llamar(kv, "acquire", tarea(1));
    const resultados = await Promise.all([
      llamar(kv, "transition", {
        issue: 1,
        lease_id: creado.data.lease.lease_id,
        state: "validating",
      }),
      llamar(kv, "acquire", tarea(2), "run-2"),
    ]);
    igual(resultados.map((r) => r.status), [200, 409]);
    igual(
      (await kv.get(["agent_pool", "worker_lease", "qwen-primary"])).value,
      resultados[0].data.lease,
    );
    igual((await kv.get(["agent_pool", "lease", 2])).value, null);
  });
});

Deno.test("slot: retry acquire es idempotente y no genera otro lease", async () => {
  await conKv(async (kv) => {
    const uno = await llamar(kv, "acquire", tarea(1));
    const dos = await llamar(kv, "acquire", tarea(1));
    igual([uno.status, dos.status], [201, 201]);
    igual(dos.data.lease, uno.data.lease);
    igual(dos.data.deduplicated, true);
    igual((await llamar(kv, "acquire", tarea(1), "ajeno")).status, 409);
  });
});

Deno.test("slot: transicion renueva ambos leases y release permite refill", async () => {
  await conKv(async (kv) => {
    const creado = await llamar(kv, "acquire", tarea(1));
    const body = { issue: 1, lease_id: creado.data.lease.lease_id };
    const cambio = await llamar(kv, "transition", { ...body, state: "implementing" });
    igual(cambio.status, 200);
    const slot = await kv.get(["agent_pool", "worker_lease", "qwen-primary"]);
    igual(slot.value, cambio.data.lease);
    igual((await llamar(kv, "release", body, "ajeno")).status, 409);
    igual((await llamar(kv, "release", body)).data.released, true);
    igual((await llamar(kv, "release", body)).data.released, false);
    igual((await llamar(kv, "acquire", tarea(2), "run-2")).status, 201);
  });
});

Deno.test("slot: expirado se recupera y release viejo no borra al nuevo dueno", async () => {
  await conKv(async (kv) => {
    const viejo = await llamar(kv, "acquire", tarea(1));
    const expirado = { ...viejo.data.lease, expires_at: new Date(0).toISOString() };
    await kv.set(["agent_pool", "lease", 1], expirado);
    await kv.set(["agent_pool", "worker_lease", "qwen-primary"], expirado);
    const nuevo = await llamar(kv, "acquire", tarea(2), "run-2");
    igual(nuevo.status, 201);
    igual(
      (await llamar(kv, "transition", {
        issue: 1,
        lease_id: viejo.data.lease.lease_id,
        state: "planning",
      })).status,
      409,
    );
    await llamar(kv, "release", { issue: 1, lease_id: viejo.data.lease.lease_id });
    igual((await kv.get(["agent_pool", "worker_lease", "qwen-primary"])).value, nuevo.data.lease);
  });
});

Deno.test("slot: lease historico sin indice bloquea y puede renovarse", async () => {
  await conKv(async (kv) => {
    const viejo = await llamar(kv, "acquire", tarea(1));
    await kv.delete(["agent_pool", "worker_lease", "qwen-primary"]);
    igual((await llamar(kv, "acquire", tarea(2), "run-2")).status, 409);
    const cambio = await llamar(kv, "transition", {
      issue: 1,
      lease_id: viejo.data.lease.lease_id,
      state: "planning",
    });
    igual(cambio.status, 200);
    igual((await kv.get(["agent_pool", "worker_lease", "qwen-primary"])).value, cambio.data.lease);
  });
});

Deno.test("slot: conflicto de fichero no deja worker reservado", async () => {
  await conKv(async (kv) => {
    await llamar(kv, "acquire", tarea(1));
    const dos = { ...tarea(2, "qwen-fallback-1"), files: ["scripts/1.py"] };
    igual((await llamar(kv, "acquire", dos)).data.error, "file_conflict");
    igual((await kv.get(["agent_pool", "worker_lease", "qwen-fallback-1"])).value, null);
  });
});

Deno.test("slot: status incluye leases historicos y dispatcher no adquiere", async () => {
  await conKv(async (kv) => {
    await llamar(kv, "acquire", tarea(1));
    await kv.delete(["agent_pool", "worker_lease", "qwen-primary"]);
    const status = await llamar(
      kv,
      "worker-status",
      { workers: ["qwen-primary", "libre"] },
      "dispatch",
      "dispatcher",
    );
    igual(status.status, 200);
    igual(status.data.leases.map((lease: { worker: string }) => lease.worker), ["qwen-primary"]);
    igual((await llamar(kv, "acquire", tarea(2), "dispatch", "dispatcher")).status, 403);
  });
});
