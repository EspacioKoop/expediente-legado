import importlib.util
import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CLIENT = ROOT / "scripts" / "agent_pool_control_client.py"

spec = importlib.util.spec_from_file_location("agent_pool_control_client", CLIENT)
client = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(client)


class _Response:
    def __init__(self, payload):
        self.payload = payload

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False

    def read(self):
        return json.dumps(self.payload).encode("utf-8")


class AgentPoolControlClientTest(unittest.TestCase):
    def test_normaliza_base_de_feedback(self):
        self.assertEqual(
            client.control_base("https://pool.test/api/report"),
            "https://pool.test",
        )
        self.assertEqual(client.control_base("https://pool.test/"), "https://pool.test")

    def test_oidc_usa_audiencia_separada(self):
        seen = []

        def opener(req, timeout):
            seen.append((req, timeout))
            return _Response({"value": "oidc-token"})

        token = client.oidc_token(
            {
                "ACTIONS_ID_TOKEN_REQUEST_TOKEN": "request-token",
                "ACTIONS_ID_TOKEN_REQUEST_URL": "https://actions.test/token?x=1",
            },
            opener=opener,
        )
        self.assertEqual(token, "oidc-token")
        req, timeout = seen[0]
        self.assertEqual(timeout, 12)
        self.assertIn("audience=siga98-agent-pool", req.full_url)
        self.assertEqual(req.get_header("Authorization"), "bearer request-token")

    def test_transition_no_expone_token_en_payload(self):
        seen = []

        def opener(req, timeout):
            seen.append((req, timeout))
            if "actions.test" in req.full_url:
                return _Response({"value": "oidc-secret"})
            return _Response({"ok": True})

        result = client.transition(
            "https://pool.test/api/report",
            1728,
            "lease-123",
            "validating",
            env={
                "ACTIONS_ID_TOKEN_REQUEST_TOKEN": "request-secret",
                "ACTIONS_ID_TOKEN_REQUEST_URL": "https://actions.test/token",
            },
            opener=opener,
        )
        self.assertEqual(result, {"ok": True})
        req, timeout = seen[-1]
        self.assertEqual(timeout, 12)
        self.assertEqual(req.full_url, "https://pool.test/api/agent-pool/transition")
        self.assertEqual(req.get_header("Authorization"), "Bearer oidc-secret")
        payload = json.loads(req.data.decode("utf-8"))
        self.assertEqual(
            payload,
            {
                "schema": 1,
                "issue": 1728,
                "lease_id": "lease-123",
                "state": "validating",
            },
        )
        self.assertNotIn("oidc-secret", req.data.decode("utf-8"))
        self.assertNotIn("request-secret", req.data.decode("utf-8"))


if __name__ == "__main__":
    unittest.main()
