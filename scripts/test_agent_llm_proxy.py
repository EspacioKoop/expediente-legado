import importlib.util
import io
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import sys
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_llm_proxy.py"
SPEC = importlib.util.spec_from_file_location("agent_llm_proxy", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)
SMOKE = ROOT / ".github" / "workflows" / "agent-provider-smoke.yml"

# Petición típica del CLI de Qwen (dialecto OpenAI), con campos que Mistral rechaza.
PETICION_QWEN = {
    "model": "mistral-small-latest",
    "stream": True,
    "stream_options": {"include_usage": True},
    "max_completion_tokens": 32000,
    "seed": 7,
    "metadata": {"x": 1},
    "messages": [
        {"role": "system", "content": [{"type": "text", "text": "sys", "cache_control": {"type": "ephemeral"}}]},
        {"role": "user", "content": "hola", "id": "m1"},
        {
            "role": "assistant",
            "content": None,
            "reasoning_content": "pienso",
            "tool_calls": [
                {"index": 0, "id": "call_abcdefghijklmnop", "type": "function",
                 "function": {"name": "read_file", "arguments": "{}"}}
            ],
        },
        {"role": "tool", "tool_call_id": "call_abcdefghijklmnop", "content": "ok"},
    ],
    "tools": [
        {"type": "function", "function": {"name": "read_file", "description": "d",
                                          "parameters": {"type": "object"}, "strict": True}}
    ],
}


class PerfilesTest(unittest.TestCase):
    def test_detecta_perfil_por_host(self):
        self.assertEqual("mistral", mod.detect_profile("https://api.mistral.ai/v1"))
        self.assertEqual("groq", mod.detect_profile("https://api.groq.com/openai/v1"))
        self.assertEqual("passthrough", mod.detect_profile("https://ollama.com/v1"))
        self.assertEqual("passthrough", mod.detect_profile("https://api.mistral.ai.evil.example/v1"))

    def test_mistral_solo_recibe_campos_admitidos(self):
        body, dropped = mod.adapt("mistral", PETICION_QWEN)
        self.assertLessEqual(set(body), mod.MISTRAL_TOP)
        self.assertEqual(32000, body["max_tokens"])
        self.assertEqual(7, body["random_seed"])
        self.assertNotIn("stream_options", body)
        self.assertIn("body.stream_options", dropped)
        self.assertNotIn("body.max_completion_tokens", dropped)
        sistema, usuario, asistente, herramienta = body["messages"]
        self.assertEqual([{"type": "text", "text": "sys"}], sistema["content"])
        self.assertNotIn("id", usuario)
        self.assertEqual("", asistente["content"])
        self.assertNotIn("reasoning_content", asistente)
        llamada = asistente["tool_calls"][0]
        self.assertNotIn("index", llamada)
        self.assertRegex(llamada["id"], r"^[A-Za-z0-9]{9}$")
        # La respuesta de la herramienta sigue casando con su llamada.
        self.assertEqual(llamada["id"], herramienta["tool_call_id"])
        self.assertNotIn("strict", body["tools"][0]["function"])

    def test_mistral_completa_parameters_de_herramientas_sin_argumentos(self):
        peticion = {"model": "m", "messages": [], "tools": [
            {"type": "function", "function": {"name": "todo_read", "description": "d"}}
        ]}
        body, _ = mod.adapt("mistral", peticion)
        self.assertEqual({"type": "object", "properties": {}}, body["tools"][0]["function"]["parameters"])

    def test_mistral_respeta_ids_ya_validos(self):
        self.assertEqual("abcDEF123", mod._mistral_id("abcDEF123"))

    def test_groq_recorta_max_tokens(self):
        body, dropped = mod.adapt("groq", {"model": "m", "max_tokens": 32000, "messages": []})
        self.assertEqual(mod.GROQ_MAX_TOKENS, body["max_tokens"])
        self.assertTrue(dropped)
        body, dropped = mod.adapt("groq", {"model": "m", "max_tokens": 100, "messages": []})
        self.assertEqual(100, body["max_tokens"])
        self.assertFalse(dropped)

    def test_resumen_de_error_de_mistral_sin_valores_ni_ruido(self):
        cuerpo = json.dumps({"detail": [
            {"type": "literal_error", "loc": ["body", "tools", "list[union[WebSearchTool,Tool]]", 1, "WebSearchTool", "type"],
             "msg": "Input should be web_search", "input": "function"},
            {"type": "string_pattern_mismatch", "loc": ["body", "tools", "list[union[WebSearchTool,Tool]]", 1, "Tool", "function", "name"],
             "msg": "String should match pattern", "input": "secreto del prompt"},
        ]}).encode()
        resumen = mod.resumen_error(cuerpo)
        self.assertIn("Tool.function.name: String should match pattern", resumen)
        self.assertNotIn("WebSearchTool.type", resumen)
        self.assertNotIn("secreto del prompt", resumen)

    def test_url_del_proveedor_sustituye_v1_local(self):
        self.assertEqual(
            "https://api.groq.com/openai/v1/chat/completions",
            mod.upstream_url("https://api.groq.com/openai/v1/", "/v1/chat/completions"),
        )


class ProveedorFalso(BaseHTTPRequestHandler):
    recibido: list = []

    def log_message(self, *args):
        return

    def do_POST(self):
        cuerpo = self.rfile.read(int(self.headers["Content-Length"]))
        ProveedorFalso.recibido.append(
            {"path": self.path, "auth": self.headers.get("Authorization"), "body": json.loads(cuerpo)}
        )
        if json.loads(cuerpo).get("model") == "falla":
            datos = b'{"detail":[{"type":"extra_forbidden","loc":["body","foo"]}]}'
            self.send_response(422)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(datos)))
            self.end_headers()
            self.wfile.write(datos)
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.end_headers()
        for trozo in (b'data: {"a":1}\n\n', b'data: {"a":2}\n\n', b"data: [DONE]\n\n"):
            self.wfile.write(trozo)
            self.wfile.flush()


class ProxyIntegracionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.proveedor = ThreadingHTTPServer(("127.0.0.1", 0), ProveedorFalso)
        threading.Thread(target=cls.proveedor.serve_forever, daemon=True).start()
        cls.log = io.StringIO()
        upstream = f"http://127.0.0.1:{cls.proveedor.server_port}/v1"
        cls.proxy = mod.serve(upstream, "mistral", 0, log=cls.log)
        threading.Thread(target=cls.proxy.serve_forever, daemon=True).start()
        cls.base = f"http://127.0.0.1:{cls.proxy.server_port}"

    @classmethod
    def tearDownClass(cls):
        cls.proxy.shutdown()
        cls.proveedor.shutdown()

    def _post(self, body):
        request = urllib.request.Request(
            self.base + "/v1/chat/completions",
            data=json.dumps(body).encode(),
            headers={"Authorization": "Bearer clave-de-prueba", "Content-Type": "application/json"},
            method="POST",
        )
        return urllib.request.urlopen(request, timeout=10)

    def test_health(self):
        with urllib.request.urlopen(self.base + mod.HEALTH_PATH, timeout=5) as r:
            self.assertEqual(200, r.status)

    def test_reenvia_adaptado_con_la_misma_clave_y_en_streaming(self):
        ProveedorFalso.recibido.clear()
        with self._post(PETICION_QWEN) as respuesta:
            self.assertEqual("text/event-stream", respuesta.headers["Content-Type"])
            datos = respuesta.read()
        self.assertIn(b"data: [DONE]", datos)
        recibido = ProveedorFalso.recibido[-1]
        self.assertEqual("/v1/chat/completions", recibido["path"])
        self.assertEqual("Bearer clave-de-prueba", recibido["auth"])
        self.assertNotIn("stream_options", recibido["body"])
        # La clave nunca llega al log.
        self.assertNotIn("clave-de-prueba", self.log.getvalue())

    def test_error_del_proveedor_llega_al_cli_y_al_log(self):
        with self.assertRaises(urllib.error.HTTPError) as ctx:
            self._post({"model": "falla", "messages": []})
        self.assertEqual(422, ctx.exception.code)
        self.assertIn(b"extra_forbidden", ctx.exception.read())
        self.assertIn("extra_forbidden", self.log.getvalue())


class CableadoSmokeTest(unittest.TestCase):
    def test_smoke_arranca_proxy_segun_perfil_y_vuelca_log(self):
        texto = SMOKE.read_text(encoding="utf-8")
        self.assertIn("scripts/agent_llm_proxy.py detect", texto)
        self.assertIn("scripts/agent_llm_proxy.py serve", texto)
        self.assertIn("openai_base_url: ${{ steps.proxy.outputs.url || steps.config.outputs.url }}", texto)
        self.assertIn("/tmp/agent-llm-proxy.log", texto)


if __name__ == "__main__":
    unittest.main()
