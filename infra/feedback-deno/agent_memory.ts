const AGENT_MEMORY_AUDIENCE = "siga98-agent-memory";
const AGENT_MEMORY_TTL_MS = 30 * 24 * 60 * 60 * 1000;
const AGENT_MEMORY_SCAN_LIMIT = 50;
const AGENT_MEMORY_RETURN_LIMIT = 8;
const AGENT_MEMORY_MAX_SUMMARY = 1200;
const GITHUB_OIDC_ISSUER = "https://token.actions.githubusercontent.com";
const GITHUB_OIDC_JWKS = "https://token.actions.githubusercontent.com/.well-known/jwks";

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
  run_id?: string;
}

export interface AgentMemoryRecord {
  schema: 1;
  id: string;
  issue: number;
  provider: "qwen" | "gemini";
  summary: string;
  tags: string[];
  paths: string[];
  source: string;
  created_at: string;
  expires_at: string;
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
    decodeBase64Url(parts[2]),
    new TextEncoder().encode(parts[0] + "." + parts[1]),
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
  const allowedWorkflows = [
    repository + "/.github/workflows/agent-autopilot.yml@",
    repository + "/.github/workflows/agent-ci-repair.yml@",
  ];
  if (!allowedWorkflows.some((prefix) => workflowRef.startsWith(prefix))) {
    return null;
  }

  return claims;
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

  return [...new Set(
    value
      .map((tag) => cleanTitle(tag, 40).toLowerCase())
      .filter((tag) => /^[a-z0-9áéíóúüñ_.:/-]+$/i.test(tag)),
  )].slice(0, 8);
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
  const scored: Array<{ score: number; memory: AgentMemoryRecord }> = [];

  const iterator = kv.list<AgentMemoryRecord>(
    { prefix: ["agent_memory", "record"] },
    { reverse: true, limit: AGENT_MEMORY_SCAN_LIMIT },
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

    if (score > 0) scored.push({ score, memory });
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
  claims: OidcClaims,
): Promise<AgentMemoryRecord | null> {
  if (!raw || typeof raw !== "object") return null;

  const input = raw as Record<string, unknown>;
  if (input.schema !== 1) return null;

  const issue = Number(input.issue);
  const provider = cleanText(input.provider, 16);
  const summary = cleanText(input.summary, AGENT_MEMORY_MAX_SUMMARY);
  if (
    !Number.isInteger(issue) ||
    issue <= 0 ||
    !["qwen", "gemini"].includes(provider) ||
    summary.length < 20 ||
    containsPotentialSecret(summary)
  ) {
    return null;
  }

  const tags = cleanMemoryTags(input.tags);
  const paths = cleanMemoryPaths(input.paths);
  const now = Date.now();
  const id = String(now) + "-" + crypto.randomUUID();

  const memory: AgentMemoryRecord = {
    schema: 1,
    id,
    issue,
    provider: provider as "qwen" | "gemini",
    summary,
    tags,
    paths,
    source: "github-actions:" + (cleanTitle(claims.run_id, 80) || "unknown"),
    created_at: new Date(now).toISOString(),
    expires_at: new Date(now + AGENT_MEMORY_TTL_MS).toISOString(),
  };

  await kv.set(
    ["agent_memory", "record", now, id],
    memory,
    { expireIn: AGENT_MEMORY_TTL_MS },
  );
  return memory;
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

  let claims: OidcClaims | null;
  try {
    claims = await authenticateAgentRequest(request, repository);
  } catch (error) {
    console.error("Agent memory OIDC failure", error);
    return json({ ok: false, error: "service_unavailable" }, 503);
  }
  if (!claims) {
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
    const memory = await rememberAgentMemory(kv, raw, claims);
    if (!memory) {
      return json({ ok: false, error: "invalid_memory" }, 400);
    }
    return json({ ok: true, memory }, 201);
  }

  return json({ ok: false, error: "not_found" }, 404);
}
