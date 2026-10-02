// Regresión ejecutable de la mesa de coordinación, fase 1 (#1867).
// KV en memoria y sin red: los tokens con forma de JWT fallan al decodificarse
// antes de pedir las claves de GitHub.
import { handleAgentCoord } from "./agent_coord.ts";

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
  method = "POST",
): Promise<{ status: number; data: Record<string, unknown> }> {
  const headers: Record<string, string> = { "content-type": "application/json" };
  if (token !== null) headers.authorization = "Bearer " + token;
  const url = new URL("https://mesa.test/api/agent-coord/" + path);
  const response = await handleAgentCoord(
    new Request(url, {
      method,
      headers,
      body: method === "POST" ? JSON.stringify(body) : undefined,
    }),
    url,
    kv,
    REPO,
  );
  return { status: response.status, data: await response.json() };
}

function aviso(extra: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    schema: 1,
    agente: "claude",
    tipo: "main-rojo",
    texto: "main rojo desde #1825: Deno 2.9.6 duplica argumentos; lo arregla #1859",
    refs: ["#1825", 1859, "basura", -3],
    paths: [".github/workflows/mando-deno.yml", "../fuera", "/absoluta"],
    ...extra,
  };
}

async function withKv(fn: (kv: Deno.Kv) => Promise<void>): Promise<void> {
  const previous = Deno.env.get("AGENT_MEMORY_NIVEL2_TOKEN");
  Deno.env.set("AGENT_MEMORY_NIVEL2_TOKEN", TOKEN);
  const kv = await Deno.openKv(":memory:");
  try {
    await fn(kv);
  } finally {
    kv.close();
    if (previous === undefined) Deno.env.delete("AGENT_MEMORY_NIVEL2_TOKEN");
    else Deno.env.set("AGENT_MEMORY_NIVEL2_TOKEN", previous);
  }
}

Deno.test("sin credencial válida no se lee ni se escribe", async () => {
  await withKv(async (kv) => {
    assertEquals((await call(kv, "avisos", { schema: 1 }, null)).status, 401, "sin cabecera");
    assertEquals((await call(kv, "avisar", aviso(), "x".repeat(40))).status, 401, "erróneo");
    assertEquals((await call(kv, "latido", { schema: 1 }, "a.b.c")).status, 401, "JWT falso");
    assertEquals((await call(kv, "avisos", {}, TOKEN, "GET")).status, 405, "solo POST");
    assertEquals((await call(kv, "avisos", { schema: 2 })).status, 400, "esquema");
  });
});

Deno.test("un aviso se publica limpio, se lista y se resuelve", async () => {
  await withKv(async (kv) => {
    const creado = await call(kv, "avisar", aviso());
    assertEquals(creado.status, 201, "avisar");
    const guardado = creado.data.aviso as Record<string, unknown>;
    assertEquals(JSON.stringify(guardado.refs), "[1825,1859]", "refs saneadas");
    assertEquals(
      JSON.stringify(guardado.paths),
      '[".github/workflows/mando-deno.yml"]',
      "rutas fuera del repo descartadas",
    );

    const lista = await call(kv, "avisos", { schema: 1 });
    const avisos = lista.data.avisos as Array<Record<string, unknown>>;
    assertEquals(avisos.length, 1, "un aviso activo");
    assertEquals(avisos[0].id, guardado.id, "es el publicado");

    assertEquals(
      (await call(kv, "resolver", { schema: 1, id: guardado.id })).status,
      200,
      "resolver",
    );
    assertEquals(
      (await call(kv, "resolver", { schema: 1, id: guardado.id })).status,
      404,
      "ya resuelto",
    );
    const vacia = await call(kv, "avisos", { schema: 1 });
    assertEquals((vacia.data.avisos as unknown[]).length, 0, "tablón vacío");
  });
});

Deno.test("rechaza avisos de agentes desconocidos, tipos libres o con secretos", async () => {
  await withKv(async (kv) => {
    for (
      const [extra, motivo] of [
        [{ agente: "intruso" }, "agente fuera de la lista"],
        [{ tipo: "cualquiera" }, "tipo fuera del catálogo"],
        [{ texto: "corto" }, "texto demasiado corto"],
        [{ texto: "usa ghp_" + "a".repeat(36) + " para subir" }, "secreto"],
      ] as Array<[Record<string, unknown>, string]>
    ) {
      assertEquals((await call(kv, "avisar", aviso(extra))).status, 400, motivo);
    }
    const lista = await call(kv, "avisos", { schema: 1 });
    assertEquals((lista.data.avisos as unknown[]).length, 0, "nada guardado");
  });
});

Deno.test("los avisos más nuevos salen primero y el TTL se acota", async () => {
  await withKv(async (kv) => {
    const viejo = await call(kv, "avisar", aviso({ tipo: "en-curso", ttl_horas: 500 }));
    await new Promise((resolve) => setTimeout(resolve, 5));
    await call(kv, "avisar", aviso({ tipo: "bloqueo", ttl_horas: 0 }));
    const guardado = viejo.data.aviso as Record<string, string>;
    const horas = (Date.parse(guardado.caduca) - Date.parse(guardado.creado)) / 3_600_000;
    assertEquals(horas, 72, "TTL máximo 72 h");

    const avisos = (await call(kv, "avisos", { schema: 1 })).data.avisos as Array<
      Record<string, unknown>
    >;
    assertEquals(avisos.length, 2, "dos activos");
    assertEquals(avisos[0].tipo, "bloqueo", "el más nuevo primero");
  });
});

Deno.test("el latido registra presencia por agente y la renueva", async () => {
  await withKv(async (kv) => {
    const primero = await call(kv, "latido", {
      schema: 1,
      agente: "odiseo",
      issue: 1850,
      rama: "dependabot/upload-artifact",
      tarea: "tests de upload-artifact v7",
    });
    assertEquals(primero.status, 200, "latido");
    // `visto` tiene resolución de milisegundo: sin pausa, los latidos empatan y
    // el orden «más reciente primero» no queda definido.
    await new Promise((resolve) => setTimeout(resolve, 5));
    await call(kv, "latido", { schema: 1, agente: "claude", issue: 1867, tarea: "mesa" });
    await new Promise((resolve) => setTimeout(resolve, 5));
    await call(kv, "latido", { schema: 1, agente: "odiseo", issue: 1753, tarea: "combate" });
    assertEquals(
      (await call(kv, "latido", { schema: 1, agente: "nadie" })).status,
      400,
      "agente desconocido",
    );

    const presentes = (await call(kv, "presentes", { schema: 1 })).data.presentes as Array<
      Record<string, unknown>
    >;
    assertEquals(presentes.length, 2, "una entrada por agente");
    const odiseo = presentes.find((p) => p.agente === "odiseo");
    assert(odiseo, "odiseo presente");
    assertEquals(odiseo.issue, 1753, "el latido nuevo sustituye al anterior");
    assertEquals(presentes[0].agente, "odiseo", "el más reciente primero");
  });
});

Deno.test("reserva: carrera de claims concurrentes sobre misma ruta", async () => {
  await withKv(async (kv) => {
    const ruta = "src/main.ts";
    const claim1 = call(kv, "claim", {
      schema: 1,
      agente: "claude",
      issue: 2001,
      rama: "feat/1",
      files: [ruta],
      goal: "goal 1",
    });
    const claim2 = call(kv, "claim", {
      schema: 1,
      agente: "odiseo",
      issue: 2002,
      rama: "feat/2",
      files: [ruta],
      goal: "goal 2",
    });

    const [res1, res2] = await Promise.all([claim1, claim2]);
    const ganadores = [res1, res2].filter((r) => r.status === 201);
    assertEquals(ganadores.length, 1, "exactamente un ganador en carrera");
  });
});

Deno.test("reserva: solapo padre-hijo y prefijos", async () => {
  await withKv(async (kv) => {
    // 1. Reservar carpeta padre
    await call(kv, "claim", {
      schema: 1,
      agente: "claude",
      issue: 3001,
      rama: "feat/padre",
      files: ["src/components/"],
      goal: "padre",
    });

    // 2. Intentar reservar hijo (debería fallar por solapo)
    const hijo = await call(kv, "claim", {
      schema: 1,
      agente: "odiseo",
      issue: 3002,
      rama: "feat/hijo",
      files: ["src/components/Botton.ts"],
      goal: "hijo",
    });
    assertEquals(hijo.status, 409, "solapo hijo en carpeta reservada");

    // 3. Reserva en ruta no solapada
    const ok = await call(kv, "claim", {
      schema: 1,
      agente: "odiseo",
      issue: 3003,
      rama: "feat/otro",
      files: ["src/utils/helpers.ts"],
      goal: "otro",
    });
    assertEquals(ok.status, 201, "ruta sin solapo permitida");
  });
});

Deno.test("reserva: expiración de lease y renovación (heartbeat)", async () => {
  await withKv(async (kv) => {
    const ruta = "src/expire.ts";
    await call(kv, "claim", {
      schema: 1,
      agente: "claude",
      issue: 4001,
      rama: "feat/exp",
      files: [ruta],
      goal: "expira",
      lease: 1, // 1 minuto
    });

    // Heartbeat autorizado
    const claimRes = await call(kv, "claim", {
      schema: 1,
      agente: "claude",
      issue: 4002,
      rama: "feat/hb",
      files: ["src/hb.ts"],
      goal: "hb",
    });
    const id = (claimRes.data.reserva as Record<string, unknown>).id;
    const hb = await call(kv, "heartbeat", {
      schema: 1,
      reservaId: id,
    });
    assertEquals(hb.status, 200, "heartbeat autorizado");

    const hbNo = await call(kv, "heartbeat", {
      schema: 1,
      reservaId: id,
    }, "t".repeat(40) + "X"); // Token distinto (simulando otro agente)
    assertEquals(hbNo.status, 403, "heartbeat no autorizado (otro agente)");
  });
});

Deno.test("reserva: release doble idempotente", async () => {
  await withKv(async (kv) => {
    const res = await call(kv, "claim", {
      schema: 1,
      agente: "claude",
      issue: 5001,
      rama: "feat/rel",
      files: ["src/rel.ts"],
      goal: "rel",
    });
    const id = (res.data.reserva as Record<string, unknown>).id;

    assertEquals((await call(kv, "release", { schema: 1, reservaId: id })).status, 200, "primer release");
    assertEquals((await call(kv, "release", { schema: 1, reservaId: id })).status, 200, "segundo release idempotente");
  });
});

Deno.test("reserva: KV caído (fail closed)", async () => {
  // Simulamos KV caído pasando un objeto que lanza errores
  const kvFallo = {
    get: () => { throw new Error("KV DOWN"); },
    set: () => { throw new Error("KV DOWN"); },
    listToJSON: () => { throw new Error("KV DOWN"); },
    close: () => {},
  } as unknown as Deno.Kv;

  const res = await call(kvFallo, "claim", {
    schema: 1,
    agente: "claude",
    issue: 6001,
    rama: "feat/fail",
    files: ["src/fail.ts"],
    goal: "fail",
  });
  assertEquals(res.status, 503, "KV caído devuelve service_unavailable");
});

Deno.test("reserva: claim frente a reserva histórica viva de #1713", async () => {
  await withKv(async (kv) => {
    const res = await call(kv, "claim", {
      schema: 1,
      agente: "claude",
      issue: 7001,
      rama: "feat/hist",
      files: ["src/hist.ts"],
      goal: "hist",
    });
    assertEquals(res.status, 201, "reserva local exitosa aunque espejo falle");
  });
});

