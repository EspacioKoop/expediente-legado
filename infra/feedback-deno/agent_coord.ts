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
const RESERVA_TTL_MS = 48 * 60 * 60 * 1000;
const RESERVA_LIMITE = 100;
const HORA_MS = 60 * 60 * 1000;

export interface Reserva {
  schema: 1;
  agente: string;
  issue: number;
  rama: string;
  files: string[];
  goal: string;
  visto: string;
}

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

function normalizarRutas(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  const rutas: string[] = [];
  for (const raw of value) {
    const ruta = cleanTitle(raw, 200).replace(/\\/g, "/");
    if (!ruta || ruta.startsWith("/") || ruta.split("/").includes("..")) continue;
    if (!rutas.includes(ruta)) rutas.push(ruta);
  }
  return rutas;
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

async function claim(
  kv: Deno.Kv,
  raw: Record<string, unknown>,
  identity: AgentIdentity,
): Promise<Reserva | null> {
  const agente = agenteDe(identity, raw.agente);
  if (!agente) return null;

  const issue = Number(raw.issue ?? 0);
  if (!Number.isInteger(issue) || issue <= 0) return null;

  const rutas = normalizarRutas(raw.files);
  if (rutas.length === 0) return null;

  const rama = cleanTitle(raw.branch || raw.rama, 120);
  if (!rama) return null;

  const goal = cleanTitle(raw.goal || raw.objetivo, 200);
  if (!goal) return null;

  // Verificación de solape: un archivo está reservado si coincide exactamente
  // o si alguna ruta reservada es prefijo de la ruta solicitada (directorio).
  // "foo" solapa "foo/bar", pero "foo" no solapa "foobar".
  const iterator = kv.list<Reserva>({ prefix: ["agent_coord", "reserva"] });
  for await (const entry of iterator) {
    const r = entry.value;
    if (!r || r.schema !== 1) continue;
    for (const rutaR of r.files) {
      for (const rutaS of rutas) {
        if (rutaS === rutaR || rutaS.startsWith(rutaR + "/")) {
          return null; // Solapado
        }
        if (rutaR.startsWith(rutaS + "/")) {
          return null; // Solapado
        }
      }
    }
  }

  const reserva: Reserva = {
    schema: 1,
    agente,
    issue,
    rama,
    files: rutas,
    goal,
    visto: new Date().toISOString(),
  };

  // Persistencia con CAS (Check-and-Set) implícito en el flujo de validación
  // previo, aunque para concurrencia estricta se requeriría una transacción.
  // Deno KV soporta atomic().
  const key = ["agent_coord", "reserva", issue, ...rutas.sort()];
  const res = await kv.atomic()
    .check({ key: key, versionstamp: null }) // solo si no existe
    .set(key, reserva)
    .commit();

  if (!res.ok) return null;

  return reserva;
}

async function heartbeat(
  kv: Deno.Kv,
  raw: Record<string, unknown>,
  identity: AgentIdentity,
): Promise<Reserva | null> {
  const agente = agenteDe(identity, raw.agente);
  if (!agente) return null;

  const issue = Number(raw.issue ?? 0);
  if (!Number.isInteger(issue) || issue <= 0) return null;

  const rutas = normalizarRutas(raw.files);
  if (rutas.length === 0) return null;

  const key = ["agent_coord", "reserva", issue, ...rutas.sort()];
  const existente = await kv.get<Reserva>(key);

  if (!existente.value || existente.value.agente !== agente) return null;

  const reserva = { ...existente.value, visto: new Date().toISOString() };
  await kv.set(key, reserva, { expireIn: RESERVA_TTL_MS });
  return reserva;
}

async function release(
  kv: Deno.Kv,
  raw: Record<string, unknown>,
  identity: AgentIdentity,
): Promise<boolean> {
  const agente = agenteDe(identity, raw.agente);
  if (!agente) return null;

  const issue = Number(raw.issue ?? 0);
  if (!Number.isInteger(issue) || issue <= 0) return null;

  const rutas = normalizarRutas(raw.files);
  if (rutas.length === 0) return null;

  const key = ["agent_coord", "reserva", issue, ...rutas.sort()];
  const existente = await kv.get<Reserva>(key);

  if (!existente.value || existente.value.agente !== agente) return null;

  await kv.delete(key);
  return true;
}

async function claims(kv: Deno.Kv): Promise<Reserva[]> {
  const lista: Reserva[] = [];
  const iterator = kv.list<Reserva>({ prefix: ["agent_coord", "reserva"] });
  for await (const entry of iterator) {
    if (entry.value?.schema === 1) lista.push(entry.value);
  }
  return lista;
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
      const reserva = await claim(kv, raw, identity);
      return reserva
        ? json({ ok: true, reserva }, 201)
        : json({ ok: false, error: "solapado_o_invalido" }, 400);
    }
    case "/api/agent-coord/heartbeat": {
      const reserva = await heartbeat(kv, raw, identity);
      return reserva
        ? json({ ok: true, reserva })
        : json({ ok: false, error: "reserva_no_encontrada" }, 400);
    }
    case "/api/agent-coord/release": {
      const ok = await release(kv, raw, identity);
      return ok
        ? json({ ok: true })
        : json({ ok: false, error: "reserva_no_encontrada" }, 400);
    }
    case "/api/agent-coord/claims":
      return json({ ok: true, claims: await claims(kv) });
  }
  return json({ ok: false, error: "not_found" }, 404);
}
