import { handleAgentB2B } from "./agent_b2b.ts";

const AGENT_POOL_AUDIENCE = "siga98-agent-pool";
const AGENT_POOL_LEASE_TTL_MS = 30 * 60 * 1000;
const AGENT_POOL_EVENT_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const AGENT_POOL_STATUS_LIMIT = 100;
const AGENT_POOL_HEALTH_LIMIT = 64;
const AGENT_POOL_MIN_COOLDOWN_MS = 5 * 60 * 1000;
const AGENT_POOL_MAX_COOLDOWN_MS = 6 * 60 * 60 * 1000;
const GITHUB_OIDC_ISSUER = "https://token.actions.githubusercontent.com";
const GITHUB_OIDC_JWKS = "https://token.actions.githubusercontent.com/.well-known/jwks";

const POOL_STATES = new Set([
  "leased",
  "planning",
  "reserved",
  "implementing",
  "validating",
  "publishing",
  "pr_open",
  "retry",
  "failed",
  "needs_human",
]);

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

interface AuthenticatedActor {
  claims: OidcClaims;
  role: "dispatcher" | "worker" | "smoke";
}

export function agentPoolRoleFromWorkflowRefs(
  repository: string,
  workflowRef: string,
  jobWorkflowRef: string,
): "dispatcher" | "worker" | "smoke" | null {
  const poolPrefix = repository + "/.github/workflows/agent-pool.yml@";
  const workerPrefix = repository + "/.github/workflows/agent-worker.yml@";
  const smokePrefix = repository + "/.github/workflows/agent-provider-smoke.yml@";

  if (workflowRef.startsWith(workerPrefix)) {
    return "worker";
  }
  if (
    workflowRef.startsWith(poolPrefix) &&
    jobWorkflowRef.startsWith(workerPrefix)
  ) {
    return "worker";
  }
  if (
    workflowRef.startsWith(poolPrefix) &&
    (!jobWorkflowRef || jobWorkflowRef.startsWith(poolPrefix))
  ) {
    return "dispatcher";
  }
  if (workflowRef.startsWith(smokePrefix)) {
    return "smoke";
  }
  return null;
}

export interface AgentPoolLease {
  schema: 1;
  issue: number;
  lease_id: string;
  run_id: string;
  worker: string;
  provider: "qwen" | "gemini";
  branch: string;
  files: string[];
  state: string;
  generation: number;
  acquired_at: string;
  updated_at: string;
  expires_at: string;
}

interface AgentPoolFileLock {
  schema: 1;
  path: string;
  issue: number;
  lease_id: string;
  run_id: string;
  worker: string;
  expires_at: string;
}

export interface AgentPoolWorkerHealth {
  schema: 1;
  worker: string;
  provider: "qwen" | "gemini";
  status: "unhealthy";
  reason: string;
  run_id: string;
  failures: number;
  updated_at: string;
  expires_at: string;
}

interface AgentPoolEvent {
  schema: 1;
  issue: number;
  lease_id: string;
  run_id: string;
  worker: string;
  provider: "qwen" | "gemini";
  state: string;
  reason: string;
  generation: number;
  at: string;
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

async function authenticateAgentPoolRequest(
  request: Request,
  repository: string,
): Promise<AuthenticatedActor | null> {
  const authorization = request.headers.get("authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) return null;

  const token = authorization.slice("Bearer ".length).trim();
  const parts = token.split(".");
  if (parts.length !== 3) return null;

  let header: { alg?: string; kid?: string };
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
    !audiences.includes(AGENT_POOL_AUDIENCE) ||
    typeof claims.exp !== "number" ||
    claims.exp < now - 30 ||
    (typeof claims.nbf === "number" && claims.nbf > now + 30) ||
    claims.repository !== repository ||
    !cleanText(claims.run_id, 80)
  ) {
    return null;
  }

  const workflowRef = claims.workflow_ref ?? "";
  const jobWorkflowRef = claims.job_workflow_ref ?? "";
  const role = agentPoolRoleFromWorkflowRefs(
    repository,
    workflowRef,
    jobWorkflowRef,
  );
  return role ? { claims, role } : null;
}

async function readJsonBody(request: Request, maxBytes = 16384): Promise<unknown> {
  const declaredLength = Number(request.headers.get("content-length") || "0");
  if (Number.isFinite(declaredLength) && declaredLength > maxBytes) {
    throw new Error("payload_too_large");
  }

  const bytes = new Uint8Array(await request.arrayBuffer());
  if (bytes.byteLength > maxBytes) throw new Error("payload_too_large");
  return JSON.parse(new TextDecoder().decode(bytes));
}

function cleanIssue(value: unknown): number | null {
  const issue = Number(value);
  return Number.isInteger(issue) && issue > 0 ? issue : null;
}

function cleanWorker(value: unknown): string {
  const worker = cleanText(value, 80);
  return /^[A-Za-z0-9._-]+$/.test(worker) ? worker : "";
}

function cleanProvider(value: unknown): "qwen" | "gemini" | null {
  const provider = cleanText(value, 16);
  return provider === "qwen" || provider === "gemini" ? provider : null;
}

function cleanBranch(value: unknown): string {
  const branch = cleanText(value, 180);
  return /^[A-Za-z0-9._/-]+$/.test(branch) && !branch.includes("..") ? branch : "";
}

function cleanFiles(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  const files: string[] = [];
  for (const item of value.slice(0, 12)) {
    const path = cleanText(item, 240).replace(/\\/g, "/");
    if (
      !path ||
      path.startsWith("/") ||
      path.split("/").includes("..") ||
      !/^[A-Za-z0-9._/@+ -]+$/.test(path)
    ) {
      continue;
    }
    if (!files.includes(path)) files.push(path);
  }
  return files;
}

function leaseKey(issue: number): Deno.KvKey {
  return ["agent_pool", "lease", issue];
}

function workerLeaseKey(worker: string): Deno.KvKey {
  return ["agent_pool", "worker_lease", worker];
}

function leaseVivo(lease: AgentPoolLease | null, now: number): lease is AgentPoolLease {
  return Boolean(lease && Date.parse(lease.expires_at) > now);
}

function mismoLease(a: AgentPoolLease, b: AgentPoolLease): boolean {
  return a.issue === b.issue && a.lease_id === b.lease_id && a.run_id === b.run_id;
}

async function leasesHistoricos(kv: Deno.Kv, workers: Set<string>): Promise<AgentPoolLease[]> {
  // Durante la migración los leases anteriores no tienen índice por slot.
  // Siguen ocupándolo hasta release/TTL; no se permite adelantarlos.
  const leases: AgentPoolLease[] = [];
  const now = Date.now();
  for await (const entry of kv.list<AgentPoolLease>({ prefix: ["agent_pool", "lease"] })) {
    if (workers.has(entry.value.worker) && leaseVivo(entry.value, now)) {
      leases.push(entry.value);
    }
  }
  return leases;
}

function fileLockKey(path: string): Deno.KvKey {
  return ["agent_pool", "file_lock", path];
}

function ownsFileLock(lock: AgentPoolFileLock, lease: AgentPoolLease): boolean {
  return lock.issue === lease.issue &&
    lock.lease_id === lease.lease_id &&
    lock.run_id === lease.run_id;
}

function fileLock(lease: AgentPoolLease, path: string, now: number): AgentPoolFileLock {
  return {
    schema: 1,
    path,
    issue: lease.issue,
    lease_id: lease.lease_id,
    run_id: lease.run_id,
    worker: lease.worker,
    expires_at: new Date(now + AGENT_POOL_LEASE_TTL_MS).toISOString(),
  };
}

function liveForeignLock(
  entry: Deno.KvEntryMaybe<AgentPoolFileLock>,
  lease: AgentPoolLease,
  now: number,
): AgentPoolFileLock | null {
  const lock = entry.value;
  if (!lock || ownsFileLock(lock, lease)) return null;
  return Date.parse(lock.expires_at) > now ? lock : null;
}

function eventKey(now: number): Deno.KvKey {
  return ["agent_pool", "event", now, crypto.randomUUID()];
}

function publicLease(lease: AgentPoolLease): AgentPoolLease {
  return { ...lease, files: lease.files ?? [] };
}

function newEvent(
  lease: AgentPoolLease,
  state: string,
  reason: string,
  now: number,
): AgentPoolEvent {
  return {
    schema: 1,
    issue: lease.issue,
    lease_id: lease.lease_id,
    run_id: lease.run_id,
    worker: lease.worker,
    provider: lease.provider,
    state,
    reason: cleanText(reason, 160),
    generation: lease.generation,
    at: new Date(now).toISOString(),
  };
}

async function acquireLease(
  kv: Deno.Kv,
  raw: unknown,
  actor: AuthenticatedActor,
): Promise<Response> {
  if (actor.role !== "worker") {
    return json({ ok: false, error: "forbidden" }, 403);
  }
  if (!raw || typeof raw !== "object") {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const input = raw as Record<string, unknown>;
  if (input.schema !== 1) {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const issue = cleanIssue(input.issue);
  const worker = cleanWorker(input.worker);
  const provider = cleanProvider(input.provider);
  const branch = cleanBranch(input.branch);
  const files = cleanFiles(input.files);
  const runId = cleanText(actor.claims.run_id, 80);
  if (!issue || !worker || !provider || !branch || !runId) {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const key = leaseKey(issue);
  const slotKey = workerLeaseKey(worker);
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const current = await kv.get<AgentPoolLease>(key);
    const slot = await kv.get<AgentPoolLease>(slotKey);
    const now = Date.now();
    if (leaseVivo(current.value, now)) {
      if (
        leaseVivo(slot.value, now) && mismoLease(slot.value, current.value) &&
        current.value.run_id === runId && current.value.worker === worker &&
        current.value.provider === provider && current.value.branch === branch &&
        JSON.stringify(current.value.files ?? []) === JSON.stringify(files)
      ) {
        return json({ ok: true, lease: publicLease(current.value), deduplicated: true }, 201);
      }
      return json(
        { ok: false, error: "leased", lease: publicLease(current.value) },
        409,
      );
    }

    const ocupado = leaseVivo(slot.value, now)
      ? slot.value
      : (await leasesHistoricos(kv, new Set([worker])))[0];
    if (ocupado) {
      return json({ ok: false, error: "worker_conflict", lease: publicLease(ocupado) }, 409);
    }
    const lease: AgentPoolLease = {
      schema: 1,
      issue,
      lease_id: crypto.randomUUID(),
      run_id: runId,
      worker,
      provider,
      branch,
      files,
      state: "leased",
      generation: 1,
      acquired_at: new Date(now).toISOString(),
      updated_at: new Date(now).toISOString(),
      expires_at: new Date(now + AGENT_POOL_LEASE_TTL_MS).toISOString(),
    };
    const event = newEvent(lease, "leased", "acquire", now);
    const lockEntries = await Promise.all(
      files.map((path) => kv.get<AgentPoolFileLock>(fileLockKey(path))),
    );
    for (let index = 0; index < files.length; index += 1) {
      const conflict = liveForeignLock(lockEntries[index], lease, now);
      if (conflict) {
        return json(
          {
            ok: false,
            error: "file_conflict",
            path: files[index],
            issue: conflict.issue,
            worker: conflict.worker,
          },
          409,
        );
      }
    }

    const atomic = kv.atomic().check(current).check(slot);
    for (let index = 0; index < files.length; index += 1) {
      atomic
        .check(lockEntries[index])
        .set(fileLockKey(files[index]), fileLock(lease, files[index], now), {
          expireIn: AGENT_POOL_LEASE_TTL_MS,
        });
    }
    const committed = await atomic
      .set(key, lease, { expireIn: AGENT_POOL_LEASE_TTL_MS })
      .set(slotKey, lease, { expireIn: AGENT_POOL_LEASE_TTL_MS })
      .set(eventKey(now), event, { expireIn: AGENT_POOL_EVENT_TTL_MS })
      .commit();

    if (committed.ok) {
      return json({ ok: true, lease: publicLease(lease) }, 201);
    }
  }

  return json({ ok: false, error: "lease_race" }, 409);
}

async function transitionLease(
  kv: Deno.Kv,
  raw: unknown,
  actor: AuthenticatedActor,
): Promise<Response> {
  if (actor.role !== "worker") {
    return json({ ok: false, error: "forbidden" }, 403);
  }
  if (!raw || typeof raw !== "object") {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const input = raw as Record<string, unknown>;
  const issue = cleanIssue(input.issue);
  const leaseId = cleanText(input.lease_id, 80);
  const state = cleanText(input.state, 32);
  const reason = cleanText(input.reason, 160);
  const runId = cleanText(actor.claims.run_id, 80);
  if (
    input.schema !== 1 ||
    !issue ||
    !leaseId ||
    !POOL_STATES.has(state) ||
    !runId
  ) {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const key = leaseKey(issue);
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const current = await kv.get<AgentPoolLease>(key);
    const lease = current.value;
    if (!lease) {
      return json({ ok: false, error: "lease_missing" }, 409);
    }
    if (lease.lease_id !== leaseId || lease.run_id !== runId) {
      return json({ ok: false, error: "lease_not_owned" }, 409);
    }

    const now = Date.now();
    const slotKey = workerLeaseKey(lease.worker);
    const slot = await kv.get<AgentPoolLease>(slotKey);
    const ocupado = leaseVivo(slot.value, now)
      ? slot.value
      : (await leasesHistoricos(kv, new Set([lease.worker])))
        .find((historico) => !mismoLease(historico, lease));
    if (ocupado && !mismoLease(ocupado, lease)) {
      return json({ ok: false, error: "worker_conflict", lease: publicLease(ocupado) }, 409);
    }
    const previousFiles = lease.files ?? [];
    const nextFiles = Object.hasOwn(input, "files") ? cleanFiles(input.files) : previousFiles;
    const next: AgentPoolLease = {
      ...lease,
      files: nextFiles,
      state,
      generation: lease.generation + 1,
      updated_at: new Date(now).toISOString(),
      expires_at: new Date(now + AGENT_POOL_LEASE_TTL_MS).toISOString(),
    };
    const lockPaths = [...new Set([...previousFiles, ...nextFiles])];
    const lockEntries = await Promise.all(
      lockPaths.map((path) => kv.get<AgentPoolFileLock>(fileLockKey(path))),
    );
    for (const path of nextFiles) {
      const index = lockPaths.indexOf(path);
      const conflict = liveForeignLock(lockEntries[index], next, now);
      if (conflict) {
        return json(
          {
            ok: false,
            error: "file_conflict",
            path,
            issue: conflict.issue,
            worker: conflict.worker,
          },
          409,
        );
      }
    }

    const event = newEvent(next, state, reason || "transition", now);
    const atomic = kv.atomic().check(current).check(slot);
    for (let index = 0; index < lockPaths.length; index += 1) {
      const path = lockPaths[index];
      const entry = lockEntries[index];
      atomic.check(entry);
      if (!nextFiles.includes(path)) {
        if (entry.value && ownsFileLock(entry.value, lease)) {
          atomic.delete(fileLockKey(path));
        }
        continue;
      }
      atomic.set(fileLockKey(path), fileLock(next, path, now), {
        expireIn: AGENT_POOL_LEASE_TTL_MS,
      });
    }
    const committed = await atomic
      .set(key, next, { expireIn: AGENT_POOL_LEASE_TTL_MS })
      .set(slotKey, next, { expireIn: AGENT_POOL_LEASE_TTL_MS })
      .set(eventKey(now), event, { expireIn: AGENT_POOL_EVENT_TTL_MS })
      .commit();
    if (committed.ok) {
      return json({ ok: true, lease: publicLease(next) });
    }
  }

  return json({ ok: false, error: "lease_race" }, 409);
}

async function releaseLease(
  kv: Deno.Kv,
  raw: unknown,
  actor: AuthenticatedActor,
): Promise<Response> {
  if (actor.role !== "worker") {
    return json({ ok: false, error: "forbidden" }, 403);
  }
  if (!raw || typeof raw !== "object") {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const input = raw as Record<string, unknown>;
  const issue = cleanIssue(input.issue);
  const leaseId = cleanText(input.lease_id, 80);
  const reason = cleanText(input.reason, 160) || "release";
  const runId = cleanText(actor.claims.run_id, 80);
  if (input.schema !== 1 || !issue || !leaseId || !runId) {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const key = leaseKey(issue);
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const current = await kv.get<AgentPoolLease>(key);
    const lease = current.value;
    if (!lease) {
      return json({ ok: true, released: false, reason: "already_missing" });
    }
    if (lease.lease_id !== leaseId || lease.run_id !== runId) {
      return json({ ok: false, error: "lease_not_owned" }, 409);
    }

    const now = Date.now();
    const slotKey = workerLeaseKey(lease.worker);
    const slot = await kv.get<AgentPoolLease>(slotKey);
    const files = lease.files ?? [];
    const lockEntries = await Promise.all(
      files.map((path) => kv.get<AgentPoolFileLock>(fileLockKey(path))),
    );
    const event = newEvent(
      { ...lease, generation: lease.generation + 1 },
      "released",
      reason,
      now,
    );
    const atomic = kv.atomic().check(current).check(slot);
    if (slot.value && mismoLease(slot.value, lease)) {
      atomic.delete(slotKey);
    }
    for (let index = 0; index < files.length; index += 1) {
      const entry = lockEntries[index];
      atomic.check(entry);
      if (entry.value && ownsFileLock(entry.value, lease)) {
        atomic.delete(fileLockKey(files[index]));
      }
    }
    const committed = await atomic
      .delete(key)
      .set(eventKey(now), event, { expireIn: AGENT_POOL_EVENT_TTL_MS })
      .commit();
    if (committed.ok) {
      return json({ ok: true, released: true });
    }
  }

  return json({ ok: false, error: "lease_race" }, 409);
}

async function leaseStatus(
  kv: Deno.Kv,
  raw: unknown,
): Promise<Response> {
  if (!raw || typeof raw !== "object") {
    return json({ ok: false, error: "invalid_request" }, 400);
  }
  const input = raw as Record<string, unknown>;
  if (input.schema !== 1 || !Array.isArray(input.issues)) {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const issues = [
    ...new Set(
      input.issues
        .map(cleanIssue)
        .filter((issue): issue is number => issue !== null),
    ),
  ].slice(0, AGENT_POOL_STATUS_LIMIT);

  const entries = await Promise.all(
    issues.map((issue) => kv.get<AgentPoolLease>(leaseKey(issue))),
  );
  return json({
    ok: true,
    leases: entries
      .map((entry) => entry.value)
      .filter((lease): lease is AgentPoolLease => Boolean(lease))
      .map(publicLease),
  });
}

async function workerLeaseStatus(kv: Deno.Kv, raw: unknown): Promise<Response> {
  if (!raw || typeof raw !== "object") {
    return json({ ok: false, error: "invalid_request" }, 400);
  }
  const input = raw as Record<string, unknown>;
  if (input.schema !== 1 || !Array.isArray(input.workers)) {
    return json({ ok: false, error: "invalid_request" }, 400);
  }
  const workers = new Set(
    input.workers.map(cleanWorker).filter(Boolean).slice(0, AGENT_POOL_HEALTH_LIMIT),
  );
  const entries = await Promise.all(
    [...workers].map((worker) => kv.get<AgentPoolLease>(workerLeaseKey(worker))),
  );
  const leases = new Map<string, AgentPoolLease>();
  for (
    const lease of [...entries.map((entry) => entry.value), ...await leasesHistoricos(kv, workers)]
  ) {
    if (leaseVivo(lease, Date.now())) leases.set(lease.lease_id, publicLease(lease));
  }
  return json({ ok: true, leases: [...leases.values()] });
}

function healthKey(worker: string): Deno.KvKey {
  return ["agent_pool", "worker_health", worker];
}

async function workerHealthStatus(
  kv: Deno.Kv,
  raw: unknown,
): Promise<Response> {
  if (!raw || typeof raw !== "object") {
    return json({ ok: false, error: "invalid_request" }, 400);
  }
  const input = raw as Record<string, unknown>;
  if (input.schema !== 1 || !Array.isArray(input.workers)) {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const workers = [
    ...new Set(
      input.workers
        .map((worker) => cleanWorker(worker))
        .filter(Boolean),
    ),
  ].slice(0, AGENT_POOL_HEALTH_LIMIT);

  const entries = await Promise.all(
    workers.map((worker) => kv.get<AgentPoolWorkerHealth>(healthKey(worker))),
  );
  return json({
    ok: true,
    unhealthy: entries
      .map((entry) => entry.value)
      .filter((health): health is AgentPoolWorkerHealth => Boolean(health)),
  });
}

async function reportWorkerHealth(
  kv: Deno.Kv,
  raw: unknown,
  actor: AuthenticatedActor,
): Promise<Response> {
  if (actor.role !== "worker" && actor.role !== "smoke") {
    return json({ ok: false, error: "forbidden" }, 403);
  }
  if (!raw || typeof raw !== "object") {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const input = raw as Record<string, unknown>;
  const worker = cleanWorker(input.worker);
  const provider = cleanProvider(input.provider);
  const status = cleanText(input.status, 16);
  const reason = cleanText(input.reason, 64) || "unknown";
  const runId = cleanText(actor.claims.run_id, 80);
  if (
    input.schema !== 1 ||
    !worker ||
    !provider ||
    !runId ||
    !["healthy", "unhealthy"].includes(status)
  ) {
    return json({ ok: false, error: "invalid_request" }, 400);
  }

  const key = healthKey(worker);
  if (status === "healthy") {
    await kv.delete(key);
    return json({ ok: true, worker, status: "healthy" });
  }

  const requestedSeconds = Number(input.cooldown_seconds);
  const requestedMs = Number.isFinite(requestedSeconds)
    ? Math.round(requestedSeconds * 1000)
    : 60 * 60 * 1000;
  const cooldownMs = Math.min(
    AGENT_POOL_MAX_COOLDOWN_MS,
    Math.max(AGENT_POOL_MIN_COOLDOWN_MS, requestedMs),
  );
  const previous = await kv.get<AgentPoolWorkerHealth>(key);
  const now = Date.now();
  const health: AgentPoolWorkerHealth = {
    schema: 1,
    worker,
    provider,
    status: "unhealthy",
    reason,
    run_id: runId,
    failures: (previous.value?.failures ?? 0) + 1,
    updated_at: new Date(now).toISOString(),
    expires_at: new Date(now + cooldownMs).toISOString(),
  };
  await kv.set(key, health, { expireIn: cooldownMs });
  return json({ ok: true, health }, 201);
}

export async function handleAgentPool(
  request: Request,
  url: URL,
  kv: Deno.Kv,
  repository: string,
): Promise<Response> {
  if (request.method !== "POST") {
    return json({ ok: false, error: "method_not_allowed" }, 405);
  }

  let actor: AuthenticatedActor | null;
  try {
    actor = await authenticateAgentPoolRequest(request, repository);
  } catch (error) {
    console.error("Agent pool OIDC failure", error);
    return json({ ok: false, error: "service_unavailable" }, 503);
  }
  if (!actor) {
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

  if (url.pathname.startsWith("/api/agent-pool/b2b/")) {
    return await handleAgentB2B(url, kv, raw, {
      role: actor.role,
      run_id: cleanText(actor.claims.run_id, 80),
    });
  }

  if (url.pathname === "/api/agent-pool/acquire") {
    return await acquireLease(kv, raw, actor);
  }
  if (url.pathname === "/api/agent-pool/transition") {
    return await transitionLease(kv, raw, actor);
  }
  if (url.pathname === "/api/agent-pool/release") {
    return await releaseLease(kv, raw, actor);
  }
  if (url.pathname === "/api/agent-pool/status") {
    return await leaseStatus(kv, raw);
  }
  if (url.pathname === "/api/agent-pool/worker-status") {
    return await workerLeaseStatus(kv, raw);
  }
  if (url.pathname === "/api/agent-pool/worker-health/status") {
    return await workerHealthStatus(kv, raw);
  }
  if (url.pathname === "/api/agent-pool/worker-health/report") {
    return await reportWorkerHealth(kv, raw, actor);
  }

  return json({ ok: false, error: "not_found" }, 404);
}
