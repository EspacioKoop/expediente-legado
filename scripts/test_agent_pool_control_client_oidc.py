import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
CLIENT_PATH = ROOT / "scripts" / "agent_pool_control_client.py"

spec = importlib.util.spec_from_file_location("agent_pool_control_client", CLIENT_PATH)
client = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(client)


class TestAgentPoolControlClientOIDC(unittest.TestCase):
    def test_oidc_url_sin_query(self):
        raw = "https://actions.githubusercontent.com/token"
        expected = "https://actions.githubusercontent.com/token?audience=siga98-agent-pool"
        self.assertEqual(client.oidc_url(raw), expected)

    def test_oidc_url_con_barra_final(self):
        raw = "https://actions.githubusercontent.com/token/"
        expected = "https://actions.githubusercontent.com/token/?audience=siga98-agent-pool"
        self.assertEqual(client.oidc_url(raw), expected)

    def test_oidc_url_con_query_existente(self):
        raw = "https://actions.githubusercontent.com/token?foo=bar"
        expected = "https://actions.githubusercontent.com/token?foo=bar&audience=siga98-agent-pool"
        self.assertEqual(client.oidc_url(raw), expected)

    def test_oidc_url_con_barra_final_y_query_existente(self):
        raw = "https://actions.githubusercontent.com/token/?foo=bar&baz=1"
        expected = "https://actions.githubusercontent.com/token/?foo=bar&baz=1&audience=siga98-agent-pool"
        self.assertEqual(client.oidc_url(raw), expected)

    def test_oidc_url_cadena_vacia(self):
        self.assertEqual(client.oidc_url(""), "?audience=siga98-agent-pool")

    def test_oidc_url_entrada_invalida(self):
        raw = "not-a-valid-url"
        expected = "not-a-valid-url?audience=siga98-agent-pool"
        self.assertEqual(client.oidc_url(raw), expected)

    def test_oidc_url_tipo_invalido_lanza_exception(self):
        with self.assertRaises(TypeError):
            client.oidc_url(None)  # type: ignore

        with self.assertRaises(TypeError):
            client.oidc_url(12345)  # type: ignore


if __name__ == "__main__":
    unittest.main()
