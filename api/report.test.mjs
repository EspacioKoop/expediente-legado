import test, { describe, beforeEach, afterEach } from "node:test";
import assert from "node:assert/strict";
import handler from "./report.js";

function createMockReq({ method = "POST", headers = {}, body = null } = {}) {
  return {
    method,
    headers: { ...headers },
    body,
  };
}

function createMockRes() {
  const res = {
    statusCode: 200,
    headers: {},
    body: null,
    setHeader(key, value) {
      res.headers[key.toLowerCase()] = value;
      return res;
    },
    status(code) {
      res.statusCode = code;
      return res;
    },
    json(data) {
      res.body = data;
      return res;
    },
  };
  return res;
}

describe("api/report.js handler", () => {
  let originalFetch;
  let originalEnv;

  beforeEach(() => {
    originalFetch = globalThis.fetch;
    originalEnv = { ...process.env };
  });

  afterEach(() => {
    globalThis.fetch = originalFetch;
    process.env = originalEnv;
  });

  test("sets security and cache headers on response", async () => {
    const req = createMockReq({ method: "GET" });
    const res = createMockRes();
    await handler(req, res);

    assert.equal(res.headers["cache-control"], "no-store");
    assert.equal(res.headers["x-content-type-options"], "nosniff");
  });

  test("GET request returns status service info", async () => {
    const req = createMockReq({ method: "GET" });
    const res = createMockRes();
    await handler(req, res);

    assert.equal(res.statusCode, 200);
    assert.deepEqual(res.body, {
      ok: true,
      service: "siga98-feedback",
      version: 1,
    });
  });

  test("disallowed methods return 405 method_not_allowed", async () => {
    for (const method of ["PUT", "DELETE", "PATCH"]) {
      const req = createMockReq({ method });
      const res = createMockRes();
      await handler(req, res);

      assert.equal(res.statusCode, 405);
      assert.deepEqual(res.body, {
        ok: false,
        error: "method_not_allowed",
      });
    }
  });

  test("payload exceeding max content length returns 413 payload_too_large", async () => {
    const req = createMockReq({
      method: "POST",
      headers: { "content-length": "25000" },
      body: { source: "siga98-f9", category: "bug", title: "t", body: "b" },
    });
    const res = createMockRes();
    await handler(req, res);

    assert.equal(res.statusCode, 413);
    assert.deepEqual(res.body, {
      ok: false,
      error: "payload_too_large",
    });
  });

  test("missing or invalid source returns 400 invalid_source", async () => {
    const invalidBodies = [
      null,
      undefined,
      "not an object",
      {},
      { source: "other", category: "bug", title: "t", body: "b" },
    ];

    for (const body of invalidBodies) {
      const req = createMockReq({ method: "POST", body });
      const res = createMockRes();
      await handler(req, res);

      assert.equal(res.statusCode, 400);
      assert.deepEqual(res.body, {
        ok: false,
        error: "invalid_source",
      });
    }
  });

  test("invalid category, title, or body returns 400 invalid_report", async () => {
    const invalidReports = [
      { source: "siga98-f9", category: "unknown", title: "t", body: "b" },
      { source: "siga98-f9", category: "bug", title: "  ", body: "b" },
      { source: "siga98-f9", category: "bug", title: "t", body: "  " },
      { source: "siga98-f9", category: "bug", title: 123, body: "b" },
    ];

    for (const body of invalidReports) {
      const req = createMockReq({ method: "POST", body });
      const res = createMockRes();
      await handler(req, res);

      assert.equal(res.statusCode, 400);
      assert.deepEqual(res.body, {
        ok: false,
        error: "invalid_report",
      });
    }
  });

  test("successful report creation on GitHub without email", async () => {
    process.env.GITHUB_TOKEN = "gh_test_token";
    delete process.env.RESEND_API_KEY;

    const fetchCalls = [];
    globalThis.fetch = async (url, options) => {
      fetchCalls.push({ url, options });
      return {
        ok: true,
        status: 201,
        json: async () => ({
          number: 101,
          html_url: "https://github.com/EspacioKoop/expediente-legado/issues/101",
        }),
      };
    };

    const req = createMockReq({
      method: "POST",
      body: {
        source: "siga98-f9",
        category: "bug",
        title: "Error de Renderizado",
        body: "Fallo en la pantalla principal",
      },
    });
    const res = createMockRes();
    await handler(req, res);

    assert.equal(res.statusCode, 201);
    assert.deepEqual(res.body, {
      ok: true,
      issue_number: 101,
      issue_url: "https://github.com/EspacioKoop/expediente-legado/issues/101",
      email_sent: false,
    });

    assert.equal(fetchCalls.length, 1);
    const [call] = fetchCalls;
    assert.equal(
      call.url,
      "https://api.github.com/repos/EspacioKoop/expediente-legado/issues",
    );
    assert.equal(call.options.method, "POST");
    assert.equal(call.options.headers.authorization, "Bearer gh_test_token");

    const payload = JSON.parse(call.options.body);
    assert.equal(payload.title, "[Playtest][BUG] Error de Renderizado");
    assert.ok(payload.body.includes("Fallo en la pantalla principal"));
    assert.ok(
      payload.body.includes("<!-- siga98-feedback source=siga98-f9 category=bug -->"),
    );
  });

  test("successful report creation with email, fixed repository, labels, and escaped HTML", async () => {
    process.env.GITHUB_TOKEN = "gh_test_token";
    process.env.GITHUB_REPOSITORY = "EspacioKoop/expediente-legado";
    process.env.GITHUB_LABELS = "feedback, playtest, urgente";
    process.env.RESEND_API_KEY = "re_test_key";
    process.env.REPORT_EMAIL_TO = "destino@example.com";
    process.env.REPORT_EMAIL_FROM = "origen@example.com";

    const fetchCalls = [];
    globalThis.fetch = async (url, options) => {
      fetchCalls.push({ url, options });
      if (url.includes("github.com")) {
        return {
          ok: true,
          status: 201,
          json: async () => ({
            number: 202,
            html_url: "https://github.com/EspacioKoop/expediente-legado/issues/202?a=1&b=2",
          }),
        };
      }
      if (url.includes("resend.com")) {
        return {
          ok: true,
          status: 200,
          json: async () => ({ id: "email_123" }),
        };
      }
      throw new Error(`Unexpected URL: ${url}`);
    };

    const req = createMockReq({
      method: "POST",
      body: {
        source: "siga98-f9",
        category: "accesibilidad",
        title: "Problema con <script>alert('xss')</script>",
        body: "Texto con & < > \" ' caracteres especiales.",
      },
    });
    const res = createMockRes();
    await handler(req, res);

    assert.equal(res.statusCode, 201);
    assert.equal(res.body.ok, true);
    assert.equal(res.body.issue_number, 202);
    assert.equal(res.body.email_sent, true);

    assert.equal(fetchCalls.length, 2);

    // GitHub fetch assertion
    const ghPayload = JSON.parse(fetchCalls[0].options.body);
    assert.deepEqual(ghPayload.labels, ["feedback", "playtest", "urgente"]);

    // Resend fetch assertion
    const emailPayload = JSON.parse(fetchCalls[1].options.body);
    assert.equal(emailPayload.from, "origen@example.com");
    assert.deepEqual(emailPayload.to, ["destino@example.com"]);
    assert.ok(
      emailPayload.subject.includes("SIGA-98 · nuevo reporte #202: Problema con <script>alert('xss')</script>"),
    );
    assert.ok(
      emailPayload.html.includes("Texto con &amp; &lt; &gt; &quot; &#039; caracteres especiales."),
    );
    assert.ok(
      emailPayload.html.includes(
        "https://github.com/EspacioKoop/expediente-legado/issues/202?a=1&amp;b=2",
      ),
    );
  });

  test("rejects private operational text and non-game destinations without POST or leakage", async () => {
    process.env.GITHUB_TOKEN = "gh_example_token";
    let calls = 0;
    globalThis.fetch = async () => {
      calls++;
      throw new Error("fetch must not run");
    };
    const standard = {
      source: "siga98-f9",
      category: "bug",
      title: "Interfaz de juego",
      body: "La cámara se atasca en SIGA-98.",
    };
    for (const message of [
      "HERMES_CUSTOM_GROQ_API_KEY=EXAMPLE_NEVER_PUBLISH",
      "Mira este log en /home/testuser/.config/hermes/gateway",
      "Conectar la red por WireGuard",
      "Equipo local 192.168.1.28 no responde",
    ]) {
      const res = createMockRes();
      await handler(createMockReq({ body: { ...standard, body: message } }), res);
      assert.equal(res.statusCode, 502);
      assert.equal(res.body.error, "upstream_failure");
      assert.equal(res.body.detail, "Reporte no apto para un repositorio público");
      assert.ok(!JSON.stringify(res.body).includes(message));
    }
    process.env.GITHUB_REPOSITORY = "eGurucharri/infra-casa";
    const res = createMockRes();
    await handler(createMockReq({ body: standard }), res);
    assert.equal(res.statusCode, 502);
    assert.equal(res.body.detail, "Destino GitHub no permitido para el feedback del juego");
    assert.equal(calls, 0);
  });

  test("upstream failure when GITHUB_TOKEN is missing or GitHub API fails", async () => {
    delete process.env.GITHUB_TOKEN;

    const req = createMockReq({
      method: "POST",
      body: {
        source: "siga98-f9",
        category: "sugerencia",
        title: "Sugerencia",
        body: "Detalle",
      },
    });
    let res = createMockRes();
    await handler(req, res);

    assert.equal(res.statusCode, 502);
    assert.deepEqual(res.body, {
      ok: false,
      error: "upstream_failure",
      detail: "GITHUB_TOKEN no configurado",
    });

    // GitHub API error status
    process.env.GITHUB_TOKEN = "token";
    globalThis.fetch = async () => ({
      ok: false,
      status: 401,
      json: async () => ({ message: "Bad credentials" }),
    });

    res = createMockRes();
    await handler(req, res);

    assert.equal(res.statusCode, 502);
    assert.deepEqual(res.body, {
      ok: false,
      error: "upstream_failure",
      detail: "GitHub devolvió 401: Bad credentials",
    });

    // Invalid GITHUB_REPOSITORY
    process.env.GITHUB_REPOSITORY = "invalid-repo-format";
    res = createMockRes();
    await handler(req, res);

    assert.equal(res.statusCode, 502);
    assert.deepEqual(res.body, {
      ok: false,
      error: "upstream_failure",
      detail: "GITHUB_REPOSITORY inválido",
    });
  });

  test("email sending failure does not fail the report creation", async () => {
    process.env.GITHUB_TOKEN = "gh_test_token";
    process.env.RESEND_API_KEY = "re_test_key";
    process.env.REPORT_EMAIL_TO = "destino@example.com";
    process.env.REPORT_EMAIL_FROM = "origen@example.com";

    globalThis.fetch = async (url) => {
      if (url.includes("github.com")) {
        return {
          ok: true,
          status: 201,
          json: async () => ({
            number: 303,
            html_url: "https://github.com/EspacioKoop/expediente-legado/issues/303",
          }),
        };
      }
      if (url.includes("resend.com")) {
        throw new Error("Resend service down");
      }
      throw new Error(`Unexpected URL: ${url}`);
    };

    const req = createMockReq({
      method: "POST",
      body: {
        source: "siga98-f9",
        category: "queja",
        title: "Queja",
        body: "Detalle de queja",
      },
    });
    const res = createMockRes();
    await handler(req, res);

    assert.equal(res.statusCode, 201);
    assert.deepEqual(res.body, {
      ok: true,
      issue_number: 303,
      issue_url: "https://github.com/EspacioKoop/expediente-legado/issues/303",
      email_sent: false,
    });
  });
});
