// Regresión ejecutable de la sala de mando (#1778). Sin red: GitHub y el
// gateway se simulan con un fetch que registra cada petición.
import {
  construirOrden,
  crearHandler,
  esc,
  type MandoConfig,
  reservasVivas,
  vaciarCache,
} from "./mando.ts";

const TOKEN = "m".repeat(40);
const ORIGEN = "https://mando.test";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function assertEquals<T>(actual: T, expected: T, message: string): void {
  if (actual !== expected) {
    throw new Error(`${message}: esperado ${expected}, obtenido ${actual}`);
  }
}

interface Llamada {
  url: string;
  method: string;
  body: string;
}

function simulador(): { fetch: typeof fetch; llamadas: Llamada[] } {
  const llamadas: Llamada[] = [];
  const responder = (data: unknown, status = 200) =>
    new Response(JSON.stringify(data), { status, headers: { "content-type": "application/json" } });
  const fetchFalso = (input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    llamadas.push({ url, method: init?.method ?? "GET", body: String(init?.body ?? "") });
    if (url.includes("/search/issues")) {
      return Promise.resolve(responder({
        items: [{
          number: 7,
          title: "<script>alert(1)</script> título",
          html_url: "https://github.com/x/y/issues/7",
          labels: [{ name: "agent:needs-human" }],
          updated_at: "2026-09-29T00:00:00Z",
        }],
      }));
    }
    if (url.endsWith("/graphql")) {
      return Promise.resolve(responder({
        data: {
          repository: {
            pullRequests: {
              nodes: [{
                number: 9,
                title: "PR de prueba",
                url: "https://github.com/x/y/pull/9",
                isDraft: false,
                headRefName: "feature/9",
                updatedAt: "2026-09-29T00:00:00Z",
                author: { login: "odiseo" },
                commits: { nodes: [{ commit: { statusCheckRollup: { state: "SUCCESS" } } }] },
              }],
            },
          },
        },
      }));
    }
    if (url.includes("/issues/1713/comments")) {
      return Promise.resolve(responder([
        {
          body: "CLAIM issue=#5 agent=Atenea branch=feature/5 files=a",
          created_at: "2026-09-28T20:00:00Z",
          author_association: "MEMBER",
          user: { login: "atenea" },
        },
        {
          body: "RELEASE issue=#5 motivo=falso",
          created_at: "2026-09-28T21:00:00Z",
          author_association: "NONE",
          user: { login: "externo" },
        },
      ]));
    }
    if (url.endsWith("/health")) {
      return Promise.resolve(responder({ ok: true, version: 4, agent_memory: true }));
    }
    if (url.endsWith("/issues") && init?.method === "POST") {
      return Promise.resolve(responder({ number: 1234 }, 201));
    }
    return Promise.resolve(responder({ message: "no simulado" }, 404));
  };
  return { fetch: fetchFalso as typeof fetch, llamadas };
}

function config(extra: Partial<MandoConfig> = {}): MandoConfig {
  return {
    token: TOKEN,
    githubToken: "gh-falso",
    repository: "EspacioKoop/expediente-legado",
    gatewayUrl: "https://gateway.test",
    registroIssue: 1713,
    fetch: simulador().fetch,
    now: () => Date.parse("2026-09-29T01:00:00Z"),
    ...extra,
  };
}

function post(path: string, campos: Record<string, string>, headers: Record<string, string> = {}) {
  return new Request(ORIGEN + path, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded", origin: ORIGEN, ...headers },
    body: new URLSearchParams(campos),
  });
}

async function entrar(handler: (r: Request) => Promise<Response>): Promise<string> {
  const response = await handler(post("/entrar", { token: TOKEN }));
  assertEquals(response.status, 303, "login correcto");
  const cookie = response.headers.get("set-cookie") ?? "";
  for (const atributo of ["HttpOnly", "Secure", "SameSite=Strict"]) {
    assert(cookie.includes(atributo), `cookie con ${atributo}`);
  }
  return cookie.split(";")[0];
}

Deno.test("sin configurar, todo salvo /health queda cerrado", async () => {
  const handler = crearHandler(config({ token: "corto" }));
  assertEquals((await handler(new Request(ORIGEN + "/"))).status, 503, "sala");
  assertEquals((await handler(post("/entrar", { token: "corto" }))).status, 503, "login");
  const health = await (await handler(new Request(ORIGEN + "/health"))).json();
  assertEquals(health.configurado, false, "health informa");
  assert(!JSON.stringify(health).includes("corto"), "health no filtra el token");
});

Deno.test("sin sesión redirige a entrar y rechaza token erróneo", async () => {
  const handler = crearHandler(config());
  const sala = await handler(new Request(ORIGEN + "/"));
  assertEquals(sala.status, 303, "redirige");
  assertEquals(sala.headers.get("location"), "/entrar", "a entrar");
  assertEquals((await handler(post("/entrar", { token: "x".repeat(40) }))).status, 401, "erróneo");
});

Deno.test("una cookie manipulada o caducada no abre la sala", async () => {
  const handler = crearHandler(config());
  const cookie = await entrar(handler);
  const manipulada = cookie.slice(0, -1) + (cookie.endsWith("0") ? "1" : "0");
  const r1 = await handler(new Request(ORIGEN + "/", { headers: { cookie: manipulada } }));
  assertEquals(r1.status, 303, "firma manipulada");

  const futuro = crearHandler(config({ now: () => Date.parse("2026-12-31T00:00:00Z") }));
  const r2 = await futuro(new Request(ORIGEN + "/", { headers: { cookie } }));
  assertEquals(r2.status, 303, "sesión caducada");
});

Deno.test("la sala muestra pool, PRs, reservas y salud escapando HTML", async () => {
  vaciarCache();
  const handler = crearHandler(config());
  const cookie = await entrar(handler);
  const response = await handler(new Request(ORIGEN + "/", { headers: { cookie } }));
  assertEquals(response.status, 200, "sala");
  const texto = await response.text();
  assert(!texto.includes("<script>alert"), "título escapado");
  assert(texto.includes("&lt;script&gt;"), "título visible escapado");
  assert(texto.includes("needs-human"), "label del pool");
  assert(texto.includes("PR de prueba") && texto.includes("success"), "PR con CI");
  assert(texto.includes("#5") && texto.includes("Atenea"), "reserva viva");
  assert(texto.includes("v4"), "versión del gateway");
  assert(response.headers.get("content-security-policy")?.includes("default-src 'none'"), "CSP");
});

Deno.test("los POST de otro origen se rechazan (CSRF)", async () => {
  const handler = crearHandler(config());
  const cookie = await entrar(handler);
  const ajeno = post("/orden", { titulo: "Orden ajena" }, { cookie, origin: "https://malo.test" });
  assertEquals((await handler(ajeno)).status, 403, "origen ajeno");
  const sinOrigen = new Request(ORIGEN + "/orden", {
    method: "POST",
    headers: { cookie, "content-type": "application/x-www-form-urlencoded" },
    body: "titulo=Sin+origen",
  });
  assertEquals((await handler(sinOrigen)).status, 403, "sin origen ni sec-fetch-site");
  assertEquals(
    (await handler(post("/entrar", { token: TOKEN }, { origin: "https://malo.test" }))).status,
    403,
    "login desde otro origen",
  );
});

Deno.test("un navegador que manda Origin: null pero es same-origin puede entrar", async () => {
  const handler = crearHandler(config());
  const navegador = await handler(
    post("/entrar", { token: TOKEN }, { origin: "null", "sec-fetch-site": "same-origin" }),
  );
  assertEquals(navegador.status, 303, "login desde la propia página");
  const cruzado = await handler(
    post("/entrar", { token: TOKEN }, { origin: ORIGEN, "sec-fetch-site": "cross-site" }),
  );
  assertEquals(cruzado.status, 403, "sec-fetch-site cross-site manda sobre Origin");
  assertEquals(
    (await handler(post("/entrar", { token: TOKEN }, { origin: "null" }))).status,
    403,
    "Origin null sin sec-fetch-site",
  );
});

Deno.test("crear una orden normal no pone labels de cola", async () => {
  const sim = simulador();
  const handler = crearHandler(config({ fetch: sim.fetch }));
  const cookie = await entrar(handler);
  const response = await handler(
    post("/orden", { titulo: "Revisar la calle", cuerpo: "Detalle", modo: "issue" }, { cookie }),
  );
  assertEquals(response.status, 303, "redirige tras crear");
  assertEquals(response.headers.get("location"), "/?creado=1234", "a la sala con aviso");
  const creada = sim.llamadas.find((l) => l.method === "POST" && l.url.endsWith("/issues"));
  assert(creada, "llamó a crear issue");
  const cuerpo = JSON.parse(creada.body);
  assertEquals(cuerpo.labels.length, 0, "sin labels");
  assert(cuerpo.body.includes("sala de mando"), "firma de origen");
});

Deno.test("delegar al pool añade agent:auto y el plan en la misma llamada", () => {
  const form = new FormData();
  form.set("titulo", "Corte delegado");
  form.set("modo", "pool");
  form.set("objetivo", "Hacer algo concreto");
  form.set("rutas", "godot/guion/a.gd\ngodot/pruebas/b.gd\n");
  const orden = construirOrden(form);
  assert(typeof orden !== "string", "orden válida");
  assertEquals(orden.labels.join(","), "agent:auto", "label de cola");
  const plan = /AGENT_PLAN_BEGIN\n(.*)\nAGENT_PLAN_END/.exec(orden.cuerpo);
  assert(plan, "bloque de plan sin valla de código");
  assertEquals(JSON.parse(plan[1]).files.length, 2, "rutas del plan");
});

Deno.test("las órdenes inválidas se rechazan sin llamar a GitHub", async () => {
  const casos: Array<[Record<string, string>, string]> = [
    [{ titulo: "abc" }, "título corto"],
    [{ titulo: "Plan raro", modo: "pool", objetivo: "x", rutas: "../fuera" }, "ruta con .."],
    [{ titulo: "Plan raro", modo: "pool", objetivo: "x", rutas: "/abs" }, "ruta absoluta"],
    [{ titulo: "Plan cojo", modo: "pool", rutas: "a.gd" }, "plan sin objetivo"],
    [{ titulo: "Plan sin pool", modo: "issue", objetivo: "x", rutas: "a.gd" }, "plan sin delegar"],
  ];
  for (const [campos, motivo] of casos) {
    const form = new FormData();
    for (const [k, v] of Object.entries(campos)) form.set(k, v);
    assert(typeof construirOrden(form) === "string", motivo);
  }

  const sim = simulador();
  const handler = crearHandler(config({ fetch: sim.fetch }));
  const cookie = await entrar(handler);
  const response = await handler(post("/orden", { titulo: "abc" }, { cookie }));
  assertEquals(response.status, 400, "400 en la sala");
  assert(!sim.llamadas.some((l) => l.method === "POST"), "no crea nada");
});

Deno.test("reservasVivas se queda con la última entrada por issue", () => {
  const vivas = reservasVivas([
    {
      body: "CLAIM issue=#1 agent=A branch=b1 files=x",
      created_at: "2026-09-28T10:00:00Z",
      author_association: "OWNER",
    },
    {
      body: "RELEASE issue=#1 motivo=hecho",
      created_at: "2026-09-28T11:00:00Z",
      author_association: "COLLABORATOR",
    },
    {
      body: "CLAIM issue=#2 agent=B branch=b2 files=y",
      created_at: "2026-09-28T12:00:00Z",
      author_association: "MEMBER",
    },
    {
      body: "PR_READY issue=#2 pr=#20 sha=abc",
      created_at: "2026-09-28T13:00:00Z",
      user: { login: "github-actions[bot]" },
    },
    { body: "comentario suelto sin formato", created_at: "2026-09-28T14:00:00Z" },
  ]);
  assertEquals(vivas.length, 1, "solo #2 sigue viva");
  assertEquals(vivas[0].tipo, "PR_READY", "último estado");
  assertEquals(vivas[0].agente, "B", "hereda el agente del CLAIM");
  assertEquals(vivas[0].pr, "20", "PR asociada");
});

Deno.test("comentarios externos no crean ni liberan reservas visibles", () => {
  const vivas = reservasVivas([
    { body: "CLAIM issue=#7 agent=Real branch=feature/7", author_association: "OWNER" },
    { body: "RELEASE issue=#7", author_association: "NONE", user: { login: "externo" } },
    { body: "CLAIM issue=#8 agent=Falso branch=feature/8", author_association: "CONTRIBUTOR" },
    { body: "CLAIM issue=#9 agent=SinMetadatos branch=feature/9" },
    { body: "CLAIM issue=#10 agent=Bot branch=feature/10", user: { login: "github-actions[bot]" } },
    { body: "RELEASE issue=#10", author_association: "NONE", user: { login: "otro[bot]" } },
  ]);
  assertEquals(vivas.map((r) => r.issue).join(","), "7,10", "solo humanos autorizados y Actions");
});

Deno.test("esc neutraliza los caracteres de HTML", () => {
  assertEquals(
    esc(`<a href="x">'&'</a>`),
    "&lt;a href=&quot;x&quot;&gt;&#39;&amp;&#39;&lt;/a&gt;",
    "esc",
  );
});
