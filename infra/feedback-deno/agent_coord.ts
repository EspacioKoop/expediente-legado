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

  for (let intento = 0; intento < RESERVA_CAS_INTENTOS; intento += 1) {
    const entry = await kv.get<RegistroReservas>(RESERVAS_KEY);
    const vivas = reservasVivas(registroReservas(entry.value).reservas);
    const conflicts = vivas.filter((reserva) =>
      reserva.files.some((existente) => rutas.some((solicitada) => rutasSolapan(existente, solicitada)))
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
        const resultado = await claim(kv, raw, identity);
        if (!resultado.ok) {
          const status = resultado.error === "conflict" ? 409 : 400;
          return json({ ok: false, error: resultado.error, conflicts: resultado.conflicts ?? [] }, status);
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
