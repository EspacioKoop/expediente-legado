// Mesa de coordinación entre agentes, fase 1 (#1867): tablón de avisos y presencia.
//
// Existe porque la coordinación por comentarios de GitHub no avisa a nadie: cuando
// main se rompió por #1825, doce PRs llevaban cada una su copia del mismo parche.
// Un aviso activo («main rojo por X; lo arregla #Y») se consulta al arrancar y
// evita el trabajo duplicado. Las reservas siguen en #1713 hasta la fase 2.
import {
  type AgentIdentity,
  authenticateAgent,
  cleanTitle,
  containsPotentialSecret,
  json,
  NIVEL2_AGENTS,
  readJsonBody,
} from "./agent_memory.ts";

const AVISO_TIPOS = ["main-rojo", "en-curso", "bloqueo", "aviso"] as const;
type AvisoTipo = typeof AVISO_TIPOS[number];

const AVISO_MAX_TEXTO = 600;
const AVISO_TTL_HORAS_DEFECTO = 24;
const AVISO_TTL_HORAS_MAX = 72;
const AVISOS_LIMITE = 20;
// Un latido vale media hora: quien no renueva deja de figurar sin barrido manual.
const PRESENCIA_TTL_MS = 30 * 60 * 1000;
const PRESENCIA_LIMITE = 50;
const RESERVA_TTL_MIN_DEFECTO = 30;
const RESERVA_TTL_MIN_MAX = 48 * 60;
const RESERVA_LIMITE = 100;
const RESERVA_CAS_INTENTOS = 5;
const RESERVAS_KEY: Deno.KvKey = ["agent_coord", "reservas", "v1"];
const HORA_MS = 60 * 60 * 1000;

export interface Aviso {
  schema: 1;
  id: string;
  tipo: AvisoTipo;
  texto: string;
  refs: number[];
  paths: string[];
  agente: string;
  creado: string;
  caduca: string;
}

export interface Presencia {
  schema: 1;
  agente: string;
  issue: number;
  rama: string;
  tarea: string;
  visto: string;
}

export interface Reserva {
  schema: 1;
  id: string;
  agente: string;
  issue: number;
  rama: string;
  files: string[];
  goal: string;
  creado: string;
  visto: string;
  expira: string;
}

interface RegistroReservas {
  schema: 1;
  reservas: Reserva[];
}

type ClaimResultado =
  | { ok: true; reserva: Reserva }
  | { ok: false; error: "invalid_request" | "conflict" | "limit"; conflicts?: Reserva[] };

// El token de nivel 2 es compartido, así que el nombre lo declara el propio
// agente dentro de la lista cerrada; el pool firma siempre como `pool`.
function agenteDe(identity: AgentIdentity, declarado: unknown): string | null {
  if (identity.level === "pool") return "pool";
  const nombre = cleanTitle(declarado, 16).toLowerCase();
  return (NIVEL2_AGENTS as readonly string[]).includes(nombre) ? nombre : null;
}

function limpiarRefs(value: unknown): number[] {
  if (!Array.isArray(value)) return [];
  const refs = value
    .map((ref) => Number(String(ref).replace(/^#/, "")))
    .filter((ref) => Number.isInteger(ref) && ref > 0);
  return [...new Set(refs)].slice(0, 8);
}

function limpiarPaths(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  const paths: string[] = [];
  for (const raw of value) {
    const path = cleanTitle(raw, 200).replace(/\\/g, "/");
    if (!path || path.startsWith("/") || path.split("/").includes("..")) continue;
    if (!paths.includes(path)) paths.push(path);
    if (paths.length >= 12) break;
  }
  return paths;
}

async function avisar(
  kv: Deno.Kv,
  raw: Record<string, unknown>,
  identity: AgentIdentity,
): Promise<Aviso | null> {
  const agente = agenteDe(identity, raw.agente);
  const tipo = cleanTitle(raw.tipo, 16) as AvisoTipo;
  const texto = cleanTitle(raw.texto, AVISO_MAX_TEXTO);
  if (
    !agente ||
    !AVISO_TIPOS.includes(tipo) ||
    texto.length < 10 ||
    containsPotentialSecret(texto)
  ) {
    return null;
  }

  const horasPedidas = Number(raw.ttl_horas ?? AVISO_TTL_HORAS_DEFECTO);
  const horas = Number.isFinite(horasPedidas)
    ? Math.min(Math.max(horasPedidas, 1), AVISO_TTL_HORAS_MAX)
    : AVISO_TTL_HORAS_DEFECTO;
  const ahora = Date.now();
  const id = String(ahora) + "-" + crypto.randomUUID();
  const aviso: Aviso = {
    schema: 1,
    id,
    tipo,
    texto,
    refs: limpiarRefs(raw.refs),
    paths: limpiarPaths(raw.paths),
    agente,
    creado: new Date(ahora).toISOString(),
    caduca: new Date(ahora + horas * HORA_MS).toISOString(),
  };
  await kv.set(["agent_coord", "aviso", ahora, id], aviso, { expireIn: horas * HORA_MS });
  return aviso;
}

async function avisosActivos(kv: Deno.Kv): Promise<Aviso[]> {
  const ahora = new Date().toISOString();
  const avisos: Aviso[] = [];
  const iterator = kv.list<Aviso>(
    { prefix: ["agent_coord", "aviso"] },
    { reverse: true, limit: AVISOS_LIMITE * 2 },
  );
  for await (const entry of iterator) {
    // expireIn no borra en el acto: se filtra también por la fecha guardada.
    if (entry.value?.schema === 1 && entry.value.caduca > ahora) avisos.push(entry.value);
    if (avisos.length >= AVISOS_LIMITE) break;
  }
  return avisos;
}

// Cualquier agente autenticado puede resolver: quien arregla main no tiene por
// qué ser quien avisó de que estaba roto.
async function resolver(kv: Deno.Kv, raw: Record<string, unknown>): Promise<boolean> {
  const id = cleanTitle(raw.id, 80);
  const match = /^(\d{13})-[0-9a-f-]{36}$/.exec(id);
  if (!match) return false;
  const key = ["agent_coord", "aviso", Number(match[1]), id];
  const existente = await kv.get<Aviso>(key);
  if (!existente.value) return false;
  await kv.delete(key);
  return true;
}

async function latido(
  kv: Deno.Kv,
  raw: Record<string, unknown>,
  identity: AgentIdentity,
): Promise<Presencia | null> {
  const agente = agenteDe(identity, raw.agente);
  if (!agente) return null;
  const issue = Number(raw.issue ?? 0);
  const tarea = cleanTitle(raw.tarea, 200);
  if (containsPotentialSecret(tarea)) return null;

  const presencia: Presencia = {
    schema: 1,
    agente,
    issue: Number.isInteger(issue) && issue > 0 ? issue : 0,
    rama: cleanTitle(raw.rama, 120),
    tarea,
    visto: new Date().toISOString(),
  };
  // El pool tiene varios workers a la vez: se distinguen por run.
  const clave = identity.level === "pool"
    ? "pool:" + (cleanTitle(identity.claims.run_id, 40) || "desconocido")
    : agente;
  await kv.set(["agent_coord", "presencia", clave], presencia, { expireIn: PRESENCIA_TTL_MS });
  return presencia;
}

async function presentes(kv: Deno.Kv): Promise<Presencia[]> {
  const limite = new Date(Date.now() - PRESENCIA_TTL_MS).toISOString();
  const lista: Presencia[] = [];
  const iterator = kv.list<Presencia>(
    { prefix: ["agent_coord", "presencia"] },
    { limit: PRESENCIA_LIMITE },
  );
  for await (const entry of iterator) {
    if (entry.value?.schema === 1 && entry.value.visto > limite) lista.push(entry.value);
  }
  return lista.sort((a, b) => b.visto.localeCompare(a.visto));
}


function normalizarRutas(value: unknown): string[] | null {
  if (!Array.isArray(value) || value.length === 0 || value.length > 12) return null;
  const rutas: string[] = [];
  const vistas = new Set<string>();
  for (const raw of value) {
    if (typeof raw !== "string") return null;
    const original = raw.trim();
    if (!original || original.length > 200) return null;
    const ruta = original.replace(/\\/g, "/");
    if (ruta.startsWith("/") || /^[A-Za-z]:\//.test(ruta)) return null;
    const segmentos = ruta.split("/");
    if (segmentos.some((segmento) => !segmento || segmento === "." || segmento === "..")) {
      return null;
    }
    const canonica = segmentos.join("/");
    if (vistas.has(canonica)) return null;
    vistas.add(canonica);
    rutas.push(canonica);
  }
  return rutas.sort();
}

function rutasSolapan(a: string, b: string): boolean {
  return a === b || a.startsWith(b + "/") || b.startsWith(a + "/");
}

function ttlReservaMinutos(raw: Record<string, unknown>): number {
  const pedido = Number(raw.ttl_min ?? RESERVA_TTL_MIN_DEFECTO);
  if (!Number.isFinite(pedido)) return RESERVA_TTL_MIN_DEFECTO;
  return Math.min(Math.max(Math.trunc(pedido), 5), RESERVA_TTL_MIN_MAX);
}

function registroReservas(value: RegistroReservas | null): RegistroReservas {
  if (value === null) return { schema: 1, reservas: [] };
  if (value.schema !== 1 || !Array.isArray(value.reservas)) {
    throw new Error("registro_reservas_invalido");
  }
  return value;
}

function reservasVivas(reservas: Reserva[], ahora = Date.now()): Reserva[] {
  return reservas.filter((reserva) => {
    if (reserva?.schema !== 1 || typeof reserva.expira !== "string") return false;
    const expira = Date.parse(reserva.expira);
    return Number.isFinite(expira) && expira > ahora;
  });
}

async function claim(
  kv: Deno.Kv,
  raw: Record<string, unknown>,
  identity: AgentIdentity,
  repository: string,
): Promise<ClaimResultado> {
  const agente = agenteDe(identity, raw.agente);
  const issue = Number(raw.issue ?? 0);
  const rutas = normalizarRutas(raw.files);
  const rama = cleanTitle(raw.branch || raw.rama, 120);
  const goal = cleanTitle(raw.goal || raw.objetivo, 200);
  if (
    !agente ||
    !Number.isInteger(issue) ||
    issue <= 0 ||
    !rutas ||
    !rama ||
    !goal ||
    containsPotentialSecret(goal)
  ) {
    return { ok: false, error: "invalid_request" };
  }

  const historicas = await reservasHistoricas1713(repository);
  const conflictosHistoricos = historicas.filter((reserva) =>
    !(reserva.issue === issue && reserva.rama === rama && reserva.agente === agente) &&
    reserva.files.some((existente) =>
      rutas.some((solicitada) => rutasSolapan(existente, solicitada))
    )
  );
  if (conflictosHistoricos.length > 0) {
    return { ok: false, error: "conflict", conflicts: conflictosHistoricos };
  }

  for (let intento = 0; intento < RESERVA_CAS_INTENTOS; intento += 1) {
    const entry = await kv.get<RegistroReservas>(RESERVAS_KEY);
    const vivas = reservasVivas(registroReservas(entry.value).reservas);
    const conflicts = vivas.filter((reserva) =>
      reserva.files.some((existente) =>
        rutas.some((solicitada) => rutasSolapan(existente, solicitada))
      )
    );
    if (conflicts.length > 0) {
      return { ok: false, error: "conflict", conflicts };
    }
    if (vivas.length >= RESERVA_LIMITE) {
      return { ok: false, error: "limit" };
    }

    const ahora = Date.now();
    const ttlMin = ttlReservaMinutos(raw);
    const reserva: Reserva = {
      schema: 1,
      id: crypto.randomUUID(),
      agente,
      issue,
      rama,
      files: rutas,
      goal,
      creado: new Date(ahora).toISOString(),
      visto: new Date(ahora).toISOString(),
      expira: new Date(ahora + ttlMin * 60 * 1000).toISOString(),
    };
    const siguiente: RegistroReservas = { schema: 1, reservas: [...vivas, reserva] };
    const committed = await kv.atomic()
      .check(entry)
      .set(RESERVAS_KEY, siguiente)
      .commit();
    if (committed.ok) return { ok: true, reserva };
  }

  throw new Error("claim_cas_agotado");
}

async function heartbeat(
  kv: Deno.Kv,
  raw: Record<string, unknown>,
  identity: AgentIdentity,
): Promise<Reserva | null> {
  const agente = agenteDe(identity, raw.agente);
  const id = cleanTitle(raw.id, 80);
  if (!agente || !id) return null;

  for (let intento = 0; intento < RESERVA_CAS_INTENTOS; intento += 1) {
    const entry = await kv.get<RegistroReservas>(RESERVAS_KEY);
    const vivas = reservasVivas(registroReservas(entry.value).reservas);
    const indice = vivas.findIndex((reserva) => reserva.id === id);
    if (indice < 0 || vivas[indice].agente !== agente) return null;

    const ahora = Date.now();
    const renovada: Reserva = {
      ...vivas[indice],
      visto: new Date(ahora).toISOString(),
      expira: new Date(ahora + ttlReservaMinutos(raw) * 60 * 1000).toISOString(),
    };
    const siguientes = vivas.slice();
    siguientes[indice] = renovada;
    const committed = await kv.atomic()
      .check(entry)
      .set(RESERVAS_KEY, { schema: 1, reservas: siguientes } satisfies RegistroReservas)
      .commit();
    if (committed.ok) return renovada;
  }

  throw new Error("heartbeat_cas_agotado");
}

async function release(
  kv: Deno.Kv,
  raw: Record<string, unknown>,
  identity: AgentIdentity,
): Promise<{ ok: boolean; reserva: Reserva | null }> {
  const agente = agenteDe(identity, raw.agente);
  const id = cleanTitle(raw.id, 80);
  if (!agente || !id) return { ok: false, reserva: null };

  for (let intento = 0; intento < RESERVA_CAS_INTENTOS; intento += 1) {
    const entry = await kv.get<RegistroReservas>(RESERVAS_KEY);
    const vivas = reservasVivas(registroReservas(entry.value).reservas);
    const reserva = vivas.find((item) => item.id === id) ?? null;
    if (!reserva) return { ok: true, reserva: null };
    if (reserva.agente !== agente) return { ok: false, reserva: null };

    const committed = await kv.atomic()
      .check(entry)
      .set(
        RESERVAS_KEY,
        { schema: 1, reservas: vivas.filter((item) => item.id !== id) } satisfies RegistroReservas,
      )
      .commit();
    if (committed.ok) return { ok: true, reserva };
  }

  throw new Error("release_cas_agotado");
}

async function claims(kv: Deno.Kv): Promise<Reserva[]> {
  const entry = await kv.get<RegistroReservas>(RESERVAS_KEY);
  return reservasVivas(registroReservas(entry.value).reservas)
    .sort((a, b) => a.expira.localeCompare(b.expira) || a.id.localeCompare(b.id));
}


function campoComentario(texto: string, nombre: string): string {
  const match = new RegExp("(?:^|\\s)" + nombre + "=([^\\s]+)").exec(texto);
  return match?.[1] ?? "";
}

function agenteHistorico(texto: string): string {
  const limpio = cleanTitle(texto, 32).toLowerCase();
  return limpio === "pool" || limpio.startsWith("pool-") ? "pool" : limpio;
}

function leaseHistoricoMinutos(texto: string): number {
  const match = /(?:^|\s)lease=(\d+)([hm])(?:\s|$)/.exec(texto);
  if (!match) return RESERVA_TTL_MIN_MAX;
  const cantidad = Number(match[1]);
  const minutos = match[2] === "h" ? cantidad * 60 : cantidad;
  return Math.min(Math.max(minutos, 5), RESERVA_TTL_MIN_MAX);
}

async function reservasHistoricas1713(repository: string): Promise<Reserva[]> {
  const ahora = Date.now();
  const desde = new Date(ahora - RESERVA_TTL_MIN_MAX * 60 * 1000).toISOString();
  const token = Deno.env.get("GITHUB_TOKEN") ?? "";
  const headers: Record<string, string> = {
    accept: "application/vnd.github+json",
    "user-agent": "SIGA98-Agent-Coord",
    "x-github-api-version": "2022-11-28",
  };
  if (token) headers.authorization = `Bearer ${token}`;

  const comentarios: Array<{ body: string; created_at: string }> = [];
  for (let pagina = 1; pagina <= 20; pagina += 1) {
    const url =
      `https://api.github.com/repos/${repository}/issues/1713/comments?per_page=100&page=${pagina}&since=${encodeURIComponent(desde)}`;
    const response = await fetch(url, { headers });
    if (!response.ok) {
      throw new Error(`github_1713_${response.status}`);
    }
    const data = await response.json();
    if (!Array.isArray(data)) throw new Error("github_1713_respuesta_invalida");
    for (const item of data) {
      const body = typeof item?.body === "string" ? item.body.trim() : "";
      const createdAt = typeof item?.created_at === "string" ? item.created_at : "";
      if (body && Number.isFinite(Date.parse(createdAt))) {
        comentarios.push({ body, created_at: createdAt });
      }
    }
    if (data.length < 100) break;
    if (pagina === 20) throw new Error("github_1713_historial_demasiado_grande");
  }

  comentarios.sort((a, b) => a.created_at.localeCompare(b.created_at));
  const activas = new Map<string, { reserva: Reserva; leaseMin: number }>();
  for (const comentario of comentarios) {
    const texto = comentario.body;
    const tipo = texto.startsWith("CLAIM ")
      ? "claim"
      : texto.startsWith("HEARTBEAT ")
      ? "heartbeat"
      : texto.startsWith("RELEASE ")
      ? "release"
      : "";
    if (!tipo) continue;

    const issue = Number(campoComentario(texto, "issue").replace(/^#/, ""));
    const rama = campoComentario(texto, "branch");
    if (!Number.isInteger(issue) || issue <= 0 || !rama) continue;
    const clave = `${issue}|${rama}`;

    if (tipo === "release") {
      activas.delete(clave);
      continue;
    }
    if (tipo === "heartbeat") {
      const actual = activas.get(clave);
      if (!actual) continue;
      const visto = Date.parse(comentario.created_at);
      actual.reserva.visto = comentario.created_at;
      actual.reserva.expira = new Date(visto + actual.leaseMin * 60 * 1000).toISOString();
      continue;
    }

    const filesRaw = campoComentario(texto, "files");
    const files = normalizarRutas(filesRaw ? filesRaw.split(",") : []);
    if (!files) throw new Error("github_1713_claim_rutas_invalidas");
    const leaseMin = leaseHistoricoMinutos(texto);
    const creadoMs = Date.parse(comentario.created_at);
    const agente = agenteHistorico(campoComentario(texto, "agent")) || "historico";
    activas.set(clave, {
      leaseMin,
      reserva: {
        schema: 1,
        id: `github-1713-${issue}-${rama}`,
        agente,
        issue,
        rama,
        files,
        goal: "reserva histórica #1713",
        creado: comentario.created_at,
        visto: comentario.created_at,
        expira: new Date(creadoMs + leaseMin * 60 * 1000).toISOString(),
      },
    });
  }

  return [...activas.values()]
    .map((item) => item.reserva)
    .filter((reserva) => Date.parse(reserva.expira) > ahora);
}

async function espejo1713(repository: string, texto: string): Promise<boolean> {
  const token = Deno.env.get("GITHUB_TOKEN") ?? "";
  if (!token) {
    console.error("Agent coord: GITHUB_TOKEN ausente; no se pudo espejar #1713");
    return false;
  }
  const response = await fetch(
    `https://api.github.com/repos/${repository}/issues/1713/comments`,
    {
      method: "POST",
      headers: {
        authorization: `Bearer ${token}`,
        accept: "application/vnd.github+json",
        "content-type": "application/json",
        "user-agent": "SIGA98-Agent-Coord",
        "x-github-api-version": "2022-11-28",
      },
      body: JSON.stringify({ body: texto }),
    },
  );
  if (!response.ok) {
    console.error("Agent coord: espejo #1713 devolvió", response.status);
    return false;
  }
  return true;
}

function textoClaim(reserva: Reserva): string {
  return [
    "AGENT_COORD_CLAIM",
    `id=${reserva.id}`,
    `agent=${reserva.agente}`,
    `issue=#${reserva.issue}`,
    `branch=${reserva.rama}`,
    `files=${reserva.files.join(",")}`,
    `expires=${reserva.expira}`,
  ].join(" ");
}

function textoRelease(reserva: Reserva, raw: Record<string, unknown>): string {
  let reason = cleanTitle(raw.reason, 80);
  if (!reason || containsPotentialSecret(reason)) reason = "unspecified";
  return [
    "AGENT_COORD_RELEASE",
    `id=${reserva.id}`,
    `agent=${reserva.agente}`,
    `issue=#${reserva.issue}`,
    `reason=${reason}`,
  ].join(" ");
}

export async function handleAgentCoord(
  request: Request,
  url: URL,
  kv: Deno.Kv,
  repository: string,
): Promise<Response> {
  if (request.method !== "POST") {
    return json({ ok: false, error: "method_not_allowed" }, 405);
  }

  let identity: AgentIdentity | null;
  try {
    identity = await authenticateAgent(request, repository);
  } catch (error) {
    console.error("Agent coord OIDC failure", error);
    return json({ ok: false, error: "service_unavailable" }, 503);
  }
  if (!identity) return json({ ok: false, error: "unauthorized" }, 401);

  let raw: Record<string, unknown>;
  try {
    const body = await readJsonBody(request);
    if (!body || typeof body !== "object" || (body as { schema?: unknown }).schema !== 1) {
      return json({ ok: false, error: "invalid_request" }, 400);
    }
    raw = body as Record<string, unknown>;
  } catch (error) {
    const tooLarge = error instanceof Error && error.message === "payload_too_large";
    return json(
      { ok: false, error: tooLarge ? "payload_too_large" : "invalid_json" },
      tooLarge ? 413 : 400,
    );
  }

  switch (url.pathname) {
    case "/api/agent-coord/avisar": {
      const aviso = await avisar(kv, raw, identity);
      return aviso
        ? json({ ok: true, aviso }, 201)
        : json({ ok: false, error: "invalid_aviso" }, 400);
    }
    case "/api/agent-coord/avisos":
      return json({ ok: true, avisos: await avisosActivos(kv) });
    case "/api/agent-coord/resolver":
      return await resolver(kv, raw)
        ? json({ ok: true })
        : json({ ok: false, error: "not_found" }, 404);
    case "/api/agent-coord/latido": {
      const presencia = await latido(kv, raw, identity);
      return presencia
        ? json({ ok: true, presencia })
        : json({ ok: false, error: "invalid_latido" }, 400);
    }
    case "/api/agent-coord/presentes":
      return json({ ok: true, presentes: await presentes(kv) });

    case "/api/agent-coord/claim": {
      try {
        const resultado = await claim(kv, raw, identity, repository);
        if (!resultado.ok) {
          const status = resultado.error === "conflict" ? 409 : 400;
          return json(
            { ok: false, error: resultado.error, conflicts: resultado.conflicts ?? [] },
            status,
          );
        }
        const espejo = await espejo1713(repository, textoClaim(resultado.reserva));
        return json({ ok: true, reserva: resultado.reserva, espejo_1713: espejo }, 201);
      } catch (error) {
        console.error("Agent coord claim failure", error);
        return json({ ok: false, error: "service_unavailable" }, 503);
      }
    }
    case "/api/agent-coord/heartbeat": {
      try {
        const reserva = await heartbeat(kv, raw, identity);
        return reserva
          ? json({ ok: true, reserva })
          : json({ ok: false, error: "reserva_no_encontrada" }, 404);
      } catch (error) {
        console.error("Agent coord heartbeat failure", error);
        return json({ ok: false, error: "service_unavailable" }, 503);
      }
    }
    case "/api/agent-coord/release": {
      try {
        const resultado = await release(kv, raw, identity);
        if (!resultado.ok) return json({ ok: false, error: "forbidden" }, 403);
        const espejo = resultado.reserva
          ? await espejo1713(repository, textoRelease(resultado.reserva, raw))
          : true;
        return json({ ok: true, released: Boolean(resultado.reserva), espejo_1713: espejo });
      } catch (error) {
        console.error("Agent coord release failure", error);
        return json({ ok: false, error: "service_unavailable" }, 503);
      }
    }
    case "/api/agent-coord/claims": {
      try {
        return json({ ok: true, claims: await claims(kv) });
      } catch (error) {
        console.error("Agent coord claims failure", error);
        return json({ ok: false, error: "service_unavailable" }, 503);
      }
    }
  }
  return json({ ok: false, error: "not_found" }, 404);
}
