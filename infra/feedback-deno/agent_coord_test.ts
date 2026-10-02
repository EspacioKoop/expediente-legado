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

type GithubComment = { body: string; created_at: string };

async function withGithubMock(
  fn: () => Promise<void>,
  historicas: GithubComment[] = [],
): Promise<void> {
  const previousToken = Deno.env.get("GITHUB_TOKEN");
  const previousFetch = globalThis.fetch;
  Deno.env.set("GITHUB_TOKEN", "test-github-token");
  globalThis.fetch = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = typeof input === "string"
      ? input
      : input instanceof URL
      ? input.toString()
      : input.url;
    if (!url.includes("/issues/1713/comments")) {
      throw new Error("red no esperada en test: " + url);
    }
    if ((init?.method ?? "GET") === "POST") {
      return new Response("{}", {
        status: 201,
        headers: { "content-type": "application/json" },
      });
    }
    return Response.json(historicas);
  }) as typeof fetch;
  try {
    await fn();
  } finally {
    globalThis.fetch = previousFetch;
    if (previousToken === undefined) Deno.env.delete("GITHUB_TOKEN");
    else Deno.env.set("GITHUB_TOKEN", previousToken);
  }
}

async function withKv(
  fn: (kv: Deno.Kv) => Promise<void>,
  historicas: GithubComment[] = [],
): Promise<void> {
  const previous = Deno.env.get("AGENT_MEMORY_NIVEL2_TOKEN");
  Deno.env.set("AGENT_MEMORY_NIVEL2_TOKEN", TOKEN);
  const kv = await Deno.openKv(":memory:");
  try {
    await withGithubMock(() => fn(kv), historicas);
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

Deno.test("reserva: carrera de claims concurrentes sobre la misma ruta", async () => {
  await withKv(async (kv) => {
    const base = {
      schema: 1,
      agente: "claude",
      files: ["src/main.ts"],
      goal: "editar main",
    };
    const [uno, dos] = await Promise.all([
      call(kv, "claim", { ...base, issue: 2001, rama: "feat/uno" }),
      call(kv, "claim", { ...base, issue: 2002, rama: "feat/dos" }),
    ]);
    const estados = [uno.status, dos.status].sort();
    assertEquals(JSON.stringify(estados), "[201,409]", "exactamente un claim gana");
  });
});

Deno.test("reserva: padre-hijo solapa pero prefijo textual no", async () => {
  await withKv(async (kv) => {
    const padre = await call(kv, "claim", {
      schema: 1,
      agente: "claude",
      issue: 3001,
      rama: "feat/padre",
      files: ["src/foo"],
      goal: "reservar directorio",
    });
    assertEquals(padre.status, 201, "padre reservado");

    const hijo = await call(kv, "claim", {
      schema: 1,
      agente: "odiseo",
      issue: 3002,
      rama: "feat/hijo",
      files: ["src/foo/bar.ts"],
      goal: "reservar hijo",
    });
    assertEquals(hijo.status, 409, "hijo entra en conflicto");

    const noPrefijo = await call(kv, "claim", {
      schema: 1,
      agente: "odiseo",
      issue: 3003,
      rama: "feat/no-prefijo",
      files: ["src/foobar"],
      goal: "prefijo textual distinto",
    });
    assertEquals(noPrefijo.status, 201, "foo no solapa foobar");
  });
});

Deno.test("reserva: rutas inválidas y duplicadas fallan cerrado", async () => {
  await withKv(async (kv) => {
    for (const files of [
      [],
      ["/absoluta"],
      ["../fuera"],
      ["src/../fuera"],
      ["src/repetida", "src/repetida"],
      ["src/carpeta/"],
    ]) {
      const res = await call(kv, "claim", {
        schema: 1,
        agente: "claude",
        issue: 3100,
        rama: "feat/rutas",
        files,
        goal: "probar normalización",
      });
      assertEquals(res.status, 400, "ruta inválida rechazada: " + JSON.stringify(files));
    }
  });
});

Deno.test("reserva: lease expirado se poda y heartbeat solo renueva al dueño", async () => {
  await withKv(async (kv) => {
    const pasado = new Date(Date.now() - 60_000).toISOString();
    await kv.set(["agent_coord", "reservas", "v1"], {
      schema: 1,
      reservas: [{
        schema: 1,
        id: "expirada",
        agente: "claude",
        issue: 4000,
        rama: "feat/vieja",
        files: ["src/expire.ts"],
        goal: "vieja",
        creado: pasado,
        visto: pasado,
        expira: pasado,
      }],
    });

    const claimRes = await call(kv, "claim", {
      schema: 1,
      agente: "claude",
      issue: 4001,
      rama: "feat/nueva",
      files: ["src/expire.ts"],
      goal: "reutiliza ruta expirada",
      ttl_min: 5,
    });
    assertEquals(claimRes.status, 201, "una reserva expirada no bloquea");
    const reserva = claimRes.data.reserva as Record<string, unknown>;
    const id = String(reserva.id);
    const expiraAntes = Date.parse(String(reserva.expira));

    const noDueno = await call(kv, "heartbeat", {
      schema: 1,
      agente: "odiseo",
      id,
      ttl_min: 60,
    });
    assertEquals(noDueno.status, 404, "otro agente no renueva");

    const hb = await call(kv, "heartbeat", {
      schema: 1,
      agente: "claude",
      id,
      ttl_min: 60,
    });
    assertEquals(hb.status, 200, "el dueño renueva");
    const renovada = hb.data.reserva as Record<string, unknown>;
    assert(
      Date.parse(String(renovada.expira)) > expiraAntes,
      "heartbeat amplía la expiración",
    );
  });
});

Deno.test("reserva: release doble es idempotente y otro agente no libera", async () => {
  await withKv(async (kv) => {
    const creado = await call(kv, "claim", {
      schema: 1,
      agente: "claude",
      issue: 5001,
      rama: "feat/release",
      files: ["src/release.ts"],
      goal: "probar release",
    });
    const id = String((creado.data.reserva as Record<string, unknown>).id);

    const ajeno = await call(kv, "release", {
      schema: 1,
      agente: "odiseo",
      id,
      reason: "ajeno",
    });
    assertEquals(ajeno.status, 403, "otro agente no libera");

    const primero = await call(kv, "release", {
      schema: 1,
      agente: "claude",
      id,
      reason: "entregado",
    });
    assertEquals(primero.status, 200, "primer release");
    assertEquals(primero.data.released as boolean, true, "liberó una reserva");

    const segundo = await call(kv, "release", {
      schema: 1,
      agente: "claude",
      id,
      reason: "entregado",
    });
    assertEquals(segundo.status, 200, "segundo release idempotente");
    assertEquals(segundo.data.released as boolean, false, "ya no había reserva");
  });
});

Deno.test("reserva: KV caído impide adquirir permiso", async () => {
  await withGithubMock(async () => {
    const kvFallo = {
      get: () => {
        throw new Error("KV DOWN");
      },
    } as unknown as Deno.Kv;
    const res = await call(kvFallo, "claim", {
      schema: 1,
      agente: "claude",
      issue: 6001,
      rama: "feat/fail",
      files: ["src/fail.ts"],
      goal: "fail closed",
    });
    assertEquals(res.status, 503, "KV caído devuelve service_unavailable");
  });
});

Deno.test("reserva: claim respeta una reserva histórica viva de #1713", async () => {
  const ahora = new Date().toISOString();
  await withKv(
    async (kv) => {
      const res = await call(kv, "claim", {
        schema: 1,
        agente: "odiseo",
        issue: 7001,
        rama: "feat/nueva",
        files: ["src/hist.ts"],
        goal: "no pisar histórico",
      });
      assertEquals(res.status, 409, "la reserva histórica bloquea el claim KV");
      const conflicts = res.data.conflicts as Array<Record<string, unknown>>;
      assertEquals(conflicts.length, 1, "devuelve el conflicto histórico");
      assertEquals(conflicts[0].issue as number, 6999, "identifica el claim previo");
    },
    [{
      body:
        "CLAIM issue=#6999 agent=claude branch=feat/historica files=src/hist.ts goal=previo lease=48h",
      created_at: ahora,
    }],
  );
});
