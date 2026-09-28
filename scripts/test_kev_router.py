import json
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import kev_router  # noqa: E402


class _FakeResponse:
    def __init__(self, payload):
        self.payload = payload

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def read(self):
        return json.dumps(self.payload).encode("utf-8")


class KevRouterTest(unittest.TestCase):
    def test_fallback_conserva_prioridad_actual_sin_kev(self):
        result = kev_router.route_provider(
            state={"title": "Arreglar test"},
            has_qwen=True,
            has_gemini=True,
            base_url=None,
        )
        self.assertEqual("qwen", result["provider"])
        self.assertEqual("fallback:no-kev", result["source"])

    def test_proveedor_explicito_no_consulta_kev(self):
        def fail_requester(**kwargs):
            raise AssertionError(f"no debería invocarse Kev: {kwargs}")

        result = kev_router.route_provider(
            state={"title": "Issue"},
            requested_provider="gemini",
            has_qwen=True,
            has_gemini=True,
            base_url="http://kev.invalid",
            requester=fail_requester,
        )
        self.assertEqual("gemini", result["provider"])
        self.assertEqual("explicit", result["source"])

    def test_label_explicita_manda(self):
        result = kev_router.route_provider(
            state={"title": "Issue"},
            labels=["bug", "agent:gemini"],
            has_qwen=True,
            has_gemini=True,
            base_url="http://kev.invalid",
        )
        self.assertEqual("gemini", result["provider"])
        self.assertEqual("explicit", result["source"])

    def test_labels_explicitas_en_conflicto_no_eligen_proveedor_ni_consultan_kev(self):
        def fail_requester(**kwargs):
            raise AssertionError(f"no debería invocarse Kev: {kwargs}")

        result = kev_router.route_provider(
            state={"title": "Issue ambiguo"},
            labels=["agent:qwen", "bug", "agent:gemini"],
            has_qwen=True,
            has_gemini=True,
            base_url="http://kev.invalid",
            requester=fail_requester,
        )
        self.assertIsNone(result["provider"])
        self.assertEqual("explicit-conflict", result["source"])
        self.assertEqual("multiple-explicit-provider-labels", result["reason"])
        self.assertEqual(["gemini", "qwen"], result["conflicting_providers"])
        self.assertEqual(["qwen", "gemini"], result["available"])

    def test_conflicto_de_labels_prevalece_sobre_proveedor_manual(self):
        def fail_requester(**kwargs):
            raise AssertionError(f"no debería invocarse Kev: {kwargs}")

        result = kev_router.route_provider(
            state={"title": "Issue ambiguo"},
            labels=["agent:qwen", "agent:gemini"],
            requested_provider="qwen",
            has_qwen=True,
            has_gemini=True,
            base_url="http://kev.invalid",
            requester=fail_requester,
        )
        self.assertIsNone(result["provider"])
        self.assertEqual("explicit-conflict", result["source"])

    def test_proveedor_explicito_ausente_no_se_sustituye(self):
        result = kev_router.route_provider(
            state={"title": "Issue"},
            labels=["agent:gemini"],
            has_qwen=True,
            has_gemini=False,
            base_url="http://kev.invalid",
        )
        self.assertIsNone(result["provider"])
        self.assertEqual("gemini", result["requested_provider"])
        self.assertEqual("explicit-unavailable", result["source"])

    def test_unico_proveedor_disponible_no_necesita_kev(self):
        result = kev_router.route_provider(
            state={"title": "Issue"},
            has_qwen=False,
            has_gemini=True,
            base_url="http://kev.invalid",
        )
        self.assertEqual("gemini", result["provider"])
        self.assertEqual("single-provider", result["source"])

    def test_kev_decide_con_confianza_suficiente(self):
        captured = {}

        def requester(**kwargs):
            captured.update(kwargs)
            return {
                "answers": {
                    "provider": {
                        "type": "choice",
                        "choice": "gemini",
                        "confidence": 0.72,
                        "probabilities": {"qwen": 0.39, "gemini": 0.61},
                    }
                }
            }

        result = kev_router.route_provider(
            state={"title": "Actualizar documentación", "body": "Cambio pequeño"},
            has_qwen=True,
            has_gemini=True,
            base_url="http://127.0.0.1:8009",
            requester=requester,
        )
        self.assertEqual("gemini", result["provider"])
        self.assertEqual("kev", result["source"])
        self.assertEqual(0.72, result["confidence"])
        self.assertEqual(
            {"qwen", "gemini"},
            set(captured["questions"]["provider"]["criteria"]),
        )

    def test_confianza_baja_vuelve_al_fallback(self):
        def requester(**kwargs):
            return {
                "answers": {
                    "provider": {
                        "type": "choice",
                        "choice": "gemini",
                        "confidence": 0.20,
                    }
                }
            }

        result = kev_router.route_provider(
            state={"title": "Issue"},
            has_qwen=True,
            has_gemini=True,
            base_url="http://kev",
            min_confidence=0.45,
            requester=requester,
        )
        self.assertEqual("qwen", result["provider"])
        self.assertEqual("fallback:low-confidence", result["source"])
        self.assertEqual("gemini", result["kev_choice"])

    def test_error_o_respuesta_invalida_no_bloquea(self):
        def requester(**kwargs):
            return {"answers": {"provider": {"choice": "otro", "confidence": 0.9}}}

        result = kev_router.route_provider(
            state={"title": "Issue"},
            has_qwen=True,
            has_gemini=True,
            base_url="http://kev",
            requester=requester,
        )
        self.assertEqual("qwen", result["provider"])
        self.assertEqual("fallback:error", result["source"])
        self.assertEqual("KevProtocolError", result["error_type"])

    def test_cliente_http_usa_system_one_y_bearer(self):
        captured = {}

        def fake_urlopen(req, timeout):
            captured["url"] = req.full_url
            captured["authorization"] = req.get_header("Authorization")
            captured["timeout"] = timeout
            captured["body"] = json.loads(req.data.decode("utf-8"))
            return _FakeResponse({"answers": {}})

        response = kev_router.call_system_one(
            base_url="http://127.0.0.1:8009/",
            api_key="secreto-prueba",
            model="kev-latest",
            state={"title": "Issue"},
            questions={"provider": {"type": "choice", "criteria": {"qwen": None}}},
            timeout=3.0,
            urlopen=fake_urlopen,
        )
        self.assertEqual({"answers": {}}, response)
        self.assertEqual("http://127.0.0.1:8009/v1/systemone", captured["url"])
        self.assertEqual("Bearer secreto-prueba", captured["authorization"])
        self.assertEqual(3.0, captured["timeout"])
        self.assertEqual("kev-latest", captured["body"]["model"])

    def test_estado_se_acota(self):
        long_text = "x" * 20000
        captured = {}

        def requester(**kwargs):
            captured["state"] = kwargs["state"]
            return {
                "answers": {
                    "provider": {
                        "choice": "qwen",
                        "confidence": 0.8,
                    }
                }
            }

        kev_router.route_provider(
            state={"body": long_text},
            has_qwen=True,
            has_gemini=True,
            base_url="http://kev",
            requester=requester,
        )
        self.assertEqual(12000, len(captured["state"]["body"]))


if __name__ == "__main__":
    unittest.main()
