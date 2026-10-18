import importlib.util
from pathlib import Path
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "check_deno_production.py"
WORKFLOW = ROOT / ".github" / "workflows" / "feedback-deno-production-smoke.yml"

SPEC = importlib.util.spec_from_file_location("check_deno_production", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


SOURCE = """
return json({
  ok: true,
  service: "siga98-feedback-deno",
  version: 4,
  kv_configured: kvConfigured,
  agent_memory: true,
  agent_pool_control: true,
  agent_pool_worker_health: true,
});
"""


class DenoProductionFreshnessTest(unittest.TestCase):
    def test_extrae_version_y_features_del_source(self):
        self.assertEqual(
            {
                "version": 4,
                "features": [
                    "agent_memory",
                    "agent_pool_control",
                    "agent_pool_worker_health",
                ],
            },
            mod.expected_contract(SOURCE),
        )

    def test_health_actual_pasa(self):
        health = {
            "ok": True,
            "service": "siga98-feedback-deno",
            "version": 4,
            "kv_configured": True,
            "agent_memory": True,
            "agent_pool_control": True,
            "agent_pool_worker_health": True,
        }
        self.assertEqual([], mod.validate_health(SOURCE, health))

    def test_version_vieja_y_feature_ausente_fallan(self):
        health = {
            "ok": True,
            "service": "siga98-feedback-deno",
            "version": 3,
            "kv_configured": True,
            "agent_memory": True,
            "agent_pool_control": True,
        }
        errors = mod.validate_health(SOURCE, health)
        self.assertTrue(any("version desplegada=3 esperada=4" in e for e in errors))
        self.assertIn(
            "agent_pool_worker_health no está activo en producción",
            errors,
        )

    def test_kv_es_parte_del_contrato_operativo(self):
        health = {
            "ok": True,
            "service": "siga98-feedback-deno",
            "version": 4,
            "kv_configured": False,
            "agent_memory": True,
            "agent_pool_control": True,
            "agent_pool_worker_health": True,
        }
        self.assertIn("kv_configured != true", mod.validate_health(SOURCE, health))

    def test_monitor_periodico_es_privado_y_el_deploy_sigue_verificando(self):
        self.assertFalse(WORKFLOW.exists())
        deploy = (
            ROOT / ".github" / "workflows" / "feedback-deno-deploy.yml"
        ).read_text(encoding="utf-8")
        self.assertIn("scripts/check_deno_production.py", deploy)
        self.assertIn("infra/feedback-deno/main.ts", deploy)
        self.assertIn("deploy --prod", deploy)


if __name__ == "__main__":
    unittest.main()
