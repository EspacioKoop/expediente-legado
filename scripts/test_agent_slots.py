import json
import os
from pathlib import Path
import re
import subprocess
import sys
import unittest

import agent_slots as slots

ROOT = Path(__file__).resolve().parents[1]
NVIDIA = "https://integrate.api.nvidia.com/v1"
VARS = {
    "QWEN_FALLBACK_1_BASE_URL": "https://openrouter.ai/api/v1",
    "QWEN_FALLBACK_1_MODEL": "cohere/north-mini-code:free",
    "QWEN_FALLBACK_2_BASE_URL": NVIDIA,
    "QWEN_FALLBACK_2_MODEL": "nvidia/nemotron-3-super-120b-a12b",
    "QWEN_FALLBACK_7_BASE_URL": NVIDIA,
    "QWEN_FALLBACK_7_MODEL": "",
    "QWEN_FALLBACK_13_BASE_URL": NVIDIA,
    "OTRA_VARIABLE": "x",
}


class SlotsTest(unittest.TestCase):
    def test_descubre_slots_mas_alla_del_cuarto(self):
        workers = [s["worker"] for s in slots.fallbacks(VARS, {1, 2, 7})]
        self.assertEqual(["qwen-fallback-1", "qwen-fallback-2", "qwen-fallback-7"], workers)

    def test_slot_con_url_pero_sin_clave_no_recibe_trabajo(self):
        # Caso real: URLs de NVIDIA configuradas antes de tener las cuentas.
        self.assertEqual(["qwen-fallback-1"], [s["worker"] for s in slots.fallbacks(VARS, {1})])

    def test_fuera_de_rango_se_ignora(self):
        self.assertEqual(set(), slots.claves_presentes("0 13 x"))
        self.assertEqual({2, 7}, slots.claves_presentes(" 2   7 "))
        self.assertIsNone(slots.slot_de_worker("qwen-fallback-13"))
        self.assertIsNone(slots.slot_de_worker("qwen-primary"))

    def test_resolver_worker_y_modelo_por_defecto(self):
        self.assertEqual(
            {"worker": "qwen-fallback-7", "slot": 7, "url": NVIDIA, "model": "qwen3-coder-plus", "tier": 1},
            slots.resolver(VARS, "qwen-fallback-7", {7}, "qwen3-coder-plus"),
        )
        self.assertIsNone(slots.resolver(VARS, "qwen-fallback-7", {2}))
        self.assertEqual(2, slots.resolver(VARS, "primera", {2, 7})["slot"])

    def test_tiers_ordenan_y_la_cascada_agota_el_tier_preferente(self):
        # Caso real: Cohere (slot 1) de último recurso tras los Nemotron (2, 7).
        variables = {**VARS, "QWEN_FALLBACK_1_TIER": "2", "QWEN_FALLBACK_7_TIER": "1"}
        orden = [(s["worker"], s["tier"]) for s in slots.fallbacks(variables, {1, 2, 7})]
        self.assertEqual(
            [("qwen-fallback-2", 1), ("qwen-fallback-7", 1), ("qwen-fallback-1", 2)], orden
        )
        self.assertEqual(2, slots.resolver(variables, "primera", {1, 2, 7})["slot"])
        self.assertEqual(1, slots.resolver(variables, "primera", {1})["slot"])

    def test_tier_invalido_es_1(self):
        for valor in ("", "0", "-1", "x", None):
            with self.subTest(valor=valor):
                self.assertEqual(1, slots.tier_de({"QWEN_FALLBACK_3_TIER": valor}, 3))
        self.assertEqual(3, slots.tier_de({"QWEN_FALLBACK_3_TIER": " 3 "}, 3))

    def test_cli_listar_y_resolver(self):
        entorno = {**os.environ, "VARS_JSON": json.dumps(VARS), "FALLBACK_KEYS": "2 7"}
        script = str(ROOT / "scripts" / "agent_slots.py")
        listar = subprocess.run([sys.executable, script, "listar"], env=entorno, capture_output=True, text=True, check=True)
        self.assertEqual(
            [
                {"worker": "qwen-fallback-2", "provider": "qwen", "tier": 1},
                {"worker": "qwen-fallback-7", "provider": "qwen", "tier": 1},
            ],
            json.loads(listar.stdout),
        )
        falla = subprocess.run(
            [sys.executable, script, "resolver", "--worker", "qwen-fallback-1"], env=entorno, capture_output=True, text=True
        )
        self.assertEqual(3, falla.returncode)


class ContratoWorkflowsTest(unittest.TestCase):
    def test_tabla_de_claves_del_pool_cubre_max_fallbacks(self):
        pool = (ROOT / ".github" / "workflows" / "agent-pool.yml").read_text(encoding="utf-8")
        numeros = {int(n) for n in re.findall(r"secrets\.QWEN_FALLBACK_(\d+)_API_KEY != '' && '\1'", pool)}
        self.assertEqual(set(range(1, slots.MAX_FALLBACKS + 1)), numeros)
        self.assertIn("python3 scripts/agent_slots.py listar", pool)
        self.assertIn("fallback_keys: ${{ needs.prepare.outputs.fallback_keys }}", pool)

    def test_worker_sin_slots_cableados(self):
        worker = (ROOT / ".github" / "workflows" / "agent-worker.yml").read_text(encoding="utf-8")
        cuerpo = worker.split("    secrets:", 1)[1].split("jobs:", 1)[1]
        self.assertNotRegex(cuerpo, r"QWEN_FALLBACK_\d+_")
        self.assertNotRegex(cuerpo, r"qwen-fallback-\d+[):]")
        self.assertEqual(3, cuerpo.count("secrets[format('QWEN_FALLBACK_{0}_API_KEY', steps.qwen_config.outputs.slot)]"))
        self.assertIn("python3 scripts/agent_slots.py resolver", cuerpo)


if __name__ == "__main__":
    unittest.main()
