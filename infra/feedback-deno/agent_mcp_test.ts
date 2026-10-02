// Regresión ejecutable del conector MCP remoto de la mesa (#2180): el flujo
// OAuth que hace ChatGPT de punta a punta, con KV en memoria y sin red.
import { handleAgentMcp } from "./agent_mcp.ts";

const TOKEN = "t".repeat(40);
const BASE = "https://mesa.test";
const REDIRECT = "https://chatgpt.com/connector_platform_oauth_redirect";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

function assertEquals<T>(actual: T, expected: T, message: string): void {
  if (actual !== expected) {
    throw new Error(`${message}: esperado ${expected}, obtenido ${actual}`);
  }
}

async function withKv(fn: (kv: Deno.Kv) => Promise<void>): Promise<void> {
  const previous = Deno.env.get("AGENT_MEMORY_NIVEL2_TOKEN");
  Deno.env.set("AGENT_MEMORY_NIVEL2_TOKEN", TOKEN);
  const kv = await Deno.openKv(":memory:");
  try {
    await fn(kv);
  } finally {
    kv.close();
    if (previous === undefined) Deno.env.delete("AGENT_MEMORY_NIVEL2_TOKEN");
    else Deno.env.set("AGENT_MEMORY_NIVEL2_TOKEN", previous);
  }
}

function pedir(
  kv: Deno.Kv,
  ruta: string,
  init: RequestInit = {},
  ip = "203.0.113.7",
): Promise<Response> {
  const url = new URL(BASE + ruta);
  return handleAgentMcp(new Request(url, init), url, kv, ip);
}

function base64url(bytes: Uint8Array): string {
  let binario = "";
  for (const byte of bytes) binario += String.fromCharCode(byte);
  return btoa(binario).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function pkce(): Promise<{ verifier: string; challenge: string }> {
  const verifier = base64url(crypto.getRandomValues(new Uint8Array(32)));
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(verifier));
  return { verifier, challenge: base64url(new Uint8Array(digest)) };
}

async function registrar(kv: Deno.Kv, redirect = REDIRECT): Promise<Response> {
  return await pedir(kv, "/oauth/register", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ client_name: "ChatGPT", redirect_uris: [redirect] }),
  });
}

function camposAutorizacion(clientId: string, challenge: string): Record<string, string> {
  return {
    client_id: clientId,
    redirect_uri: REDIRECT,
    response_type: "code",
    code_challenge: challenge,
    code_challenge_method: "S256",
    state: "estado-123",
  };
}

async function autorizar(
  kv: Deno.Kv,
  clientId: string,
  challenge: string,
  clave: string,
  ip?: string,
): Promise<Response> {
  return await pedir(kv, "/oauth/authorize", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ ...camposAutorizacion(clientId, challenge), clave }).toString(),
  }, ip);
}

async function canjear(
  kv: Deno.Kv,
  campos: Record<string, string>,
): Promise<{ status: number; data: Record<string, unknown> }> {
  const respuesta = await pedir(kv, "/oauth/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams(campos).toString(),
  });
  return { status: respuesta.status, data: await respuesta.json() };
}

// Registro + autorización + canje: lo que hace ChatGPT al añadir el conector.
async function conectar(
  kv: Deno.Kv,
): Promise<{ clientId: string; acceso: string; refresco: string }> {
  const clientId = (await (await registrar(kv)).json()).client_id as string;
  const { verifier, challenge } = await pkce();
  const redireccion = await autorizar(kv, clientId, challenge, TOKEN);
  const code = new URL(redireccion.headers.get("location")!).searchParams.get("code")!;
  const { data } = await canjear(kv, {
    grant_type: "authorization_code",
    code,
    redirect_uri: REDIRECT,
    client_id: clientId,
    code_verifier: verifier,
  });
  return {
    clientId,
    acceso: data.access_token as string,
    refresco: data.refresh_token as string,
  };
}

async function rpc(
  kv: Deno.Kv,
  acceso: string,
  method: string,
  params: Record<string, unknown> = {},
  id: number | null = 1,
): Promise<{ status: number; data: Record<string, unknown> | null }> {
  const respuesta = await pedir(kv, "/mcp", {
    method: "POST",
    headers: { "content-type": "application/json", authorization: "Bearer " + acceso },
    // id null = notificación: el mensaje va sin id.
    body: JSON.stringify(
      id === null ? { jsonrpc: "2.0", method, params } : { jsonrpc: "2.0", id, method, params },
    ),
  });
  const texto = await respuesta.text();
  return { status: respuesta.status, data: texto ? JSON.parse(texto) : null };
}

Deno.test("los metadatos OAuth anuncian el recurso, PKCE S256 y el registro dinámico", async () => {
  await withKv(async (kv) => {
    const recurso = await (await pedir(kv, "/.well-known/oauth-protected-resource")).json();
    assertEquals(recurso.resource, BASE + "/mcp", "recurso protegido");
    assertEquals(recurso.authorization_servers[0], BASE, "servidor de autorización");

    const servidor = await (await pedir(kv, "/.well-known/oauth-authorization-server")).json();
    assertEquals(servidor.registration_endpoint, BASE + "/oauth/register", "registro");
    assertEquals(servidor.code_challenge_methods_supported.join(), "S256", "solo S256");
  });
});

Deno.test("el registro dinámico solo admite redirect_uri https de ChatGPT", async () => {
  await withKv(async (kv) => {
    assertEquals((await registrar(kv, "https://evil.example/cb")).status, 400, "host ajeno");
    assertEquals((await registrar(kv, "http://chatgpt.com/cb")).status, 400, "sin https");
    const bueno = await registrar(kv);
    assertEquals(bueno.status, 201, "redirect de ChatGPT");
    assert(String((await bueno.json()).client_id).startsWith("mesa-"), "client_id emitido");
  });
});

Deno.test("sin la clave de nivel 2 no hay código, y el formulario no redirige a ciegas", async () => {
  await withKv(async (kv) => {
    const clientId = (await (await registrar(kv)).json()).client_id as string;
    const { challenge } = await pkce();

    const formulario = await pedir(
      kv,
      "/oauth/authorize?" + new URLSearchParams(camposAutorizacion(clientId, challenge)),
    );
    assertEquals(formulario.status, 200, "formulario");
    assert(
      (formulario.headers.get("content-security-policy") ?? "").includes("frame-ancestors 'none'"),
      "sin iframes",
    );

    const mala = await autorizar(kv, clientId, challenge, "clave-equivocada");
    assertEquals(mala.status, 401, "clave mala");
    assertEquals(mala.headers.get("location"), null, "sin redirección");

    const ajeno = await pedir(
      kv,
      "/oauth/authorize?" + new URLSearchParams({
        ...camposAutorizacion(clientId, challenge),
        redirect_uri: "https://chatgpt.com/otra",
      }),
    );
    assertEquals(ajeno.status, 400, "redirect no registrada");

    const sinPkce = await pedir(
      kv,
      "/oauth/authorize?" + new URLSearchParams({
        ...camposAutorizacion(clientId, challenge),
        code_challenge_method: "plain",
      }),
    );
    assertEquals(sinPkce.status, 400, "PKCE plain rechazado");
  });
});

Deno.test("tras cinco claves malas la IP espera aunque luego acierte", async () => {
  await withKv(async (kv) => {
    const clientId = (await (await registrar(kv)).json()).client_id as string;
    const { challenge } = await pkce();
    for (let i = 0; i < 5; i++) {
      assertEquals(
        (await autorizar(kv, clientId, challenge, "mala", "198.51.100.9")).status,
        401,
        "fallo",
      );
    }
    assertEquals(
      (await autorizar(kv, clientId, challenge, TOKEN, "198.51.100.9")).status,
      429,
      "bloqueada",
    );
    assertEquals(
      (await autorizar(kv, clientId, challenge, TOKEN, "198.51.100.10")).status,
      302,
      "otra IP",
    );
  });
});

Deno.test("el código exige el verificador PKCE y solo vale una vez", async () => {
  await withKv(async (kv) => {
    const clientId = (await (await registrar(kv)).json()).client_id as string;
    const { verifier, challenge } = await pkce();
    const redireccion = await autorizar(kv, clientId, challenge, TOKEN);
    assertEquals(redireccion.status, 302, "autorizado");
    const destino = new URL(redireccion.headers.get("location")!);
    assertEquals(destino.origin + destino.pathname, REDIRECT, "vuelve a ChatGPT");
    assertEquals(destino.searchParams.get("state"), "estado-123", "conserva state");
    const code = destino.searchParams.get("code")!;

    const otro = (await pkce()).verifier;
    const campos = {
      grant_type: "authorization_code",
      code,
      redirect_uri: REDIRECT,
      client_id: clientId,
      code_verifier: otro,
    };
    assertEquals((await canjear(kv, campos)).data.error, "invalid_grant", "verificador ajeno");
    // El intento fallido ya consumió el código: no se puede reintentar con el bueno.
    assertEquals(
      (await canjear(kv, { ...campos, code_verifier: verifier })).data.error,
      "invalid_grant",
      "código consumido",
    );
  });
});

Deno.test("el refresh rota: el viejo deja de valer", async () => {
  await withKv(async (kv) => {
    const { clientId, refresco } = await conectar(kv);
    const primero = await canjear(kv, {
      grant_type: "refresh_token",
      refresh_token: refresco,
      client_id: clientId,
    });
    assertEquals(primero.status, 200, "refresh válido");
    assert(primero.data.refresh_token !== refresco, "refresh nuevo");
    const repetido = await canjear(kv, {
      grant_type: "refresh_token",
      refresh_token: refresco,
      client_id: clientId,
    });
    assertEquals(repetido.data.error, "invalid_grant", "refresh reutilizado");
  });
});

Deno.test("/mcp sin token responde 401 con la pista de metadatos", async () => {
  await withKv(async (kv) => {
    const sin = await pedir(kv, "/mcp", { method: "POST", body: "{}" });
    assertEquals(sin.status, 401, "sin token");
    assert(
      (sin.headers.get("www-authenticate") ?? "").includes(
        `resource_metadata="${BASE}/.well-known/oauth-protected-resource"`,
      ),
      "WWW-Authenticate",
    );
    // La clave de nivel 2 no es un token de acceso del conector.
    assertEquals((await rpc(kv, TOKEN, "tools/list")).status, 401, "clave como bearer");
  });
});

Deno.test("ChatGPT ve la mesa y publica como odiseo, sin acceso a escribir memoria", async () => {
  await withKv(async (kv) => {
    const { acceso } = await conectar(kv);

    const inicio = await rpc(kv, acceso, "initialize", { protocolVersion: "2025-06-18" });
    const resultado = inicio.data!.result as Record<string, unknown>;
    assertEquals(resultado.protocolVersion, "2025-06-18", "versión negociada");

    assertEquals(
      (await rpc(kv, acceso, "notifications/initialized", {}, null)).status,
      202,
      "notificación",
    );

    const lista = await rpc(kv, acceso, "tools/list");
    const nombres = (lista.data!.result as { tools: { name: string }[] }).tools
      .map((t) => t.name);
    assertEquals(nombres.length, 6, "seis herramientas");
    assert(!nombres.includes("recordar") && !nombres.includes("olvidar_leccion"), "sin escritura");

    const aviso = await rpc(kv, acceso, "tools/call", {
      name: "avisar",
      arguments: { tipo: "en-curso", texto: "Odiseo revisa #2145 desde ChatGPT", refs: [2145] },
    });
    const publicado = JSON.parse(
      (aviso.data!.result as { content: { text: string }[] }).content[0].text,
    );
    assertEquals(publicado.agente, "odiseo", "firma fija");

    const activos = await rpc(kv, acceso, "tools/call", { name: "avisos_activos" });
    assert(
      (activos.data!.result as { content: { text: string }[] }).content[0].text.includes(
        "#2145",
      ),
      "aviso visible",
    );

    const secreto = await rpc(kv, acceso, "tools/call", {
      name: "avisar",
      arguments: { tipo: "aviso", texto: "token ghp_" + "a".repeat(36) },
    });
    assertEquals(
      (secreto.data!.result as { isError?: boolean }).isError,
      true,
      "secreto rechazado",
    );

    const desconocido = await rpc(kv, acceso, "resources/list");
    assertEquals(
      (desconocido.data!.error as { code: number }).code,
      -32601,
      "método no soportado",
    );
  });
});
