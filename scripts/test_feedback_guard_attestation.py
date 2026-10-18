"""Regression for deployed F9 publication guard attestation, without network."""
from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]


def load(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


cf = load(ROOT / "scripts/check_feedback_worker_production.py", "f9_cf_health")
deno = load(ROOT / "scripts/check_deno_production.py", "f9_deno_health")


class GuardAttestationTest(unittest.TestCase):
    def test_cf_source_has_versioned_guard(self):
        source = (ROOT / "infra/feedback-worker/worker.js").read_text(encoding="utf-8")
        contract = cf.expected_contract(source)
        self.assertEqual(contract["publication_guard"], 1)
        self.assertEqual(contract["version"], 2)
        healthy = {
            "ok": True, "service": "siga98-feedback", "github_configured": True,
            **contract,
        }
        self.assertEqual(cf.validate_health(source, healthy), [])
        for key, bad in (
            ("publication_guard", None),
            ("publication_guard", 0),
            ("publication_guard", True),
            ("github_configured", False),
        ):
            with self.subTest(key=key, bad=bad):
                data = {**healthy, key: bad}
                self.assertTrue(cf.validate_health(source, data))

    def test_deno_guard_attested_on_production_health(self):
        source = (ROOT / "infra/feedback-deno/main.ts").read_text(encoding="utf-8")
        contract = deno.expected_contract(source)
        self.assertEqual(contract["publication_guard"], 1)
        health = {
            "ok": True, "service": "siga98-feedback-deno",
            "version": contract["version"], "kv_configured": True,
            "publication_guard": 1,
            **{feature: True for feature in contract["features"]},
        }
        self.assertEqual(deno.validate_health(source, health), [])
        del health["publication_guard"]
        self.assertIn(
            "publication_guard ausente o desactualizado en producción",
            deno.validate_health(source, health),
        )

    def test_no_network_or_private_hostnames_in_canary_url(self):
        self.assertEqual(
            cf.health_url("https://some-account.workers.dev/api/report"),
            "https://some-account.workers.dev/health",
        )
        self.assertEqual(
            cf.health_url("https://feedback.example.org/"),
            "https://feedback.example.org/health",
        )
        for url in (
            "http://public.example.org/api/report",
            "https://localhost/api/report",
            "https://127.0.0.1/api/report",
            "https://10.0.0.2/api/report",
            "https://user:pass@service.example.org/api/report",
            "https://service.example.org/other",
            "https://service.example.org:8080/api/report",
        ):
            with self.subTest(url=url), self.assertRaises(ValueError):
                cf.health_url(url)

    def test_smoke_never_posts_and_uses_documented_variable(self):
        workflow = (
            ROOT / ".github/workflows/feedback-worker-production-smoke.yml"
        ).read_text(encoding="utf-8")
        self.assertIn("workflow_dispatch:", workflow)
        self.assertIn("schedule:", workflow)
        self.assertIn("vars.SIGA98_FEEDBACK_URL", workflow)
        self.assertIn("scripts/check_feedback_worker_production.py", workflow)
        self.assertNotIn("POST", workflow)
        self.assertNotIn("secrets.", workflow)


if __name__ == "__main__":
    unittest.main()
