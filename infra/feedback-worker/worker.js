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

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
    },
  });
}

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

async function createGitHubIssue(env, payload) {
  if (!env.GITHUB_TOKEN) {
    throw new Error("GITHUB_TOKEN no configurado");
  }

  const repository = cleanText(env.GITHUB_REPOSITORY || DEFAULT_REPOSITORY, 200);
  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)) {
    throw new Error("GITHUB_REPOSITORY inválido");
  }

  const category = CATEGORIES.has(payload.category) ? payload.category : "otro";
  const title = `[Playtest][${category.toUpperCase()}] ${payload.title}`;
  const marker = `\n\n<!-- siga98-feedback source=${payload.source} category=${category} -->`;
  const issue = {
    title: title.slice(0, 256),
    body: (payload.body + marker).slice(0, MAX_BODY + marker.length),
  };

  if (env.GITHUB_LABELS) {
    issue.labels = env.GITHUB_LABELS
      .split(",")
      .map((label) => label.trim())
      .filter(Boolean)
      .slice(0, 10);
  }

  const response = await fetch(`https://api.github.com/repos/${repository}/issues`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${env.GITHUB_TOKEN}`,
      accept: "application/vnd.github+json",
      "content-type": "application/json",
      "user-agent": "SIGA98-Feedback-Gateway",
      "x-github-api-version": "2022-11-28",
    },
    body: JSON.stringify(issue),
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(
      `GitHub devolvió ${response.status}: ${cleanText(data.message || "", 300)}`,
    );
  }
  return data;
}

async function sendOptionalEmail(env, payload, issue) {
  if (!env.RESEND_API_KEY || !env.REPORT_EMAIL_TO || !env.REPORT_EMAIL_FROM) {
    return false;
  }

  const issueUrl = cleanText(issue.html_url || "", 500);
  const escapedBody = escapeHtml(payload.body);
  const escapedUrl = escapeHtml(issueUrl);
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      authorization: `Bearer ${env.RESEND_API_KEY}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      from: env.REPORT_EMAIL_FROM,
      to: [env.REPORT_EMAIL_TO],
      subject: `SIGA-98 · nuevo reporte #${issue.number}: ${payload.title}`,
      html:
        `<p><strong>Issue creado:</strong> <a href="${escapedUrl}">${escapedUrl}</a></p>` +
        `<pre style="white-space:pre-wrap">${escapedBody}</pre>`,
    }),
  });

  return response.ok;
}

export default {
  async fetch(request, env) {
    if (request.method === "GET") {
      return json({ ok: true, service: "siga98-feedback", version: 1 });
    }
    if (request.method !== "POST") {
      return json({ ok: false, error: "method_not_allowed" }, 405);
    }

    const declaredLength = Number(request.headers.get("content-length") || "0");
    if (declaredLength > 24576) {
      return json({ ok: false, error: "payload_too_large" }, 413);
    }

    let raw;
    try {
      raw = await request.json();
    } catch {
      return json({ ok: false, error: "invalid_json" }, 400);
    }

    if (!raw || typeof raw !== "object" || raw.source !== "siga98-f9") {
      return json({ ok: false, error: "invalid_source" }, 400);
    }

    const category = cleanText(raw.category, 32);
    const title = cleanText(raw.title, 120);
    const body = cleanText(raw.body, MAX_BODY);
    if (!CATEGORIES.has(category) || !title || !body) {
      return json({ ok: false, error: "invalid_report" }, 400);
    }

    const payload = {
      source: "siga98-f9",
      category,
      title,
      body,
    };

    try {
      const issue = await createGitHubIssue(env, payload);
      let emailSent = false;
      try {
        emailSent = await sendOptionalEmail(env, payload, issue);
      } catch {
        emailSent = false;
      }

      return json(
        {
          ok: true,
          issue_number: issue.number,
          issue_url: issue.html_url,
          email_sent: emailSent,
        },
        201,
      );
    } catch (error) {
      return json(
        {
          ok: false,
          error: "upstream_failure",
          detail: cleanText(error instanceof Error ? error.message : String(error), 500),
        },
        502,
      );
    }
  },
};
