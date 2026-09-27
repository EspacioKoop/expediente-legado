const DEFAULT_REPOSITORY = "EspacioKoop/expediente-legado";
const CATEGORIES = new Set([
  "bug",
  "mejora",
  "sugerencia",
  "queja",
  "accesibilidad",
  "otro",
]);
const MAX_BODY = 16000;
const MAX_REQUEST_BYTES = 24576;
const WINDOW_MS = 60_000;
const ACTOR_LIMIT = 6;
const GLOBAL_LIMIT = 30;

interface CounterState {
  count: number;
  resetAt: number;
}

let kvPromise: Promise<Deno.Kv> | null = null;

function json(data: unknown, status = 200, extraHeaders: HeadersInit = {}): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
      "referrer-policy": "no-referrer",
      ...extraHeaders,
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

function getKv(): Promise<Deno.Kv> {
  kvPromise ??= Deno.openKv();
  return kvPromise;
}

async function actorKey(remoteIp: string, secret: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign("HMAC", key, encoder.encode(remoteIp));
  return Array.from(new Uint8Array(digest).slice(0, 16), (byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
}

function nextCounter(
  current: CounterState | null,
  limit: number,
  now: number,
): CounterState | null {
  if (!current || current.resetAt <= now) {
    return { count: 1, resetAt: now + WINDOW_MS };
  }
  if (current.count >= limit) {
    return null;
  }
  return { count: current.count + 1, resetAt: current.resetAt };
}

async function consumeRateLimits(
  kv: Deno.Kv,
  actor: string,
): Promise<boolean> {
  const actorDbKey: Deno.KvKey = ["rate", "actor", actor];
  const globalDbKey: Deno.KvKey = ["rate", "global"];

  for (let attempt = 0; attempt < 5; attempt += 1) {
    const [actorEntry, globalEntry] = await Promise.all([
      kv.get<CounterState>(actorDbKey),
      kv.get<CounterState>(globalDbKey),
    ]);
    const now = Date.now();
    const actorNext = nextCounter(actorEntry.value, ACTOR_LIMIT, now);
    const globalNext = nextCounter(globalEntry.value, GLOBAL_LIMIT, now);
    if (!actorNext || !globalNext) {
      return false;
    }

    const ttl = WINDOW_MS * 2;
    const committed = await kv.atomic()
      .check(actorEntry, globalEntry)
      .set(actorDbKey, actorNext, { expireIn: ttl })
      .set(globalDbKey, globalNext, { expireIn: ttl })
      .commit();

    if (committed.ok) {
      return true;
    }
  }

  return false;
}

async function createGitHubIssue(payload: {
  source: string;
  category: string;
  title: string;
  body: string;
}): Promise<Record<string, unknown>> {
  const token = Deno.env.get("GITHUB_TOKEN") ?? "";
  if (!token) {
    throw new Error("GITHUB_TOKEN no configurado");
  }

  const repository = cleanText(
    Deno.env.get("GITHUB_REPOSITORY") || DEFAULT_REPOSITORY,
    200,
  );
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)) {
    throw new Error("GITHUB_REPOSITORY inválido");
  }

  const category = CATEGORIES.has(payload.category) ? payload.category : "otro";
  const title = `[Playtest][${category.toUpperCase()}] ${payload.title}`;
  const marker =
    `\n\n<!-- siga98-feedback source=${payload.source} category=${category} provider=deno -->`;

  const issue: Record<string, unknown> = {
    title: title.slice(0, 256),
    body: (payload.body + marker).slice(0, MAX_BODY + marker.length),
  };

  const labelsRaw = Deno.env.get("GITHUB_LABELS") ?? "";
  if (labelsRaw) {
    issue.labels = labelsRaw
      .split(",")
      .map((label) => label.trim())
      .filter(Boolean)
      .slice(0, 10);
  }

  const response = await fetch(`https://api.github.com/repos/${repository}/issues`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      accept: "application/vnd.github+json",
      "content-type": "application/json",
      "user-agent": "SIGA98-Feedback-Deno",
      "x-github-api-version": "2022-11-28",
    },
    body: JSON.stringify(issue),
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(`GitHub devolvió ${response.status}`);
  }
  return data as Record<string, unknown>;
}

async function handler(
  request: Request,
  info: Deno.ServeHandlerInfo,
): Promise<Response> {
  const url = new URL(request.url);

  if (request.method === "GET" && (url.pathname === "/" || url.pathname === "/health")) {
    let kvConfigured = false;
    try {
      await getKv();
      kvConfigured = true;
    } catch {
      kvConfigured = false;
    }

    return json({
      ok: true,
      service: "siga98-feedback-deno",
      version: 1,
      github_configured: Boolean(Deno.env.get("GITHUB_TOKEN")),
      kv_configured: kvConfigured,
    });
  }

  if (url.pathname !== "/api/report") {
    return json({ ok: false, error: "not_found" }, 404);
  }
  if (request.method !== "POST") {
    return json({ ok: false, error: "method_not_allowed" }, 405);
  }

  const declaredLength = Number(request.headers.get("content-length") || "0");
  if (
    Number.isFinite(declaredLength) &&
    declaredLength > MAX_REQUEST_BYTES
  ) {
    return json({ ok: false, error: "payload_too_large" }, 413);
  }

  const token = Deno.env.get("GITHUB_TOKEN") ?? "";
  if (!token) {
    return json({ ok: false, error: "service_unavailable" }, 503);
  }

  let kv: Deno.Kv;
  try {
    kv = await getKv();
  } catch (error) {
    console.error("Deno KV unavailable", error);
    return json({ ok: false, error: "service_unavailable" }, 503);
  }

  const remoteIp = info.remoteAddr.hostname || "unknown";
  const actor = await actorKey(remoteIp, token);
  let allowed = false;
  try {
    allowed = await consumeRateLimits(kv, actor);
  } catch (error) {
    console.error("Rate limit failure", error);
    return json({ ok: false, error: "service_unavailable" }, 503);
  }
  if (!allowed) {
    return json(
      { ok: false, error: "rate_limited" },
      429,
      { "retry-after": "60" },
    );
  }

  let bytes: Uint8Array;
  try {
    bytes = new Uint8Array(await request.arrayBuffer());
  } catch {
    return json({ ok: false, error: "invalid_body" }, 400);
  }
  if (bytes.byteLength > MAX_REQUEST_BYTES) {
    return json({ ok: false, error: "payload_too_large" }, 413);
  }

  let raw: unknown;
  try {
    raw = JSON.parse(new TextDecoder().decode(bytes));
  } catch {
    return json({ ok: false, error: "invalid_json" }, 400);
  }

  if (
    !raw ||
    typeof raw !== "object" ||
    (raw as Record<string, unknown>).schema !== 1 ||
    (raw as Record<string, unknown>).source !== "siga98-f9"
  ) {
    return json({ ok: false, error: "invalid_source" }, 400);
  }

  const record = raw as Record<string, unknown>;
  const category = cleanText(record.category, 32);
  const title = cleanTitle(record.title, 120);
  const body = cleanText(record.body, MAX_BODY);
  if (!CATEGORIES.has(category) || !title || !body) {
    return json({ ok: false, error: "invalid_report" }, 400);
  }

  try {
    const issue = await createGitHubIssue({
      source: "siga98-f9",
      category,
      title,
      body,
    });
    return json(
      {
        ok: true,
        issue_number: issue.number,
        issue_url: issue.html_url,
        email_sent: false,
      },
      201,
    );
  } catch (error) {
    console.error("GitHub issue creation failed", error);
    return json({ ok: false, error: "upstream_failure" }, 502);
  }
}

Deno.serve(handler);
