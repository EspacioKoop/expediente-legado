"""Pruebas unitarias e integración para make_handler en agent_llm_proxy.py."""

from http.client import HTTPConnection
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import io
import json
import sys
import threading
import unittest
import urllib.error
import urllib.request

from scripts.agent_llm_proxy import make_handler


class FakeUpstreamHandler(BaseHTTPRequestHandler):
    requests_received = []

    def log_message(self, fmt, *args):
        return

    def do_GET(self):
        FakeUpstreamHandler.requests_received.append({
            "method": "GET",
            "path": self.path,
            "headers": dict(self.headers),
            "body": None,
        })
        if self.path == "/v1/error":
            self.send_response(500)
            self.send_header("Content-Type", "application/json")
            body = b'{"error": "internal_error"}'
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        body = b'{"status": "ok"}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length) if length > 0 else b""
        body_json = None
        if raw:
            try:
                body_json = json.loads(raw.decode("utf-8"))
            except Exception:
                body_json = raw

        FakeUpstreamHandler.requests_received.append({
            "method": "POST",
            "path": self.path,
            "headers": dict(self.headers),
            "body": body_json,
            "raw_body": raw,
        })

        if self.path == "/v1/error_422":
            self.send_response(422)
            self.send_header("Content-Type", "application/json")
            err_payload = b'{"detail":[{"loc":["body","stream_options"],"msg":"extra_forbidden"}]}'
            self.send_header("Content-Length", str(len(err_payload)))
            self.end_headers()
            self.wfile.write(err_payload)
            return

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        resp_data = b'{"choices": [{"message": {"role": "assistant", "content": "hola"}}]}'
        self.send_header("Content-Length", str(len(resp_data)))
        self.end_headers()
        self.wfile.write(resp_data)


class TestAgentLLMProxyHandler(unittest.TestCase):
    def setUp(self):
        FakeUpstreamHandler.requests_received = []
        self.upstream_server = ThreadingHTTPServer(("127.0.0.1", 0), FakeUpstreamHandler)
        self.upstream_server.daemon_threads = True
        self.upstream_thread = threading.Thread(target=self.upstream_server.serve_forever, daemon=True)
        self.upstream_thread.start()

        self.upstream_port = self.upstream_server.server_port
        self.upstream_url = f"http://127.0.0.1:{self.upstream_port}/v1"

        self.log_stream = io.StringIO()
        handler_cls = make_handler(self.upstream_url, "mistral", self.log_stream)

        self.proxy_server = ThreadingHTTPServer(("127.0.0.1", 0), handler_cls)
        self.proxy_server.daemon_threads = True
        self.proxy_thread = threading.Thread(target=self.proxy_server.serve_forever, daemon=True)
        self.proxy_thread.start()

        self.proxy_port = self.proxy_server.server_port
        self.proxy_base = f"http://127.0.0.1:{self.proxy_port}"

    def tearDown(self):
        self.proxy_server.shutdown()
        self.proxy_server.server_close()
        self.upstream_server.shutdown()
        self.upstream_server.server_close()

    def test_post_mistral_filters_unsupported_fields_and_forwards_to_upstream(self):
        peticion = {
            "model": "mistral-small-latest",
            "stream": True,
            "stream_options": {"include_usage": True},
            "max_completion_tokens": 4096,
            "seed": 42,
            "metadata": {"user_id": "test"},
            "messages": [
                {"role": "user", "content": "hola", "extra_user_field": 123},
                {
                    "role": "assistant",
                    "content": None,
                    "reasoning_content": "pensando...",
                    "tool_calls": [
                        {
                            "index": 0,
                            "id": "call_1234567890abcdef",
                            "type": "function",
                            "function": {"name": "test_func", "arguments": "{}"},
                        }
                    ],
                },
            ],
        }

        req = urllib.request.Request(
            f"{self.proxy_base}/v1/chat/completions",
            data=json.dumps(peticion).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "Authorization": "Bearer secreto-token-123",
            },
            method="POST",
        )

        with urllib.request.urlopen(req, timeout=5) as resp:
            self.assertEqual(200, resp.status)
            res_data = json.loads(resp.read().decode("utf-8"))
            self.assertIn("choices", res_data)

        self.assertEqual(1, len(FakeUpstreamHandler.requests_received))
        recibido = FakeUpstreamHandler.requests_received[0]
        self.assertEqual("POST", recibido["method"])
        self.assertEqual("/v1/chat/completions", recibido["path"])
        self.assertEqual("Bearer secreto-token-123", recibido["headers"].get("Authorization"))

        body = recibido["body"]
        self.assertNotIn("stream_options", body)
        self.assertNotIn("metadata", body)
        self.assertNotIn("max_completion_tokens", body)
        self.assertEqual(4096, body.get("max_tokens"))
        self.assertEqual(42, body.get("random_seed"))

        user_msg, assistant_msg = body["messages"]
        self.assertNotIn("extra_user_field", user_msg)
        self.assertEqual("", assistant_msg["content"])
        self.assertNotIn("reasoning_content", assistant_msg)

        tool_call = assistant_msg["tool_calls"][0]
        self.assertNotIn("index", tool_call)
        self.assertEqual(9, len(tool_call["id"]))

        logs = self.log_stream.getvalue()
        self.assertIn("[mistral]", logs)
        self.assertIn("descartado:", logs)
        self.assertNotIn("secreto-token-123", logs)

    def test_health_endpoint_returns_ok_without_forwarding(self):
        with urllib.request.urlopen(f"{self.proxy_base}/__health", timeout=5) as resp:
            self.assertEqual(200, resp.status)
            body = json.loads(resp.read().decode("utf-8"))
            self.assertEqual({"ok": True}, body)

        self.assertEqual(0, len(FakeUpstreamHandler.requests_received))

    def test_get_forwarding_passes_through_to_upstream(self):
        with urllib.request.urlopen(f"{self.proxy_base}/v1/models", timeout=5) as resp:
            self.assertEqual(200, resp.status)
            body = json.loads(resp.read().decode("utf-8"))
            self.assertEqual({"status": "ok"}, body)

        self.assertEqual(1, len(FakeUpstreamHandler.requests_received))
        recibido = FakeUpstreamHandler.requests_received[0]
        self.assertEqual("GET", recibido["method"])
        self.assertEqual("/v1/models", recibido["path"])

    def test_invalid_content_length_returns_400(self):
        conn = HTTPConnection("127.0.0.1", self.proxy_port, timeout=5)
        try:
            conn.putrequest("POST", "/v1/chat/completions")
            conn.putheader("Content-Type", "application/json")
            conn.putheader("Content-Length", "abc")
            conn.endheaders()
            resp = conn.getresponse()
            self.assertEqual(400, resp.status)
            body = json.loads(resp.read().decode("utf-8"))
            self.assertEqual("Content-Length invalido", body["error"]["message"])
        finally:
            conn.close()

        self.assertEqual(0, len(FakeUpstreamHandler.requests_received))

    def test_invalid_utf8_json_returns_400(self):
        conn = HTTPConnection("127.0.0.1", self.proxy_port, timeout=5)
        try:
            raw_bad = b"\x80\x81\x82"
            conn.putrequest("POST", "/v1/chat/completions")
            conn.putheader("Content-Type", "application/json")
            conn.putheader("Content-Length", str(len(raw_bad)))
            conn.endheaders(raw_bad)
            resp = conn.getresponse()
            self.assertEqual(400, resp.status)
            body = json.loads(resp.read().decode("utf-8"))
            self.assertEqual("Cuerpo JSON no es UTF-8 valido", body["error"]["message"])
        finally:
            conn.close()

        self.assertEqual(0, len(FakeUpstreamHandler.requests_received))

    def test_upstream_http_error_forwarding_and_logging(self):
        peticion = {"model": "test", "messages": []}
        req = urllib.request.Request(
            f"{self.proxy_base}/v1/error_422",
            data=json.dumps(peticion).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        with self.assertRaises(urllib.error.HTTPError) as ctx:
            urllib.request.urlopen(req, timeout=5)

        self.assertEqual(422, ctx.exception.code)
        err_body = ctx.exception.read().decode("utf-8")
        self.assertIn("extra_forbidden", err_body)

        logs = self.log_stream.getvalue()
        self.assertIn("[mistral]", logs)
        self.assertIn("422", logs)
        self.assertIn("extra_forbidden", logs)

    def test_upstream_connection_error_returns_502(self):
        log_stream = io.StringIO()
        # Upstream URL pointing to an unopened port
        dead_handler_cls = make_handler("http://127.0.0.1:1/v1", "mistral", log_stream)
        dead_proxy = ThreadingHTTPServer(("127.0.0.1", 0), dead_handler_cls)
        dead_proxy.daemon_threads = True
        threading.Thread(target=dead_proxy.serve_forever, daemon=True).start()

        try:
            req = urllib.request.Request(
                f"http://127.0.0.1:{dead_proxy.server_port}/v1/chat/completions",
                data=b"{}",
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with self.assertRaises(urllib.error.HTTPError) as ctx:
                urllib.request.urlopen(req, timeout=5)

            self.assertEqual(502, ctx.exception.code)
            body = json.loads(ctx.exception.read().decode("utf-8"))
            self.assertIn("proxy:", body["error"]["message"])

            logs = log_stream.getvalue()
            self.assertIn("sin respuesta", logs)
        finally:
            dead_proxy.shutdown()
            dead_proxy.server_close()


class TestAgentLLMProxyHandlerGroq(unittest.TestCase):
    def setUp(self):
        FakeUpstreamHandler.requests_received = []
        self.upstream_server = ThreadingHTTPServer(("127.0.0.1", 0), FakeUpstreamHandler)
        self.upstream_server.daemon_threads = True
        threading.Thread(target=self.upstream_server.serve_forever, daemon=True).start()

        self.upstream_port = self.upstream_server.server_port
        self.upstream_url = f"http://127.0.0.1:{self.upstream_port}/v1"

        self.log_stream = io.StringIO()
        handler_cls = make_handler(self.upstream_url, "groq", self.log_stream)

        self.proxy_server = ThreadingHTTPServer(("127.0.0.1", 0), handler_cls)
        self.proxy_server.daemon_threads = True
        threading.Thread(target=self.proxy_server.serve_forever, daemon=True).start()

        self.proxy_port = self.proxy_server.server_port
        self.proxy_base = f"http://127.0.0.1:{self.proxy_port}"

    def tearDown(self):
        self.proxy_server.shutdown()
        self.proxy_server.server_close()
        self.upstream_server.shutdown()
        self.upstream_server.server_close()

    def test_groq_caps_max_tokens(self):
        peticion = {"model": "qwen3.8-27b", "max_tokens": 30000, "messages": []}
        req = urllib.request.Request(
            f"{self.proxy_base}/v1/chat/completions",
            data=json.dumps(peticion).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        with urllib.request.urlopen(req, timeout=5) as resp:
            self.assertEqual(200, resp.status)

        self.assertEqual(1, len(FakeUpstreamHandler.requests_received))
        recibido = FakeUpstreamHandler.requests_received[0]
        body = recibido["body"]
        self.assertEqual(16384, body.get("max_tokens"))

        logs = self.log_stream.getvalue()
        self.assertIn("[groq]", logs)
        self.assertIn("body.max_tokens>16384", logs)


if __name__ == "__main__":
    unittest.main()
