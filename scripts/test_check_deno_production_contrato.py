import importlib.util
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "check_deno_production.py"

SPEC = importlib.util.spec_from_file_location("check_deno_production", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


SYNTHETIC_MAIN_TS = """
return json({
  ok: true,
  service: "siga98-feedback-deno",
  version: 5,
  kv_configured: true,
  agent_memory: true,
  agent_alpha: true,
  agent_memory: true,
});
"""

SYNTHETIC_MAIN_TS_NO_VERSION = """
return json({
  ok: true,
  service: "siga98-feedback-deno",
  agent_memory: true,
});
"""


class ExpectedContractTest(unittest.TestCase):
    def test_expected_contract_extrae_version_y_features_ordenadas(self):
        contract = mod.expected_contract(SYNTHETIC_MAIN_TS)
        self.assertEqual(contract["version"], 5)
        self.assertEqual(contract["features"], ["agent_alpha", "agent_memory"])

    def test_expected_contract_sin_version_lanza_value_error(self):
        with self.assertRaises(ValueError) as cm:
            mod.expected_contract(SYNTHETIC_MAIN_TS_NO_VERSION)
        self.assertIn("main.ts no declara version en /health", str(cm.exception))


class ValidateHealthTest(unittest.TestCase):
    def setUp(self):
        self.source = SYNTHETIC_MAIN_TS
        self.valid_health = {
            "ok": True,
            "service": "siga98-feedback-deno",
            "version": 5,
            "kv_configured": True,
            "agent_alpha": True,
            "agent_memory": True,
        }

    def test_validate_health_correcto_sin_errores(self):
        errors = mod.validate_health(self.source, self.valid_health)
        self.assertEqual(errors, [])

    def test_validate_health_con_campos_de_menos(self):
        health_incompleto = {
            "version": 5,
        }
        errors = mod.validate_health(self.source, health_incompleto)
        self.assertIn("health.ok != true", errors)
        self.assertIn("health.service inesperado", errors)
        self.assertIn("agent_alpha no está activo en producción", errors)
        self.assertIn("agent_memory no está activo en producción", errors)
        self.assertIn("kv_configured != true", errors)

    def test_validate_health_con_tipos_distintos(self):
        health_tipos_incorrectos = {
            "ok": "true",
            "service": "siga98-feedback-deno",
            "version": "5",
            "kv_configured": 1,
            "agent_alpha": "true",
            "agent_memory": True,
        }
        errors = mod.validate_health(self.source, health_tipos_incorrectos)
        self.assertIn("health.ok != true", errors)
        self.assertIn("version desplegada='5' esperada=5", errors)
        self.assertIn("agent_alpha no está activo en producción", errors)
        self.assertIn("kv_configured != true", errors)

    def test_validate_health_con_valores_erroneos(self):
        health_erroneo = {
            "ok": False,
            "service": "otro-servicio",
            "version": 2,
            "kv_configured": False,
            "agent_alpha": False,
            "agent_memory": True,
        }
        errors = mod.validate_health(self.source, health_erroneo)
        self.assertIn("health.ok != true", errors)
        self.assertIn("health.service inesperado", errors)
        self.assertIn("version desplegada=2 esperada=5", errors)
        self.assertIn("agent_alpha no está activo en producción", errors)
        self.assertIn("kv_configured != true", errors)


if __name__ == "__main__":
    unittest.main()
