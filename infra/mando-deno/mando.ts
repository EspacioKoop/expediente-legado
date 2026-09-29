// Sala de mando y órdenes de expediente-legado (#1778).
//
// App aparte del gateway siga98-feedback-deno: vive en otra org de Deno Deploy
// y no tiene KV, así que un fallo aquí no puede tocar memoria ni leases. Solo
// lee GitHub y el /health del gateway, y crea issues cuando se lo piden.

const VERSION = 1;
const MIN_TOKEN = 32;
const SESION_MS = 30 * 24 * 60 * 60 * 1000;
const CACHE_MS = 30 * 1000;
const COOKIE = "mando";
const VENTANA_RESERVAS_MS = 72 * 60 * 60 * 1000;
const MAX_TITULO = 200;
const MAX_CUERPO = 8000;
const MAX_RUTAS_PLAN = 20;

// Orden de lectura: lo que exige atención primero.
const LABELS_POOL = [
  "agent:needs-human",
  "agent:working",
  "agent:pr-open",
  "agent:auto",
  "agent:pool",
  "agent:qwen",
  "agent:gemini",
];

export interface MandoConfig {
  token: string;
  githubToken: string;
  repository: string;
  gatewayUrl: string;
  registroIssue: number;
  fetch: typeof fetch;
  now: () => number;
}

export function configDesdeEntorno(): MandoConfig {
  return {
    token: Deno.env.get("MANDO_TOKEN") ?? "",
    githubToken: Deno.env.get("GITHUB_TOKEN") ?? "",
    repository: Deno.env.get("GITHUB_REPOSITORY") ?? "EspacioKoop/expediente-legado",
    gatewayUrl: (Deno.env.get("MANDO_GATEWAY_URL") ??
      "https://siga98-feedback-deno.expediente-legado.deno.net").replace(/\/+$/, ""),
    registroIssue: 1713,
    fetch: (input, init) => fetch(input, init),
    now: () => Date.now(),
  };
}

// ---------------------------------------------------------------- utilidades

export function esc(value: unknown): string {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function html(body: string, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(body, {
    status,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
      "referrer-policy": "no-referrer",
      "x-frame-options": "DENY",
      "content-security-policy":
        "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; frame-ancestors 'none'",
      ...headers,
    },
  });
}

function redirigir(location: string, headers: Record<string, string> = {}): Response {
  return new Response(null, {
    status: 303,
    headers: { location, "cache-control": "no-store", ...headers },
  });
}

function hace(ms: number): string {
  const minutos = Math.max(0, Math.round(ms / 60000));
  if (minutos < 60) return `hace ${minutos} min`;
  const horas = Math.round(minutos / 60);
  if (horas < 48) return `hace ${horas} h`;
  return `hace ${Math.round(horas / 24)} d`;
}

// ------------------------------------------------------------------- sesión

async function hmac(clave: string, mensaje: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(clave),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const firma = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(mensaje));
  return [...new Uint8Array(firma)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

// Compara resúmenes de igual longitud para no filtrar nada por tiempo.
async function iguales(a: string, b: string): Promise<boolean> {
  const [x, y] = await Promise.all(
    [a, b].map(async (v) =>
      new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(v)))
    ),
  );
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
  return diff === 0;
}

// La cookie es `caducidad.firma`: rotar MANDO_TOKEN invalida todas las sesiones.
async function crearSesion(config: MandoConfig): Promise<string> {
  const caduca = config.now() + SESION_MS;
  return `${caduca}.${await hmac(config.token, `mando-sesion-v1|${caduca}`)}`;
}

async function sesionValida(request: Request, config: MandoConfig): Promise<boolean> {
  const cookies = request.headers.get("cookie") ?? "";
  const valor = cookies.split(/;\s*/).find((c) => c.startsWith(COOKIE + "="))?.slice(
    COOKIE.length + 1,
  );
  const match = /^(\d{13})\.([0-9a-f]{64})$/.exec(valor ?? "");
  if (!match) return false;
  const caduca = Number(match[1]);
  if (caduca < config.now()) return false;
  return await iguales(match[2], await hmac(config.token, `mando-sesion-v1|${caduca}`));
}

function cookieSesion(valor: string, maxAge: number): string {
  return `${COOKIE}=${valor}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=${maxAge}`;
}

// Un POST solo vale si viene de esta misma web (CSRF).
function mismoOrigen(request: Request): boolean {
  const origin = request.headers.get("origin");
  if (origin) return origin === new URL(request.url).origin;
  return request.headers.get("sec-fetch-site") === "same-origin";
}

// ------------------------------------------------------------------- GitHub

interface IssuePool {
  number: number;
  title: string;
  url: string;
  labels: string[];
  updated: string;
}

interface PrAbierta {
  number: number;
  title: string;
  url: string;
  draft: boolean;
  autor: string;
  rama: string;
  updated: string;
  ci: string;
}

export interface Reserva {
  tipo: string;
  issue: number;
  agente: string;
  rama: string;
  pr: string;
  fecha: string;
}

interface Salud {
  version: unknown;
  flags: Record<string, unknown>;
}

interface Estado {
  pool: IssuePool[] | string;
  prs: PrAbierta[] | string;
  reservas: Reserva[] | string;
  salud: Salud | string;
  leido: number;
}

async function gh(
  config: MandoConfig,
  path: string,
  init: RequestInit = {},
): Promise<unknown> {
  const response = await config.fetch(`https://api.github.com${path}`, {
    ...init,
    headers: {
      accept: "application/vnd.github+json",
      authorization: `Bearer ${config.githubToken}`,
      "x-github-api-version": "2022-11-28",
      "user-agent": "siga98-mando",
      ...(init.body ? { "content-type": "application/json" } : {}),
    },
  });
  if (!response.ok) throw new Error(`GitHub ${response.status}`);
  return await response.json();
}

async function leerPool(config: MandoConfig): Promise<IssuePool[]> {
  const q = `repo:${config.repository} is:issue is:open label:${LABELS_POOL.join(",")}`;
  const data = await gh(config, `/search/issues?per_page=50&q=${encodeURIComponent(q)}`) as {
    items?: Array<Record<string, unknown>>;
  };
  return (data.items ?? []).map((item) => ({
    number: Number(item.number),
    title: String(item.title ?? ""),
    url: String(item.html_url ?? ""),
    labels: ((item.labels ?? []) as Array<{ name?: string }>).map((l) => String(l.name ?? "")),
    updated: String(item.updated_at ?? ""),
  }));
}

async function leerPrs(config: MandoConfig): Promise<PrAbierta[]> {
  const [owner, name] = config.repository.split("/");
  const query = `query($owner:String!,$name:String!){repository(owner:$owner,name:$name){
    pullRequests(states:OPEN,first:30,orderBy:{field:UPDATED_AT,direction:DESC}){nodes{
      number title url isDraft headRefName updatedAt author{login}
      commits(last:1){nodes{commit{statusCheckRollup{state}}}}}}}}`;
  const data = await gh(config, "/graphql", {
    method: "POST",
    body: JSON.stringify({ query, variables: { owner, name } }),
  }) as {
    data?: {
      repository?: { pullRequests?: { nodes?: Array<Record<string, unknown>> } };
    };
  };
  const nodes = data.data?.repository?.pullRequests?.nodes ?? [];
  return nodes.map((pr) => {
    const commits = pr.commits as {
      nodes?: Array<{ commit?: { statusCheckRollup?: { state?: string } | null } }>;
    };
    return {
      number: Number(pr.number),
      title: String(pr.title ?? ""),
      url: String(pr.url ?? ""),
      draft: pr.isDraft === true,
      autor: String((pr.author as { login?: string } | null)?.login ?? "?"),
      rama: String(pr.headRefName ?? ""),
      updated: String(pr.updatedAt ?? ""),
      ci: String(commits?.nodes?.[0]?.commit?.statusCheckRollup?.state ?? "SIN CI"),
    };
  });
}

const TIPOS_REGISTRO = /^(CLAIM|HEARTBEAT|PR_DRAFT|PR_READY|CI_FIX|RELEASE)\b/;

// Reduce el registro de #1713 a la última entrada por issue: si es RELEASE,
// la reserva ya no está viva. Solo mira la ventana reciente (las leases duran
// 48 h), así que no es un sustituto del workflow de reservas.
export function reservasVivas(
  comentarios: Array<{ body?: string; created_at?: string }>,
): Reserva[] {
  const ultima = new Map<number, Reserva>();
  for (const comentario of comentarios) {
    const linea = (comentario.body ?? "").trim().split("\n", 1)[0];
    const tipo = TIPOS_REGISTRO.exec(linea)?.[1];
    const issue = Number(/\bissue=#(\d+)/.exec(linea)?.[1]);
    if (!tipo || !Number.isInteger(issue) || issue <= 0) continue;
    const previa = ultima.get(issue);
    ultima.set(issue, {
      tipo,
      issue,
      agente: /\bagent=(\S+)/.exec(linea)?.[1] ?? previa?.agente ?? "",
      rama: /\bbranch=(\S+)/.exec(linea)?.[1] ?? previa?.rama ?? "",
      pr: /\bpr=#?(\d+)/.exec(linea)?.[1] ?? previa?.pr ?? "",
      fecha: comentario.created_at ?? "",
    });
  }
  return [...ultima.values()]
    .filter((r) => r.tipo !== "RELEASE")
    .sort((a, b) => b.fecha.localeCompare(a.fecha));
}

async function leerReservas(config: MandoConfig): Promise<Reserva[]> {
  const desde = new Date(config.now() - VENTANA_RESERVAS_MS).toISOString();
  const comentarios: Array<{ body?: string; created_at?: string }> = [];
  for (let page = 1; page <= 3; page++) {
    const lote = await gh(
      config,
      `/repos/${config.repository}/issues/${config.registroIssue}/comments` +
        `?per_page=100&page=${page}&since=${encodeURIComponent(desde)}`,
    ) as Array<{ body?: string; created_at?: string }>;
    comentarios.push(...lote);
    if (lote.length < 100) break;
  }
  return reservasVivas(comentarios);
}

async function leerSalud(config: MandoConfig): Promise<Salud> {
  const response = await config.fetch(`${config.gatewayUrl}/health`);
  if (!response.ok) throw new Error(`gateway ${response.status}`);
  const data = await response.json() as Record<string, unknown>;
  const flags: Record<string, unknown> = {};
  for (const [clave, valor] of Object.entries(data)) {
    if (typeof valor === "boolean") flags[clave] = valor;
  }
  return { version: data.version, flags };
}

// Cada sección falla por separado: un 403 de GitHub no deja la sala en blanco.
async function seccion<T>(leer: () => Promise<T>): Promise<T | string> {
  try {
    return await leer();
  } catch (error) {
    console.error("Sala de mando", error);
    return error instanceof Error ? error.message : "error";
  }
}

let cache: Estado | null = null;

async function leerEstado(config: MandoConfig, fresco: boolean): Promise<Estado> {
  if (!fresco && cache && config.now() - cache.leido < CACHE_MS) return cache;
  const [pool, prs, reservas, salud] = await Promise.all([
    seccion(() => leerPool(config)),
    seccion(() => leerPrs(config)),
    seccion(() => leerReservas(config)),
    seccion(() => leerSalud(config)),
  ]);
  cache = { pool, prs, reservas, salud, leido: config.now() };
  return cache;
}

export function vaciarCache(): void {
  cache = null;
}

// ------------------------------------------------------------------ órdenes

export interface Orden {
  titulo: string;
  cuerpo: string;
  labels: string[];
}

// Convierte el formulario en un issue. Con «delegar», el label de cola va en
// la misma llamada que crea el issue: un issue sin label parece libre.
export function construirOrden(form: FormData): Orden | string {
  const titulo = String(form.get("titulo") ?? "").trim().replace(/\s+/g, " ");
  const texto = String(form.get("cuerpo") ?? "").trim();
  const delegar = form.get("modo") === "pool";
  const objetivo = String(form.get("objetivo") ?? "").trim().replace(/\s+/g, " ");
  const rutas = String(form.get("rutas") ?? "")
    .split("\n")
    .map((r) => r.trim())
    .filter(Boolean);

  if (titulo.length < 5 || titulo.length > MAX_TITULO) {
    return "El título debe tener entre 5 y 200 caracteres.";
  }
  if (texto.length > MAX_CUERPO) return "La descripción supera 8000 caracteres.";
  if (rutas.length > MAX_RUTAS_PLAN) return "Un plan admite como mucho 20 rutas.";
  for (const ruta of rutas) {
    if (ruta.startsWith("/") || ruta.split("/").includes("..") || /[*?[\]\s]/.test(ruta)) {
      return `Ruta no válida en el plan: ${ruta}`;
    }
  }
  if (rutas.length > 0 !== (objetivo.length > 0)) {
    return "Un plan necesita rutas y objetivo a la vez (o ninguno de los dos).";
  }
  if (rutas.length > 0 && !delegar) {
    return "Un plan solo tiene sentido al delegar en el pool.";
  }

  const partes = [texto];
  if (rutas.length > 0) {
    partes.push(
      "AGENT_PLAN_BEGIN\n" + JSON.stringify({ files: rutas, goal: objetivo }) +
        "\nAGENT_PLAN_END",
    );
  }
  partes.push("---\nCreado desde la sala de mando (#1778).");
  return {
    titulo,
    cuerpo: partes.filter(Boolean).join("\n\n"),
    labels: delegar ? ["agent:auto"] : [],
  };
}

async function crearIssue(config: MandoConfig, orden: Orden): Promise<number> {
  const data = await gh(config, `/repos/${config.repository}/issues`, {
    method: "POST",
    body: JSON.stringify({ title: orden.titulo, body: orden.cuerpo, labels: orden.labels }),
  }) as { number?: number };
  return Number(data.number);
}

// -------------------------------------------------------------------- vistas

const ESTILO = `
:root{--papel:#eef0e6;--tarjeta:#f7f8f2;--tinta:#1f2a36;--tinta-2:#4d5866;--regla:#c5c9b8;
--carbon:#2f4f8f;--sello:#b3372b;--ambar:#9a6a12;--verde:#3d6b3a;color-scheme:light}
@media (prefers-color-scheme:dark){:root{--papel:#15191e;--tarjeta:#20262e;--tinta:#e3e6dc;
--tinta-2:#a4acb6;--regla:#343c46;--carbon:#93abe2;--sello:#e56b5d;--ambar:#d9a441;--verde:#7fb77a;
color-scheme:dark}}
*{box-sizing:border-box}
body{margin:0;background:var(--papel);color:var(--tinta);font:15px/1.5 system-ui,sans-serif;
padding:0 16px 48px}
main{max-width:960px;margin:0 auto}
header{display:flex;flex-wrap:wrap;justify-content:space-between;align-items:baseline;gap:8px;
padding:20px 0 12px;border-bottom:2px solid var(--tinta)}
h1{margin:0;font:800 26px/1.1 system-ui,sans-serif;letter-spacing:-.01em}
h2{font:700 12px/1.3 ui-monospace,monospace;text-transform:uppercase;letter-spacing:.12em;
color:var(--tinta-2);margin:28px 0 8px}
.dato{font:12px ui-monospace,monospace;color:var(--tinta-2)}
ul{list-style:none;margin:0;padding:0;border-top:1px solid var(--regla)}
li{display:flex;flex-wrap:wrap;gap:4px 10px;align-items:baseline;padding:9px 0;
border-bottom:1px solid var(--regla)}
li a{color:var(--tinta);font-weight:600;text-decoration:none;flex:1 1 60%}
li a:hover{text-decoration:underline}
.num{font:700 13px ui-monospace,monospace;color:var(--carbon);min-width:5ch}
.sello{font:700 10.5px/1 ui-monospace,monospace;text-transform:uppercase;letter-spacing:.08em;
padding:3px 5px;border:1.5px solid currentColor;border-radius:2px;white-space:nowrap}
.mal{color:var(--sello)}.aviso{color:var(--ambar)}.bien{color:var(--verde)}.neutro{color:var(--tinta-2)}
.vacio,.error{padding:10px 0;color:var(--tinta-2)}.error{color:var(--sello)}
form{display:grid;gap:10px;background:var(--tarjeta);border:1px solid var(--regla);
border-radius:3px;padding:14px}
label{display:grid;gap:4px;font-size:13px;color:var(--tinta-2)}
input[type=text],input[type=password],textarea{font:inherit;color:var(--tinta);
background:var(--papel);border:1px solid var(--regla);border-radius:3px;padding:8px;width:100%}
textarea{min-height:90px}
fieldset{border:0;padding:0;margin:0;display:flex;flex-wrap:wrap;gap:6px 18px}
fieldset label{display:flex;gap:6px;align-items:center;color:var(--tinta)}
button{font:700 14px system-ui,sans-serif;background:var(--carbon);color:var(--tarjeta);border:0;
border-radius:3px;padding:10px 16px;cursor:pointer;justify-self:start}
button.plano{background:none;color:var(--tinta-2);padding:0;font-weight:400;text-decoration:underline}
:focus-visible{outline:2px solid var(--carbon);outline-offset:2px}
.aviso-caja{padding:10px 12px;border-left:3px solid var(--verde);background:var(--tarjeta);margin-top:16px}
.aviso-caja.mal{border-left-color:var(--sello)}
details summary{cursor:pointer;color:var(--tinta-2);font-size:13px}
`;

function pagina(titulo: string, contenido: string): string {
  return `<!doctype html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex"><title>${esc(titulo)}</title><style>${ESTILO}</style>
</head><body><main>${contenido}</main></body></html>`;
}

function vistaEntrar(error = ""): string {
  return pagina(
    "Sala de mando",
    `<header><h1>Sala de mando</h1><span class="dato">expediente-legado</span></header>
${error ? `<p class="aviso-caja mal">${esc(error)}</p>` : ""}
<h2>Acceso</h2>
<form method="post" action="/entrar">
  <label>Token de acceso<input type="password" name="token" id="token" autocomplete="current-password" required></label>
  <button type="submit">Entrar</button>
</form>`,
  );
}

function claseLabel(label: string): string {
  if (label === "agent:needs-human") return "mal";
  if (label === "agent:working" || label === "agent:pr-open") return "aviso";
  if (label.startsWith("agent:")) return "neutro";
  return "";
}

function claseCi(estado: string): string {
  if (estado === "SUCCESS") return "bien";
  if (estado === "FAILURE" || estado === "ERROR") return "mal";
  if (estado === "PENDING" || estado === "EXPECTED") return "aviso";
  return "neutro";
}

function lista<T>(datos: T[] | string, vacio: string, fila: (item: T) => string): string {
  if (typeof datos === "string") {
    return `<p class="error">No se pudo leer: ${esc(datos)}</p>`;
  }
  if (datos.length === 0) return `<p class="vacio">${esc(vacio)}</p>`;
  return `<ul>${datos.map(fila).join("")}</ul>`;
}

function vistaSala(config: MandoConfig, estado: Estado, aviso: string, error: string): string {
  const ahora = config.now();
  const orden = (issue: IssuePool) =>
    LABELS_POOL.findIndex((l) => issue.labels.includes(l)) + 1 || 99;
  const pool = typeof estado.pool === "string"
    ? estado.pool
    : [...estado.pool].sort((a, b) => orden(a) - orden(b));

  const salud = typeof estado.salud === "string"
    ? `<p class="error">Gateway sin respuesta: ${esc(estado.salud)}</p>`
    : `<ul><li><span class="num">v${esc(estado.salud.version)}</span>` +
      Object.entries(estado.salud.flags).map(([k, v]) =>
        `<span class="sello ${v ? "bien" : "mal"}">${esc(k)}</span>`
      ).join(" ") + `</li></ul>`;

  return pagina(
    "Sala de mando",
    `<header><h1>Sala de mando</h1>
<span class="dato">leído ${
      esc(hace(ahora - estado.leido))
    } · <a href="/?fresco=1">releer</a></span></header>
${aviso ? `<p class="aviso-caja">${aviso}</p>` : ""}
${error ? `<p class="aviso-caja mal">${esc(error)}</p>` : ""}

<h2>Pool · issues en cola</h2>
${
      lista(pool, "No hay issues en la cola del pool.", (i) =>
        `<li><span class="num">#${i.number}</span><a href="${esc(i.url)}">${esc(i.title)}</a>` +
        i.labels.filter((l) =>
          l.startsWith("agent:")
        ).map((l) =>
          `<span class="sello ${claseLabel(l)}">${esc(l.slice(6))}</span>`
        ).join("") + `<span class="dato">${esc(hace(ahora - Date.parse(i.updated)))}</span></li>`)
    }

<h2>PRs abiertas</h2>
${
      lista(estado.prs, "No hay PRs abiertas.", (p) =>
        `<li><span class="num">#${p.number}</span><a href="${esc(p.url)}">${esc(p.title)}</a>` +
        `<span class="sello ${claseCi(p.ci)}">${esc(p.ci.toLowerCase())}</span>` +
        (p.draft ? `<span class="sello neutro">draft</span>` : "") +
        `<span class="dato">${esc(p.rama)} · ${
          esc(hace(ahora - Date.parse(p.updated)))
        }</span></li>`)
    }

<h2>Reservas vivas en #${config.registroIssue} · últimas 72 h</h2>
${
      lista(estado.reservas, "Sin reservas vivas en la ventana.", (r) =>
        `<li><span class="num">#${r.issue}</span><span class="sello ${
          r.tipo === "PR_READY" ? "bien" : r.tipo === "CI_FIX" ? "aviso" : "neutro"
        }">${esc(r.tipo)}</span><span>${esc(r.agente || "?")}</span>` +
        `<span class="dato">${esc(r.rama)}${r.pr ? ` · PR #${esc(r.pr)}` : ""} · ${
          esc(hace(ahora - Date.parse(r.fecha)))
        }</span></li>`)
    }

<h2>Gateway de producción</h2>
${salud}

<h2>Nueva orden</h2>
<form method="post" action="/orden">
  <label>Título<input type="text" name="titulo" id="titulo" required minlength="5" maxlength="200"></label>
  <label>Descripción<textarea name="cuerpo" id="cuerpo" maxlength="8000"></textarea></label>
  <fieldset>
    <label><input type="radio" name="modo" id="modo-issue" value="issue" checked> Solo crear el issue</label>
    <label><input type="radio" name="modo" id="modo-pool" value="pool"> Delegar al pool (agent:auto)</label>
  </fieldset>
  <details><summary>Plan para el pool (opcional)</summary>
    <label>Objetivo<input type="text" name="objetivo" id="objetivo" maxlength="300"></label>
    <label>Rutas, una por línea<textarea name="rutas" id="rutas"></textarea></label>
  </details>
  <button type="submit">Crear issue</button>
</form>

<form method="post" action="/salir" style="margin-top:16px;background:none;border:0;padding:0">
  <button type="submit" class="plano">Cerrar sesión</button>
</form>`,
  );
}

// ------------------------------------------------------------------ handler

export function crearHandler(config: MandoConfig): (request: Request) => Promise<Response> {
  const configurado = config.token.length >= MIN_TOKEN && config.githubToken.length > 0;

  return async (request: Request): Promise<Response> => {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return new Response(
        JSON.stringify({ ok: true, service: "siga98-mando", version: VERSION, configurado }),
        { headers: { "content-type": "application/json", "cache-control": "no-store" } },
      );
    }

    // Fail-closed: sin token de acceso o de GitHub no se sirve nada más.
    if (!configurado) {
      return html(pagina("Sala de mando", "<h1>Sala de mando sin configurar</h1>"), 503);
    }

    if (url.pathname === "/entrar") {
      if (request.method === "GET") return html(vistaEntrar());
      if (request.method !== "POST") return html("", 405);
      if (!mismoOrigen(request)) return html(vistaEntrar("Petición rechazada."), 403);
      const form = await request.formData();
      if (!await iguales(String(form.get("token") ?? ""), config.token)) {
        return html(vistaEntrar("Token incorrecto."), 401);
      }
      return redirigir("/", {
        "set-cookie": cookieSesion(await crearSesion(config), SESION_MS / 1000),
      });
    }

    if (!await sesionValida(request, config)) {
      return request.method === "GET" ? redirigir("/entrar") : html("", 401);
    }

    if (url.pathname === "/salir" && request.method === "POST") {
      if (!mismoOrigen(request)) return html("", 403);
      return redirigir("/entrar", { "set-cookie": cookieSesion("", 0) });
    }

    if (url.pathname === "/orden" && request.method === "POST") {
      if (!mismoOrigen(request)) return html("", 403);
      const orden = construirOrden(await request.formData());
      if (typeof orden === "string") {
        const estado = await leerEstado(config, false);
        return html(vistaSala(config, estado, "", orden), 400);
      }
      try {
        const numero = await crearIssue(config, orden);
        return redirigir(`/?creado=${numero}${orden.labels.length ? "&pool=1" : ""}`);
      } catch (error) {
        const estado = await leerEstado(config, false);
        const motivo = error instanceof Error ? error.message : "error";
        return html(vistaSala(config, estado, "", `GitHub rechazó el issue (${motivo}).`), 502);
      }
    }

    if (url.pathname === "/" && request.method === "GET") {
      const creado = Number(url.searchParams.get("creado"));
      const aviso = Number.isInteger(creado) && creado > 0
        ? `Creado <a href="https://github.com/${
          esc(config.repository)
        }/issues/${creado}">#${creado}</a>${
          url.searchParams.get("pool") ? " y delegado al pool" : ""
        }.`
        : "";
      const estado = await leerEstado(config, url.searchParams.has("fresco") || aviso !== "");
      return html(vistaSala(config, estado, aviso, ""));
    }

    return html(pagina("Sala de mando", "<h1>No encontrado</h1>"), 404);
  };
}
