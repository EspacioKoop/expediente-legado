// Conector MCP remoto de la mesa para ChatGPT (#2180).
//
// Las sesiones de ChatGPT (Odiseo en el navegador) no pueden lanzar el MCP local
// `siga98-memoria`, que va por stdio, y los conectores de ChatGPT solo aceptan
// OAuth. Aquí se sirve la misma mesa (avisos, presencia y búsqueda en la memoria)
// por Streamable HTTP, con un OAuth 2.1 mínimo:
// - registro dinámico, limitado a `redirect_uri` de ChatGPT;
// - PKCE S256 obligatorio;
// - autorización con la clave de nivel 2, para no dar de alta secretos nuevos en
//   Deno Deploy;
// - tokens opacos guardados como hash, con caducidad y refresh rotatorio.
// No expone `recordar`, `olvidar_leccion` ni las reservas: ChatGPT lee la memoria
// común y coordina, pero no la reescribe.
import { avisar, avisosActivos, latido, presentes, resolver } from "./agent_coord.ts";
import { nivel2TokenMatches, searchAgentMemory } from "./agent_memory.ts";

const AGENTE = "odiseo";
const PROTOCOLOS = ["2025-11-25", "2025-06-18", "2025-03-26"];
const REDIRECT_HOSTS = ["chatgpt.com", "chat.openai.com"];
const SCOPE = "mesa";

const MINUTO_MS = 60 * 1000;
const CODIGO_TTL_MS = 5 * MINUTO_MS;
const ACCESO_TTL_MS = 60 * MINUTO_MS;
const REFRESCO_TTL_MS = 30 * 24 * 60 * MINUTO_MS;
const CLIENTE_TTL_MS = 90 * 24 * 60 * MINUTO_MS;
// La clave de nivel 2 tiene 32 caracteres o más: el límite no la protege de la
// fuerza bruta (ya es inviable), sino de que alguien sature la KV a intentos.
const VENTANA_MS = 15 * MINUTO_MS;
const FALLOS_MAX = 5;
const REGISTROS_MAX = 10;
const MCP_MAX_BYTES = 16 * 1024;

const RUTAS = new Set([
  "/mcp",
  "/.well-known/oauth-protected-resource",
  "/.well-known/oauth-protected-resource/mcp",
  "/.well-known/oauth-authorization-server",
  "/oauth/register",
  "/oauth/authorize",
  "/oauth/token",
]);

interface Cliente {
  redirect_uris: string[];
  client_name: string;
  creado: string;
}

interface Codigo {
  client_id: string;
  redirect_uri: string;
  code_challenge: string;
}

interface Concesion {
  client_id: string;
}

export function esRutaMcp(pathname: string): boolean {
  return RUTAS.has(pathname);
}

// Deno Deploy termina TLS delante: la URL que llega puede decir http.
function origen(url: URL): string {
  const local = url.hostname === "localhost" || url.hostname === "127.0.0.1";
  return (local ? url.protocol : "https:") + "//" + url.host;
}

function json(data: unknown, status = 200, extra: HeadersInit = {}): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      ...extra,
    },
  });
}

function aleatorio(bytes = 32): string {
  return base64url(crypto.getRandomValues(new Uint8Array(bytes)));
}

function base64url(bytes: Uint8Array): string {
  let binario = "";
  for (const byte of bytes) binario += String.fromCharCode(byte);
  return btoa(binario).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function resumen(valor: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(valor));
  return base64url(new Uint8Array(digest));
}

function texto(valor: unknown, max: number): string {
  return typeof valor === "string" ? valor.trim().slice(0, max) : "";
}

// Cuenta por IP y ventana fija. Devuelve false si ya se pasó del máximo.
async function dentroDelLimite(
  kv: Deno.Kv,
  tipo: string,
  ip: string,
  max: number,
): Promise<boolean> {
  const ventana = Math.floor(Date.now() / VENTANA_MS);
  const actual = await kv.get<Deno.KvU64>(["agent_mcp", "limite", tipo, ip, ventana]);
  return Number(actual.value?.value ?? 0n) < max;
}

async function contar(kv: Deno.Kv, tipo: string, ip: string): Promise<void> {
  const ventana = Math.floor(Date.now() / VENTANA_MS);
  await kv.atomic()
    .sum(["agent_mcp", "limite", tipo, ip, ventana], 1n)
    .commit();
  // `sum` no admite expireIn: la clave caduca reescribiéndola con su valor.
  const clave = ["agent_mcp", "limite", tipo, ip, ventana];
  const actual = await kv.get<Deno.KvU64>(clave);
  if (actual.value) await kv.set(clave, actual.value, { expireIn: 2 * VENTANA_MS });
}

function redirectValido(valor: unknown): string | null {
  if (typeof valor !== "string" || valor.length > 512) return null;
  try {
    const url = new URL(valor);
    if (url.protocol !== "https:" || !REDIRECT_HOSTS.includes(url.hostname)) return null;
    if (url.username || url.password || url.hash) return null;
    return url.toString();
  } catch {
    return null;
  }
}

function metadatosRecurso(base: string): Response {
  return json({
    resource: base + "/mcp",
    authorization_servers: [base],
    bearer_methods_supported: ["header"],
    scopes_supported: [SCOPE],
  });
}

function metadatosServidor(base: string): Response {
  return json({
    issuer: base,
    authorization_endpoint: base + "/oauth/authorize",
    token_endpoint: base + "/oauth/token",
    registration_endpoint: base + "/oauth/register",
    response_types_supported: ["code"],
    grant_types_supported: ["authorization_code", "refresh_token"],
    code_challenge_methods_supported: ["S256"],
    token_endpoint_auth_methods_supported: ["none"],
    scopes_supported: [SCOPE],
  });
}

async function registrar(request: Request, kv: Deno.Kv, ip: string): Promise<Response> {
  if (!await dentroDelLimite(kv, "registro", ip, REGISTROS_MAX)) {
    return json({ error: "slow_down" }, 429);
  }
  await contar(kv, "registro", ip);

  let cuerpo: Record<string, unknown>;
  try {
    const bruto = await request.text();
    if (bruto.length > 8192) return json({ error: "invalid_client_metadata" }, 400);
    cuerpo = JSON.parse(bruto);
  } catch {
    return json({ error: "invalid_client_metadata" }, 400);
  }
  const pedidas = Array.isArray(cuerpo?.redirect_uris) ? cuerpo.redirect_uris : [];
  const redirects = pedidas.map(redirectValido);
  if (redirects.length === 0 || redirects.length > 5 || redirects.includes(null)) {
    return json({
      error: "invalid_redirect_uri",
      error_description: "solo se admiten redirect_uri https de " + REDIRECT_HOSTS.join(", "),
    }, 400);
  }

  const clientId = "mesa-" + aleatorio(18);
  const cliente: Cliente = {
    redirect_uris: redirects as string[],
    client_name: texto(cuerpo.client_name, 80) || "ChatGPT",
    creado: new Date().toISOString(),
  };
  await kv.set(["agent_mcp", "cliente", clientId], cliente, { expireIn: CLIENTE_TTL_MS });
  return json({
    client_id: clientId,
    client_id_issued_at: Math.floor(Date.now() / 1000),
    client_name: cliente.client_name,
    redirect_uris: cliente.redirect_uris,
    grant_types: ["authorization_code", "refresh_token"],
    response_types: ["code"],
    token_endpoint_auth_method: "none",
  }, 201);
}

function escapar(valor: string): string {
  return valor.replace(
    /[&<>"']/g,
    (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c] as string,
  );
}

function pagina(contenido: string, status = 200): Response {
  const html = `<!doctype html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Mesa SIGA-98</title><style>
body{font:16px system-ui,sans-serif;max-width:28rem;margin:3rem auto;padding:0 1rem;background:#111;color:#eee}
input,button{font:inherit;width:100%;box-sizing:border-box;padding:.6rem;margin:.4rem 0}
.error{color:#f88}</style></head><body>${contenido}</body></html>`;
  return new Response(html, {
    status,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
      // form-action también cubre la redirección a ChatGPT que sigue al envío.
      "content-security-policy": "default-src 'none'; style-src 'unsafe-inline'; " +
        "form-action 'self' " + REDIRECT_HOSTS.map((h) => "https://" + h).join(" ") +
        "; frame-ancestors 'none'",
      "referrer-policy": "no-referrer",
    },
  });
}

interface PeticionAutorizacion {
  client_id: string;
  redirect_uri: string;
  code_challenge: string;
  state: string;
}

// Valida lo que llega por la URL (GET) o por el formulario (POST). Si el cliente
// o el redirect no cuadran no se redirige a ningún sitio: se muestra un error.
async function leerAutorizacion(
  kv: Deno.Kv,
  campos: URLSearchParams,
): Promise<PeticionAutorizacion | string> {
  const clientId = texto(campos.get("client_id"), 80);
  const cliente = clientId ? await kv.get<Cliente>(["agent_mcp", "cliente", clientId]) : null;
  if (!cliente?.value) return "Cliente desconocido: vuelve a añadir el conector en ChatGPT.";
  const redirect = texto(campos.get("redirect_uri"), 512);
  if (!cliente.value.redirect_uris.includes(redirect)) return "redirect_uri no registrada.";
  if (campos.get("response_type") !== "code") return "response_type no admitido.";
  const challenge = texto(campos.get("code_challenge"), 128);
  if (campos.get("code_challenge_method") !== "S256" || !/^[A-Za-z0-9_-]{43}$/.test(challenge)) {
    return "PKCE S256 obligatorio.";
  }
  return {
    client_id: clientId,
    redirect_uri: redirect,
    code_challenge: challenge,
    state: texto(campos.get("state"), 512),
  };
}

function formulario(peticion: PeticionAutorizacion, error = ""): Response {
  const ocultos = Object.entries({
    client_id: peticion.client_id,
    redirect_uri: peticion.redirect_uri,
    code_challenge: peticion.code_challenge,
    code_challenge_method: "S256",
    response_type: "code",
    state: peticion.state,
  }).map(([k, v]) => `<input type="hidden" name="${k}" value="${escapar(v)}">`).join("");
  return pagina(
    `<h1>Mesa SIGA-98</h1>
<p>ChatGPT pide acceso a la mesa de coordinación como <b>${AGENTE}</b>: leer y publicar avisos, latidos y buscar en la memoria común.</p>
${error ? `<p class="error">${escapar(error)}</p>` : ""}
<form method="post" action="/oauth/authorize">${ocultos}
<label>Clave de nivel 2<input type="password" name="clave" autocomplete="off" required></label>
<button type="submit">Autorizar</button></form>`,
    error ? 401 : 200,
  );
}

async function autorizar(request: Request, kv: Deno.Kv, ip: string): Promise<Response> {
  if (request.method === "GET") {
    const peticion = await leerAutorizacion(kv, new URL(request.url).searchParams);
    return typeof peticion === "string"
      ? pagina(`<p class="error">${escapar(peticion)}</p>`, 400)
      : formulario(peticion);
  }
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const bruto = await request.text();
  if (bruto.length > 4096) return pagina('<p class="error">Petición demasiado grande.</p>', 413);
  const campos = new URLSearchParams(bruto);
  const peticion = await leerAutorizacion(kv, campos);
  if (typeof peticion === "string") return pagina(`<p class="error">${escapar(peticion)}</p>`, 400);

  if (!await dentroDelLimite(kv, "fallo", ip, FALLOS_MAX)) {
    return pagina('<p class="error">Demasiados intentos. Espera un cuarto de hora.</p>', 429);
  }
  if (!await nivel2TokenMatches(campos.get("clave") ?? "")) {
    await contar(kv, "fallo", ip);
    return formulario(peticion, "Clave incorrecta.");
  }

  const codigo = aleatorio();
  const valor: Codigo = {
    client_id: peticion.client_id,
    redirect_uri: peticion.redirect_uri,
    code_challenge: peticion.code_challenge,
  };
  await kv.set(["agent_mcp", "codigo", await resumen(codigo)], valor, {
    expireIn: CODIGO_TTL_MS,
  });
  const destino = new URL(peticion.redirect_uri);
  destino.searchParams.set("code", codigo);
  if (peticion.state) destino.searchParams.set("state", peticion.state);
  return new Response(null, {
    status: 302,
    headers: { location: destino.toString(), "cache-control": "no-store" },
  });
}

// Lee y borra en la misma transacción: un código o un refresh valen una vez
// aunque lleguen dos peticiones a la vez.
async function consumir<T>(kv: Deno.Kv, clave: Deno.KvKey): Promise<T | null> {
  const entrada = await kv.get<T>(clave);
  if (!entrada.value) return null;
  const hecho = await kv.atomic().check(entrada).delete(clave).commit();
  return hecho.ok ? entrada.value : null;
}

async function emitir(kv: Deno.Kv, clientId: string): Promise<Response> {
  const acceso = aleatorio();
  const refresco = aleatorio();
  const concesion: Concesion = { client_id: clientId };
  await kv.atomic()
    .set(["agent_mcp", "acceso", await resumen(acceso)], concesion, { expireIn: ACCESO_TTL_MS })
    .set(["agent_mcp", "refresco", await resumen(refresco)], concesion, {
      expireIn: REFRESCO_TTL_MS,
    })
    .commit();
  return json({
    access_token: acceso,
    token_type: "Bearer",
    expires_in: ACCESO_TTL_MS / 1000,
    refresh_token: refresco,
    scope: SCOPE,
  });
}

async function token(request: Request, kv: Deno.Kv): Promise<Response> {
  if (request.method !== "POST") return json({ error: "invalid_request" }, 405);
  const bruto = await request.text();
  if (bruto.length > 4096) return json({ error: "invalid_request" }, 400);
  const tipo = request.headers.get("content-type") ?? "";
  let campos: URLSearchParams;
  try {
    campos = tipo.includes("application/json")
      ? new URLSearchParams(
        Object.entries(JSON.parse(bruto) as Record<string, unknown>)
          .map(([k, v]) => [k, String(v)]),
      )
      : new URLSearchParams(bruto);
  } catch {
    return json({ error: "invalid_request" }, 400);
  }
  const clientId = texto(campos.get("client_id"), 80);

  switch (campos.get("grant_type")) {
    case "authorization_code": {
      const codigo = texto(campos.get("code"), 128);
      const verificador = texto(campos.get("code_verifier"), 128);
      if (!codigo || !/^[A-Za-z0-9._~-]{43,128}$/.test(verificador)) {
        return json({ error: "invalid_request" }, 400);
      }
      const guardado = await consumir<Codigo>(kv, [
        "agent_mcp",
        "codigo",
        await resumen(codigo),
      ]);
      if (
        !guardado ||
        guardado.client_id !== clientId ||
        guardado.redirect_uri !== texto(campos.get("redirect_uri"), 512) ||
        await resumen(verificador) !== guardado.code_challenge
      ) {
        return json({ error: "invalid_grant" }, 400);
      }
      return await emitir(kv, clientId);
    }
    case "refresh_token": {
      const refresco = texto(campos.get("refresh_token"), 128);
      const guardado = refresco
        ? await consumir<Concesion>(kv, ["agent_mcp", "refresco", await resumen(refresco)])
        : null;
      if (!guardado || guardado.client_id !== clientId) {
        return json({ error: "invalid_grant" }, 400);
      }
      return await emitir(kv, clientId);
    }
    default:
      return json({ error: "unsupported_grant_type" }, 400);
  }
}

const HERRAMIENTAS = [
  {
    name: "avisos_activos",
    description:
      "Avisos vigentes de la mesa (main rojo, trabajo en curso, bloqueos). Consúltalo antes de empezar un corte.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
    annotations: { readOnlyHint: true },
  },
  {
    name: "avisar",
    description:
      "Publica un aviso para el resto de agentes. Firma como odiseo. Nunca incluyas tokens ni datos personales.",
    inputSchema: {
      type: "object",
      properties: {
        tipo: { type: "string", enum: ["main-rojo", "en-curso", "bloqueo", "aviso"] },
        texto: { type: "string", minLength: 10, maxLength: 600 },
        refs: { type: "array", items: { type: "integer" }, description: "Issues o PRs" },
        paths: { type: "array", items: { type: "string" }, description: "Rutas del repo" },
        ttl_horas: { type: "number", minimum: 1, maximum: 72 },
      },
      required: ["tipo", "texto"],
      additionalProperties: false,
    },
    annotations: { readOnlyHint: false, destructiveHint: false },
  },
  {
    name: "resolver_aviso",
    description: "Retira un aviso que ya no aplica (por ejemplo, main vuelve a estar verde).",
    inputSchema: {
      type: "object",
      properties: { id: { type: "string" } },
      required: ["id"],
      additionalProperties: false,
    },
    annotations: { readOnlyHint: false, destructiveHint: true },
  },
  {
    name: "latido",
    description: "Anuncia en qué está trabajando odiseo. Caduca a los 30 minutos sin renovar.",
    inputSchema: {
      type: "object",
      properties: {
        tarea: { type: "string", maxLength: 200 },
        issue: { type: "integer", minimum: 0 },
        rama: { type: "string", maxLength: 120 },
      },
      required: ["tarea"],
      additionalProperties: false,
    },
    annotations: { readOnlyHint: false, destructiveHint: false },
  },
  {
    name: "quien_esta",
    description: "Agentes con latido en la última media hora y en qué están.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
    annotations: { readOnlyHint: true },
  },
  {
    name: "buscar_memoria",
    description:
      "Busca lecciones y episodios en la memoria común de los agentes por texto, issue, rutas o etiquetas.",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string" },
        issue: { type: "integer", minimum: 0 },
        paths: { type: "array", items: { type: "string" } },
        tags: { type: "array", items: { type: "string" } },
      },
      additionalProperties: false,
    },
    annotations: { readOnlyHint: true },
  },
];

const IDENTIDAD = { level: "nivel2" } as const;

async function llamarHerramienta(
  kv: Deno.Kv,
  nombre: string,
  args: Record<string, unknown>,
): Promise<{ content: { type: "text"; text: string }[]; isError?: boolean }> {
  const ok = (dato: unknown) => ({
    content: [{ type: "text" as const, text: JSON.stringify(dato, null, 2) }],
  });
  const error = (mensaje: string) => ({
    content: [{ type: "text" as const, text: mensaje }],
    isError: true,
  });

  switch (nombre) {
    case "avisos_activos":
      return ok(await avisosActivos(kv));
    case "avisar": {
      const aviso = await avisar(kv, { ...args, agente: AGENTE }, IDENTIDAD);
      return aviso ? ok(aviso) : error(
        "Aviso rechazado: tipo debe ser main-rojo, en-curso, bloqueo o aviso; texto de 10 caracteres o más y sin nada con forma de secreto.",
      );
    }
    case "resolver_aviso":
      return await resolver(kv, args) ? ok({ resuelto: true }) : error("Aviso no encontrado.");
    case "latido": {
      const presencia = await latido(kv, { ...args, agente: AGENTE }, IDENTIDAD);
      return presencia ? ok(presencia) : error("Latido rechazado.");
    }
    case "quien_esta":
      return ok(await presentes(kv));
    case "buscar_memoria":
      return ok(await searchAgentMemory(kv, { ...args, schema: 1 }));
    default:
      return error("Herramienta desconocida: " + nombre);
  }
}

function rpcError(id: unknown, code: number, message: string, status = 200): Response {
  return json({ jsonrpc: "2.0", id: id ?? null, error: { code, message } }, status);
}

async function mcp(request: Request, kv: Deno.Kv, base: string): Promise<Response> {
  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405, { allow: "POST" });
  }

  const autorizacion = request.headers.get("authorization") ?? "";
  const portador = autorizacion.startsWith("Bearer ")
    ? autorizacion.slice("Bearer ".length).trim()
    : "";
  const concesion = portador
    ? await kv.get<Concesion>(["agent_mcp", "acceso", await resumen(portador)])
    : null;
  if (!concesion?.value) {
    const invalido = portador ? ', error="invalid_token"' : "";
    return json({ error: "unauthorized" }, 401, {
      "www-authenticate":
        `Bearer resource_metadata="${base}/.well-known/oauth-protected-resource"${invalido}`,
    });
  }

  const bruto = await request.text();
  if (bruto.length > MCP_MAX_BYTES) return rpcError(null, -32600, "petición demasiado grande");
  let mensaje: Record<string, unknown>;
  try {
    mensaje = JSON.parse(bruto);
  } catch {
    return rpcError(null, -32700, "JSON no válido");
  }
  if (!mensaje || typeof mensaje !== "object" || Array.isArray(mensaje)) {
    return rpcError(null, -32600, "se espera un único mensaje JSON-RPC");
  }

  const { id, method } = mensaje;
  // Notificaciones (sin id) y respuestas del cliente: se aceptan sin cuerpo.
  if (id === undefined || typeof method !== "string") return new Response(null, { status: 202 });
  const params = (mensaje.params && typeof mensaje.params === "object")
    ? mensaje.params as Record<string, unknown>
    : {};

  const responder = (result: unknown) => json({ jsonrpc: "2.0", id, result });
  switch (method) {
    case "initialize": {
      const pedido = String(params.protocolVersion ?? "");
      return responder({
        protocolVersion: PROTOCOLOS.includes(pedido) ? pedido : PROTOCOLOS[0],
        capabilities: { tools: { listChanged: false } },
        serverInfo: { name: "siga98-mesa", version: "1" },
        instructions:
          "Mesa de coordinación de los agentes de expediente-legado. Al empezar, mira avisos_activos y quien_esta; " +
          "las reservas de archivos siguen en el issue #1713.",
      });
    }
    case "ping":
      return responder({});
    case "tools/list":
      return responder({ tools: HERRAMIENTAS });
    case "tools/call": {
      const nombre = String(params.name ?? "");
      const args = (params.arguments && typeof params.arguments === "object")
        ? params.arguments as Record<string, unknown>
        : {};
      return responder(await llamarHerramienta(kv, nombre, args));
    }
    default:
      return rpcError(id, -32601, "método no soportado: " + method);
  }
}

export async function handleAgentMcp(
  request: Request,
  url: URL,
  kv: Deno.Kv,
  ip: string,
): Promise<Response> {
  const base = origen(url);
  switch (url.pathname) {
    case "/.well-known/oauth-protected-resource":
    case "/.well-known/oauth-protected-resource/mcp":
      return metadatosRecurso(base);
    case "/.well-known/oauth-authorization-server":
      return metadatosServidor(base);
    case "/oauth/register":
      return request.method === "POST"
        ? await registrar(request, kv, ip)
        : json({ error: "method_not_allowed" }, 405);
    case "/oauth/authorize":
      return await autorizar(request, kv, ip);
    case "/oauth/token":
      return await token(request, kv);
    default:
      return await mcp(request, kv, base);
  }
}
