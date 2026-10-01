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
    "QWEN_FALLBACK_7_MAX_TASK_BYTES": "24000",
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
            {"worker": "qwen-fallback-7", "slot": 7, "url": NVIDIA, "model": "qwen3-coder-plus", "backend": "nvidia", "tier": 1,
             "max_task_bytes": 24000, "secret": "QWEN_FALLBACK_7_API_KEY"},
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

    def test_presupuesto_de_tarea_es_opcional_y_provider_neutral(self):
        self.assertEqual(24000, slots.max_task_bytes_de_worker(VARS, "qwen-fallback-7"))
        self.assertEqual(
            32000,
            slots.max_task_bytes_de_worker(
                {"QWEN_PRIMARY_MAX_TASK_BYTES": "32000"}, "qwen-primary"
            ),
        )
        for valor in ("", "-1", "x", None):
            with self.subTest(valor=valor):
                self.assertEqual(
                    0,
                    slots.max_task_bytes_de_worker(
                        {"QWEN_FALLBACK_3_MAX_TASK_BYTES": valor},
                        "qwen-fallback-3",
                    ),
                )

    def test_backend_se_infiere_solo_para_hosts_conocidos(self):
        casos = {
            "https://api.groq.com/openai/v1": "groq",
            "https://api.mistral.ai/v1": "mistral",
            NVIDIA: "nvidia",
            "https://openrouter.ai/api/v1": "openrouter",
            "https://generativelanguage.googleapis.com/v1beta/openai/": "gemini",
            "https://api.deepseek.com/v1": "deepseek",
            "https://api.cohere.ai/compatibility/v1": "cohere",
            "https://api.together.xyz/v1": "together",
            "https://omniroute.tailnet.example/v1": "custom",
            "not-a-url": "custom",
        }
        for url, esperado in casos.items():
            with self.subTest(url=url):
                self.assertEqual(esperado, slots.backend_de_url(url))

    def test_inventario_distingue_backend_de_executor(self):
        inventario = slots.inventario(VARS, {1, 2}, {"gemini"}, omniroute=True)
        por_worker = {w["worker"]: w for w in inventario}
        self.assertEqual(("qwen", "omniroute"), (
            por_worker["qwen-primary"]["provider"], por_worker["qwen-primary"]["backend"]
        ))
        self.assertEqual(("gemini", "gemini"), (
            por_worker["gemini"]["provider"], por_worker["gemini"]["backend"]
        ))
        self.assertEqual(("qwen", "openrouter"), (
            por_worker["qwen-fallback-1"]["provider"], por_worker["qwen-fallback-1"]["backend"]
        ))
        self.assertEqual(("qwen", "nvidia"), (
            por_worker["qwen-fallback-2"]["provider"], por_worker["qwen-fallback-2"]["backend"]
        ))

    def test_cli_listar_y_resolver(self):
        entorno = {**os.environ, "VARS_JSON": json.dumps(VARS), "FALLBACK_KEYS": "2 7"}
        script = str(ROOT / "scripts" / "agent_slots.py")
        listar = subprocess.run([sys.executable, script, "listar"], env=entorno, capture_output=True, text=True, check=True)
        self.assertEqual(
            [
                {"worker": "qwen-fallback-2", "provider": "qwen", "backend": "nvidia", "tier": 1},
                {"worker": "qwen-fallback-7", "provider": "qwen", "backend": "nvidia", "tier": 1},
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
        self.assertIn("python3 scripts/agent_slots.py workers", pool)
        self.assertIn("python3 scripts/agent_slots.py usables", pool)
        self.assertNotIn("add_worker", pool)
        self.assertIn("fallback_keys: ${{ needs.prepare.outputs.fallback_keys }}", pool)

    def test_worker_sin_slots_cableados(self):
        worker = (ROOT / ".github" / "workflows" / "agent-worker.yml").read_text(encoding="utf-8")
        cuerpo = worker.split("    secrets:", 1)[1].split("jobs:", 1)[1]
        self.assertNotRegex(cuerpo, r"QWEN_FALLBACK_\d+_")
        self.assertNotRegex(cuerpo, r"qwen-fallback-\d+[):]")
        self.assertEqual(2, cuerpo.count("secrets[steps.qwen_config.outputs.key_secret]"))
        self.assertIn("secrets[steps.slot.outputs.secret] != ''", cuerpo)
        self.assertIn("^(QWEN_FALLBACK_[1-9][0-9]*_API_KEY|QWEN_API_KEY|GEMINI_API_KEY)$", cuerpo)
        self.assertIn("python3 scripts/agent_slots.py resolver", cuerpo)


    def test_autopilot_y_ci_repair_usan_fallbacks_dinamicos(self):
        for nombre in ("agent-autopilot.yml", "agent-ci-repair.yml"):
            texto = (ROOT / ".github" / "workflows" / nombre).read_text(encoding="utf-8")
            with self.subTest(workflow=nombre):
                self.assertIn("python3 scripts/agent_slots.py listar", texto)
                self.assertIn("python3 scripts/agent_slots.py resolver --worker", texto)
                self.assertNotIn("HAS_QWEN_FALLBACK_", texto)
                self.assertNotRegex(
                    texto,
                    r"openai_api_key:\s*\$\{\{\s*secrets\.QWEN_FALLBACK_\d+_API_KEY\s*\}\}",
                )
                numeros = {
                    int(n)
                    for n in re.findall(
                        r"secrets\.QWEN_FALLBACK_(\d+)_API_KEY != '' && '\1'",
                        texto,
                    )
                }
                self.assertEqual(set(range(1, slots.MAX_FALLBACKS + 1)), numeros)
                for intento in range(1, 5):
                    self.assertIn(
                        f"secrets[steps.qwen_fallbacks.outputs.secret_{intento}]",
                        texto,
                    )
                    self.assertIn(
                        f"steps.qwen_fallbacks.outputs.url_{intento}",
                        texto,
                    )


class ProveedoresYModelosTest(unittest.TestCase):
    def test_key_from_reutiliza_clave_de_otro_slot_o_proveedor_base(self):
        variables = {
            "QWEN_FALLBACK_2_BASE_URL": NVIDIA,
            "QWEN_FALLBACK_2_MODEL": "nvidia/nemotron-3-super-120b-a12b",
            "QWEN_FALLBACK_5_BASE_URL": NVIDIA,
            "QWEN_FALLBACK_5_MODEL": "nvidia/nemotron-3-ultra-550b-a55b",
            "QWEN_FALLBACK_5_KEY_FROM": "2",
            "QWEN_FALLBACK_6_BASE_URL": "https://generativelanguage.googleapis.com/v1beta/openai/",
            "QWEN_FALLBACK_6_MODEL": "gemini-3.8-flash-lite",
            "QWEN_FALLBACK_6_KEY_FROM": "gemini",
            "QWEN_FALLBACK_6_TIER": "3",
        }
        usables = slots.fallbacks(variables, {2}, {"gemini"})
        self.assertEqual(
            [("qwen-fallback-2", "QWEN_FALLBACK_2_API_KEY"), ("qwen-fallback-5", "QWEN_FALLBACK_2_API_KEY"),
             ("qwen-fallback-6", "GEMINI_API_KEY")],
            [(s["worker"], s["secret"]) for s in usables],
        )
        # Sin la clave de origen, el slot que la hereda no es utilizable.
        self.assertEqual(["qwen-fallback-2", "qwen-fallback-5"], [s["worker"] for s in slots.fallbacks(variables, {2})])

    def test_key_from_no_puede_nombrar_secretos_arbitrarios(self):
        for origen in ("OMNIROUTE_API_KEY", "kev", "13", "0", "../x"):
            with self.subTest(origen=origen):
                variables = {"QWEN_FALLBACK_3_BASE_URL": NVIDIA, "QWEN_FALLBACK_3_KEY_FROM": origen}
                self.assertEqual("", slots.secreto_de(variables, 3))
                self.assertEqual([], slots.fallbacks(variables, set(), {"qwen", "gemini"}))

    def test_inventario_incluye_proveedores_base_con_su_tier(self):
        variables = {**VARS, "QWEN_PRIMARY_TIER": "1", "GEMINI_TIER": "2", "QWEN_FALLBACK_1_TIER": "3"}
        inventario = slots.inventario(variables, {1, 2}, {"gemini"}, omniroute=True)
        self.assertEqual(
            [("qwen-primary", "qwen", 1), ("gemini", "gemini", 2), ("qwen-fallback-2", "qwen", 1), ("qwen-fallback-1", "qwen", 3)],
            [(w["worker"], w["provider"], w["tier"]) for w in inventario],
        )
        self.assertEqual([], [w for w in slots.inventario({}, set(), set()) if w["worker"] in {"qwen-primary", "gemini"}])

    def test_cli_workers_y_usables(self):
        variables = {**VARS, "QWEN_FALLBACK_7_KEY_FROM": "gemini"}
        entorno = {**os.environ, "VARS_JSON": json.dumps(variables), "FALLBACK_KEYS": "2", "BASE_KEYS": "gemini qwen"}
        script = str(ROOT / "scripts" / "agent_slots.py")
        usables = subprocess.run([sys.executable, script, "usables"], env=entorno, capture_output=True, text=True, check=True)
        self.assertEqual("2 7", usables.stdout.strip())
        workers = subprocess.run([sys.executable, script, "workers"], env=entorno, capture_output=True, text=True, check=True)
        nombres = [w["worker"] for w in json.loads(workers.stdout)]
        self.assertEqual(["qwen-primary", "gemini", "qwen-fallback-2", "qwen-fallback-7"], nombres)


if __name__ == "__main__":
    unittest.main()
