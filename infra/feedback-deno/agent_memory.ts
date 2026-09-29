const AGENT_MEMORY_AUDIENCE = "siga98-agent-memory";
const AGENT_MEMORY_TTL_MS = 30 * 24 * 60 * 60 * 1000;
const AGENT_MEMORY_SCAN_LIMIT = 50;
const AGENT_MEMORY_RETURN_LIMIT = 8;
const AGENT_MEMORY_MAX_SUMMARY = 1200;
// Las lecciones no caducan, así que se escanean más que los episodios del pool.
const AGENT_MEMORY_LESSON_SCAN_LIMIT = 100;
const AGENT_MEMORY_MAX_QUERY_WORDS = 8;
// Variable de entorno de Deno Deploy, no secret de GitHub. Sin ella (o si es
// corta) el nivel 2 queda deshabilitado: fail-closed.
const AGENT_MEMORY_NIVEL2_TOKEN_ENV = "AGENT_MEMORY_NIVEL2_TOKEN";
const AGENT_MEMORY_NIVEL2_MIN_TOKEN = 32;
const GITHUB_OIDC_ISSUER = "https://token.actions.githubusercontent.com";
const GITHUB_OIDC_JWKS = "https://token.actions.githubusercontent.com/.well-known/jwks";

const POOL_PROVIDERS = ["qwen", "gemini"] as const;
const NIVEL2_AGENTS = ["claude", "codex", "hermes", "odiseo"] as const;
type AgentMemoryProvider = typeof POOL_PROVIDERS[number] | typeof NIVEL2_AGENTS[number];

// `episodio`: lo que pasó en un issue concreto, caduca a los 30 días.
// `leccion`: conocimiento estable que escribe el nivel 2 y lee todo el mundo.
type AgentMemoryKind = "episodio" | "leccion";

type AgentIdentity =
  | { level: "pool"; claims: OidcClaims }
  | { level: "nivel2" };

interface OidcJwk extends JsonWebKey {
  kid?: string;
}

interface OidcClaims {
  iss?: string;
  aud?: string | string[];
  exp?: number;
  nbf?: number;
  repository?: string;
  workflow_ref?: string;
  job_workflow_ref?: string;
  run_id?: string;
}

export interface AgentMemoryRecord {
  schema: 1;
  id: string;
  // Ausente en los registros anteriores a #1756: se leen como episodio.
  kind?: AgentMemoryKind;
  // 0 en lecciones que no nacen de un issue concreto.
  issue: number;
  provider: AgentMemoryProvider;
  summary: string;
  tags: string[];
  paths: string[];
  source: string;
  created_at: string;
  expires_at: string | null;
}

let oidcJwksCache: { expiresAt: number; keys: OidcJwk[] } | null = null;

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
      "referrer-policy": "no-referrer",
    },
  });
}

function cleanText(value: unknown, max: number): string {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, max);
}

function cleanTitle(value: unknown, max: number): string {
  return cleanText(value, max)
    .replace(/[\r\n\t]+/g, " ")
    .replace(/\s{2,}/g, " ");
}

function decodeBase64Url(value: string): Uint8Array {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized + "=".repeat((4 - normalized.length % 4) % 4);
  const binary = atob(padded);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function decodeJwtJson<T>(value: string): T {
  return JSON.parse(new TextDecoder().decode(decodeBase64Url(value))) as T;
}

function toArrayBuffer(bytes: Uint8Array): ArrayBuffer {
  const copy = new Uint8Array(bytes.byteLength);
  copy.set(bytes);
  return copy.buffer;
}

async function oidcKeys(): Promise<OidcJwk[]> {
  const now = Date.now();
  if (oidcJwksCache && oidcJwksCache.expiresAt > now) {
    return oidcJwksCache.keys;
  }

  const response = await fetch(GITHUB_OIDC_JWKS, {
    headers: { accept: "application/json" },
  });
  if (!response.ok) {
    throw new Error("No se pudo cargar JWKS de GitHub");
  }

  const raw = await response.json() as { keys?: OidcJwk[] };
  if (!Array.isArray(raw.keys) || raw.keys.length === 0) {
    throw new Error("JWKS de GitHub inválido");
  }

  oidcJwksCache = {
    keys: raw.keys,
    expiresAt: now + 10 * 60 * 1000,
  };
  return raw.keys;
}

async function authenticateAgentRequest(
  request: Request,
  repository: string,
): Promise<OidcClaims | null> {
  const authorization = request.headers.get("authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) return null;

  const token = authorization.slice("Bearer ".length).trim();
  const parts = token.split(".");
  if (parts.length !== 3) return null;

  let header: { alg?: string; kid?: string; typ?: string };
  let claims: OidcClaims;
  try {
    header = decodeJwtJson(parts[0]);
    claims = decodeJwtJson(parts[1]);
  } catch {
    return null;
  }

  if (header.alg !== "RS256" || !header.kid) return null;

  const jwk = (await oidcKeys()).find((candidate) => candidate.kid === header.kid);
  if (!jwk) return null;

  const key = await crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const verified = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    key,
    toArrayBuffer(decodeBase64Url(parts[2])),
    toArrayBuffer(new TextEncoder().encode(parts[0] + "." + parts[1])),
  );
  if (!verified) return null;

  const now = Math.floor(Date.now() / 1000);
  const audiences = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
  if (
    claims.iss !== GITHUB_OIDC_ISSUER ||
    !audiences.includes(AGENT_MEMORY_AUDIENCE) ||
    typeof claims.exp !== "number" ||
    claims.exp < now - 30 ||
    (typeof claims.nbf === "number" && claims.nbf > now + 30)
  ) {
    return null;
  }

  if (claims.repository !== repository) return null;

  const workflowRef = claims.workflow_ref ?? "";
  const jobWorkflowRef = claims.job_workflow_ref ?? "";
  const allowedWorkflows = [
    repository + "/.github/workflows/agent-autopilot.yml@",
    repository + "/.github/workflows/agent-ci-repair.yml@",
  ];
  const workerPrefix = repository + "/.github/workflows/agent-worker.yml@";
  const poolPrefix = repository + "/.github/workflows/agent-pool.yml@";
  const directAllowed = allowedWorkflows.some((prefix) => workflowRef.startsWith(prefix)) ||
    workflowRef.startsWith(workerPrefix);
  const reusableAllowed = workflowRef.startsWith(poolPrefix) &&
    jobWorkflowRef.startsWith(workerPrefix);
  if (!directAllowed && !reusableAllowed) {
    return null;
  }

  return claims;
}

async function sha256(value: string): Promise<Uint8Array> {
  return new Uint8Array(
    await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value)),
  );
}

// Compara resúmenes de igual longitud para no filtrar el token por tiempo.
async function nivel2TokenMatches(token: string): Promise<boolean> {
  const expected = Deno.env.get(AGENT_MEMORY_NIVEL2_TOKEN_ENV) ?? "";
  if (expected.length < AGENT_MEMORY_NIVEL2_MIN_TOKEN || !token) return false;

  const [given, wanted] = await Promise.all([sha256(token), sha256(expected)]);
  let diff = 0;
  for (let index = 0; index < wanted.length; index++) {
    diff |= given[index] ^ wanted[index];
  }
  return diff === 0;
}

async function authenticateAgent(
  request: Request,
  repository: string,
): Promise<AgentIdentity | null> {
  const authorization = request.headers.get("authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) return null;
  const token = authorization.slice("Bearer ".length).trim();

  // Un JWT solo puede ser OIDC del pool: nunca se prueba como token de nivel 2.
  if (token.split(".").length === 3) {
    const claims = await authenticateAgentRequest(request, repository);
    return claims ? { level: "pool", claims } : null;
  }
  return await nivel2TokenMatches(token) ? { level: "nivel2" } : null;
}

async function readJsonBody(request: Request, maxBytes = 8192): Promise<unknown> {
  const declaredLength = Number(request.headers.get("content-length") || "0");
  if (Number.isFinite(declaredLength) && declaredLength > maxBytes) {
    throw new Error("payload_too_large");
  }

  const bytes = new Uint8Array(await request.arrayBuffer());
  if (bytes.byteLength > maxBytes) throw new Error("payload_too_large");
  return JSON.parse(new TextDecoder().decode(bytes));
}

function cleanMemoryTags(value: unknown): string[] {
  if (!Array.isArray(value)) return [];

  return [
    ...new Set(
      value
        .map((tag) => cleanTitle(tag, 40).toLowerCase())
        .filter((tag) => /^[a-z0-9áéíóúüñ_.:/-]+$/i.test(tag)),
    ),
  ].slice(0, 8);
}

function cleanMemoryPaths(value: unknown): string[] {
  if (!Array.isArray(value)) return [];

  const clean: string[] = [];
  for (const raw of value) {
    const path = cleanText(raw, 240).replace(/\\/g, "/");
    if (
      !path ||
      path.startsWith("/") ||
      path.startsWith(".agent-") ||
      path.split("/").includes("..") ||
      /[*?[\]]/.test(path)
    ) {
      continue;
    }

    if (!clean.includes(path)) clean.push(path);
    if (clean.length >= 12) break;
  }
  return clean;
}

// Palabras de 4 letras o más: lo bastante largas para no casar con todo.
function cleanQueryWords(value: unknown): string[] {
  return [
    ...new Set(
      cleanTitle(value, 200)
        .toLowerCase()
        .split(/[^a-z0-9áéíóúüñ_]+/i)
        .filter((word) => word.length >= 4),
    ),
  ].slice(0, AGENT_MEMORY_MAX_QUERY_WORDS);
}

function pathsOverlap(left: string, right: string): boolean {
  const a = left.replace(/\/+$/, "");
  const b = right.replace(/\/+$/, "");
  return a === b || a.startsWith(b + "/") || b.startsWith(a + "/");
}

function containsPotentialSecret(value: string): boolean {
  return /(github_pat_|gh[pousr]_|AIza[0-9A-Za-z_-]{20,}|sk-[A-Za-z0-9_-]{12,}|Bearer\s+[A-Za-z0-9._-]{12,})/i
    .test(value);
}

async function searchAgentMemory(
  kv: Deno.Kv,
  raw: unknown,
): Promise<AgentMemoryRecord[]> {
  if (!raw || typeof raw !== "object") return [];

  const input = raw as Record<string, unknown>;
  if (input.schema !== 1) return [];

  const issue = Number(input.issue);
  const paths = cleanMemoryPaths(input.paths);
  const tags = cleanMemoryTags(input.tags);
  const words = cleanQueryWords(input.query);
  const scored: Array<{ score: number; memory: AgentMemoryRecord }> = [];

  const sources: Array<[string, number]> = [
    ["record", AGENT_MEMORY_SCAN_LIMIT],
    ["leccion", AGENT_MEMORY_LESSON_SCAN_LIMIT],
  ];
  for (const [prefix, limit] of sources) {
    const iterator = kv.list<AgentMemoryRecord>(
      { prefix: ["agent_memory", prefix] },
      { reverse: true, limit },
    );
    for await (const entry of iterator) {
      const memory = entry.value;
      if (!memory || memory.schema !== 1) continue;

      let score = 0;
      if (Number.isInteger(issue) && issue > 0 && memory.issue === issue) {
        score += 100;
      }
      for (const path of paths) {
        if (memory.paths.some((candidate) => pathsOverlap(path, candidate))) {
          score += 30;
        }
      }
      for (const tag of tags) {
        if (memory.tags.includes(tag)) score += 10;
      }
      const summary = memory.summary.toLowerCase();
      for (const word of words) {
        if (summary.includes(word)) score += 5;
      }

      if (score > 0) scored.push({ score, memory });
    }
  }

  scored.sort((left, right) =>
    right.score - left.score ||
    right.memory.created_at.localeCompare(left.memory.created_at)
  );

  return scored
    .slice(0, AGENT_MEMORY_RETURN_LIMIT)
    .map((item) => item.memory);
}

async function rememberAgentMemory(
  kv: Deno.Kv,
  raw: unknown,
  identity: AgentIdentity,
): Promise<AgentMemoryRecord | null> {
  if (!raw || typeof raw !== "object") return null;

  const input = raw as Record<string, unknown>;
  if (input.schema !== 1) return null;

  const kind: AgentMemoryKind = input.kind === "leccion" ? "leccion" : "episodio";
  const issue = Number(input.issue ?? 0);
  const provider = cleanText(input.provider, 16);
  const summary = cleanText(input.summary, AGENT_MEMORY_MAX_SUMMARY);
  const allowedProviders: readonly string[] = identity.level === "pool"
    ? POOL_PROVIDERS
    : NIVEL2_AGENTS;
  // Solo el nivel 2 fija lecciones: el pool deja episodios que caducan.
  const lessonAllowed = kind === "episodio" || identity.level === "nivel2";
  const issueValid = Number.isInteger(issue) &&
    (kind === "leccion" ? issue >= 0 : issue > 0);
  if (
    !lessonAllowed ||
    !issueValid ||
    !allowedProviders.includes(provider) ||
    summary.length < 20 ||
    containsPotentialSecret(summary)
  ) {
    return null;
  }

  const tags = cleanMemoryTags(input.tags);
  const paths = cleanMemoryPaths(input.paths);
  const now = Date.now();
  const id = String(now) + "-" + crypto.randomUUID();
  const source = identity.level === "pool"
    ? "github-actions:" + (cleanTitle(identity.claims.run_id, 80) || "unknown")
    : "nivel2:" + provider;

  const memory: AgentMemoryRecord = {
    schema: 1,
    id,
    kind,
    issue,
    provider: provider as AgentMemoryProvider,
    summary,
    tags,
    paths,
    source,
    created_at: new Date(now).toISOString(),
    expires_at: kind === "leccion" ? null : new Date(now + AGENT_MEMORY_TTL_MS).toISOString(),
  };

  if (kind === "leccion") {
    await kv.set(["agent_memory", "leccion", now, id], memory);
  } else {
    await kv.set(
      ["agent_memory", "record", now, id],
      memory,
      { expireIn: AGENT_MEMORY_TTL_MS },
    );
  }
  return memory;
}

// Las lecciones no caducan: sin `forget` un error quedaría para siempre.
async function forgetAgentLesson(kv: Deno.Kv, raw: unknown): Promise<boolean> {
  if (!raw || typeof raw !== "object") return false;

  const input = raw as Record<string, unknown>;
  const id = cleanText(input.id, 80);
  const match = /^(\d{13})-[0-9a-f-]{36}$/.exec(id);
  if (input.schema !== 1 || !match) return false;

  const key = ["agent_memory", "leccion", Number(match[1]), id];
  const existing = await kv.get<AgentMemoryRecord>(key);
  if (!existing.value) return false;

  await kv.delete(key);
  return true;
}

export async function handleAgentMemory(
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
    console.error("Agent memory OIDC failure", error);
    return json({ ok: false, error: "service_unavailable" }, 503);
  }
  if (!identity) {
    return json({ ok: false, error: "unauthorized" }, 401);
  }

  let raw: unknown;
  try {
    raw = await readJsonBody(request);
  } catch (error) {
    const tooLarge = error instanceof Error && error.message === "payload_too_large";
    return json(
      { ok: false, error: tooLarge ? "payload_too_large" : "invalid_json" },
      tooLarge ? 413 : 400,
    );
  }

  if (url.pathname === "/api/agent-memory/search") {
    return json({
      ok: true,
      memories: await searchAgentMemory(kv, raw),
    });
  }

  if (url.pathname === "/api/agent-memory/remember") {
    const memory = await rememberAgentMemory(kv, raw, identity);
    if (!memory) {
      return json({ ok: false, error: "invalid_memory" }, 400);
    }
    return json({ ok: true, memory }, 201);
  }

  if (url.pathname === "/api/agent-memory/forget") {
    if (identity.level !== "nivel2") {
      return json({ ok: false, error: "forbidden" }, 403);
    }
    if (!await forgetAgentLesson(kv, raw)) {
      return json({ ok: false, error: "not_found" }, 404);
    }
    return json({ ok: true });
  }

  return json({ ok: false, error: "not_found" }, 404);
}
