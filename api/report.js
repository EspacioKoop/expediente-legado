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

function cleanText(value, max) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, max);
}

function escapeHtml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

async function createGitHubIssue(payload) {
  const token = process.env.GITHUB_TOKEN;
  if (!token) throw new Error("GITHUB_TOKEN no configurado");

  const repository = cleanText(
    process.env.GITHUB_REPOSITORY || DEFAULT_REPOSITORY,
    200,
  );
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)) {
    throw new Error("GITHUB_REPOSITORY inválido");
  }

  const category = CATEGORIES.has(payload.category) ? payload.category : "otro";
  const marker =
    `\n\n<!-- siga98-feedback source=${payload.source} category=${category} -->`;
  const issue = {
    title: `[Playtest][${category.toUpperCase()}] ${payload.title}`.slice(
      0,
      256,
    ),
    body: (payload.body + marker).slice(0, MAX_BODY + marker.length),
  };

  if (process.env.GITHUB_LABELS) {
    issue.labels = process.env.GITHUB_LABELS
      .split(",")
      .map((label) => label.trim())
      .filter(Boolean)
      .slice(0, 10);
  }

  const response = await fetch(
    `https://api.github.com/repos/${repository}/issues`,
    {
      method: "POST",
      headers: {
        authorization: `Bearer ${token}`,
        accept: "application/vnd.github+json",
        "content-type": "application/json",
        "user-agent": "SIGA98-Feedback-Gateway",
        "x-github-api-version": "2022-11-28",
      },
      body: JSON.stringify(issue),
    },
  );

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(
      `GitHub devolvió ${response.status}: ${cleanText(
        data.message || "",
        300,
      )}`,
    );
  }
  return data;
}

async function sendOptionalEmail(payload, issue) {
  const apiKey = process.env.RESEND_API_KEY;
  const to = process.env.REPORT_EMAIL_TO;
  const from = process.env.REPORT_EMAIL_FROM;
  if (!apiKey || !to || !from) return false;

  const issueUrl = cleanText(issue.html_url || "", 500);
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      authorization: `Bearer ${apiKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: [to],
      subject: `SIGA-98 · nuevo reporte #${issue.number}: ${payload.title}`,
      html:
        `<p><strong>Issue creado:</strong> <a href="${escapeHtml(
          issueUrl,
        )}">${escapeHtml(issueUrl)}</a></p>` +
        `<pre style="white-space:pre-wrap">${escapeHtml(payload.body)}</pre>`,
    }),
  });
  return response.ok;
}

export default async function handler(request, response) {
  response.setHeader("Cache-Control", "no-store");
  response.setHeader("X-Content-Type-Options", "nosniff");

  if (request.method === "GET") {
    return response
      .status(200)
      .json({ ok: true, service: "siga98-feedback", version: 1 });
  }
  if (request.method !== "POST") {
    return response.status(405).json({ ok: false, error: "method_not_allowed" });
  }

  const declaredLength = Number(request.headers["content-length"] || "0");
  if (declaredLength > 24576) {
    return response.status(413).json({ ok: false, error: "payload_too_large" });
  }

  const raw = request.body;
  if (!raw || typeof raw !== "object" || raw.source !== "siga98-f9") {
    return response.status(400).json({ ok: false, error: "invalid_source" });
  }

  const category = cleanText(raw.category, 32);
  const title = cleanText(raw.title, 120);
  const body = cleanText(raw.body, MAX_BODY);
  if (!CATEGORIES.has(category) || !title || !body) {
    return response.status(400).json({ ok: false, error: "invalid_report" });
  }

  const payload = {
    source: "siga98-f9",
    category,
    title,
    body,
  };

  try {
    const issue = await createGitHubIssue(payload);
    let emailSent = false;
    try {
      emailSent = await sendOptionalEmail(payload, issue);
    } catch {
      emailSent = false;
    }
    return response.status(201).json({
      ok: true,
      issue_number: issue.number,
      issue_url: issue.html_url,
      email_sent: emailSent,
    });
  } catch (error) {
    return response.status(502).json({
      ok: false,
      error: "upstream_failure",
      detail: cleanText(
        error instanceof Error ? error.message : String(error),
        500,
      ),
    });
  }
}
