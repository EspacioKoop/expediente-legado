from __future__ import annotations

import io
import json
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch
from urllib.error import HTTPError

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

import agent_b2b_mailbox as mailbox


class FakeResponse(io.BytesIO):
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        self.close()
        return False


class AgentB2BMailbox1870Test(unittest.TestCase):
    def test_error_http_no_expone_texto_arbitrario_del_servidor(self):
        for valor in (
            "Authorization: Bearer abcdefghijklmnop",
            "fallo\n::error::mensaje inyectado",
            "https://example.invalid/private?token=valor",
            "x" * 81,
            "ghp_" + "x" * 36,
            "private_credential_value",
        ):
            with self.subTest(error=valor):
                response = HTTPError(
                    "https://example.invalid", 503, "Unavailable", {},
                    io.BytesIO(json.dumps({"error": valor}).encode()),
                )
                with patch.object(mailbox, "urlopen", side_effect=response):
                    with self.assertRaises(mailbox.MailboxError) as caught:
                        mailbox.post_json(
                            base_url="https://example.invalid", endpoint="/inbox",
                            payload={}, oidc_token="a.b.c",
                        )
                self.assertEqual("mailbox HTTP 503: http_error", str(caught.exception))

    def test_error_http_conserva_codigo_del_protocolo(self):
        response = HTTPError(
            "https://example.invalid", 403, "Forbidden", {},
            io.BytesIO(b'{"error":"invalid_request"}'),
        )
        with patch.object(mailbox, "urlopen", side_effect=response):
            with self.assertRaisesRegex(mailbox.MailboxError, "HTTP 403: invalid_request"):
                mailbox.post_json(
                    base_url="https://example.invalid", endpoint="/inbox",
                    payload={}, oidc_token="a.b.c",
                )

    def test_cli_mailbox_caido_sale_controlado_sin_volcar_respuesta(self):
        response = HTTPError(
            "https://example.invalid", 503, "Unavailable", {},
            io.BytesIO(b'{"error":"Authorization: Bearer abcdefghijklmnop"}'),
        )
        argv = [
            "agent_b2b_mailbox", "--control-url", "https://example.invalid",
            "--oidc-token", "a.b.c", "inbox", "--recipient", "reviewer",
            "--task-id", "task-1",
        ]
        stderr, stdout = io.StringIO(), io.StringIO()
        with (
            patch.object(sys, "argv", argv),
            patch.object(sys, "stderr", stderr),
            patch.object(sys, "stdout", stdout),
            patch.object(mailbox, "urlopen", side_effect=response),
        ):
            self.assertEqual(2, mailbox.main())
        self.assertEqual("", stdout.getvalue())
        self.assertEqual("agent_b2b_mailbox: mailbox HTTP 503: http_error\n", stderr.getvalue())

    def test_control_url_deriva_desde_report_y_exige_https(self):
        self.assertEqual(
            mailbox.control_base_url("https://example.invalid/api/report"),
            "https://example.invalid",
        )
        self.assertEqual(
            mailbox.control_base_url("https://example.invalid/base/"),
            "https://example.invalid/base",
        )
        for invalid in (
            "http://example.invalid/api/report",
            "https://example.invalid/api/report?x=1",
            "not-a-url",
        ):
            with self.assertRaises(ValueError):
                mailbox.control_base_url(invalid)

    def test_send_normaliza_blocker_e_idempotencia(self):
        payload = mailbox.build_send_payload(
            task_id="EspacioKoop/expediente-legado#1870@abc123",
            message_type="blocker",
            recipient="dispatcher",
            idempotency_key="run-7:blocker-1",
            subject="Falta una dependencia",
            evidence=["CI #123"],
        )
        self.assertEqual(payload["schema"], 1)
        self.assertEqual(payload["message_type"], "BLOCKER")
        self.assertTrue(payload["blocking"])
        self.assertEqual(payload["idempotency_key"], "run-7:blocker-1")

    def test_send_rechaza_vacio_token_invalido_y_secreto(self):
        with self.assertRaises(ValueError):
            mailbox.build_send_payload(
                task_id="task 1",
                message_type="QUESTION",
                recipient="worker",
                idempotency_key="idem",
                body="hola",
            )
        with self.assertRaises(ValueError):
            mailbox.build_send_payload(
                task_id="task-1",
                message_type="QUESTION",
                recipient="worker",
                idempotency_key="idem",
            )
        with self.assertRaises(ValueError):
            mailbox.build_send_payload(
                task_id="task-1",
                message_type="QUESTION",
                recipient="worker",
                idempotency_key="idem",
                body="Authorization: Bearer abcdefghijklmnop",
            )

    def test_inbox_exige_task_para_worker_y_acota_limit(self):
        with self.assertRaises(ValueError):
            mailbox.build_inbox_payload(recipient="worker")
        payload = mailbox.build_inbox_payload(recipient="worker", task_id="task-1", limit=999)
        self.assertEqual(payload["limit"], 50)
        dispatcher = mailbox.build_inbox_payload(recipient="dispatcher", limit=0)
        self.assertEqual(dispatcher["task_id"], "")
        self.assertEqual(dispatcher["limit"], 1)

    def test_ack_valida_identificadores(self):
        payload = mailbox.build_ack_payload(
            recipient="reviewer", task_id="task-1", message_id="message-1"
        )
        self.assertEqual(payload["message_id"], "message-1")
        with self.assertRaises(ValueError):
            mailbox.build_ack_payload(recipient="reviewer", task_id="", message_id="message-1")

    def test_oidc_url_fija_audiencia(self):
        result = mailbox.oidc_request_url("https://token.actions.example/id?foo=bar")
        self.assertIn("foo=bar", result)
        self.assertIn("audience=siga98-agent-pool", result)

    def test_request_oidc_usa_header_efimero(self):
        captured = {}

        def fake_urlopen(request, timeout):
            captured["url"] = request.full_url
            captured["auth"] = request.get_header("Authorization")
            captured["timeout"] = timeout
            return FakeResponse(json.dumps({"value": "a.b.c"}).encode())

        env = {
            "ACTIONS_ID_TOKEN_REQUEST_URL": "https://token.actions.example/id",
            "ACTIONS_ID_TOKEN_REQUEST_TOKEN": "ephemeral-request-token",
        }
        with patch.dict(os.environ, env, clear=False), patch.object(mailbox, "urlopen", fake_urlopen):
            token = mailbox.request_oidc_token(timeout=7)
        self.assertEqual(token, "a.b.c")
        self.assertEqual(captured["auth"], "bearer ephemeral-request-token")
        self.assertIn("audience=siga98-agent-pool", captured["url"])
        self.assertEqual(captured["timeout"], 7)

    def test_post_json_envia_bearer_sin_meterlo_en_payload(self):
        captured = {}

        def fake_urlopen(request, timeout):
            captured["url"] = request.full_url
            captured["auth"] = request.get_header("Authorization")
            captured["body"] = request.data.decode()
            return FakeResponse(b'{"ok":true}')

        with patch.object(mailbox, "urlopen", fake_urlopen):
            result = mailbox.post_json(
                base_url="https://example.invalid/api/report",
                endpoint="/api/agent-pool/b2b/inbox",
                payload={"schema": 1, "recipient": "dispatcher", "task_id": "", "limit": 1},
                oidc_token="a.b.c",
            )
        self.assertEqual(result, {"ok": True})
        self.assertEqual(captured["auth"], "Bearer a.b.c")
        self.assertNotIn("a.b.c", captured["body"])
        self.assertTrue(captured["url"].endswith("/api/agent-pool/b2b/inbox"))


if __name__ == "__main__":
    unittest.main()
