import unittest

import agent_slots as slots


class AgentSlotsLimitsTest(unittest.TestCase):
    def test_backend_de_url_hostnames_desconocidos_no_se_filtran(self):
        urls_desconocidas = [
            "https://internal-service.private.local/v1",
            "http://192.168.1.100:8080/v1",
            "https://user:password@secret-domain.org/api",
            "http://localhost:11434/v1",
            "ftp://unknown-server.net/path",
            "not_a_valid_url",
            "",
        ]
        for url in urls_desconocidas:
            with self.subTest(url=url):
                self.assertEqual("custom", slots.backend_de_url(url))

        self.assertEqual("groq", slots.backend_de_url("https://api.groq.com/openai/v1"))
        self.assertEqual("openrouter", slots.backend_de_url("https://openrouter.ai/api/v1"))

    def test_entero_no_negativo_valores_extremos_y_invalidos(self):
        casos_invalidos = [
            "abc",
            "12.34",
            "-5",
            "None",
            None,
            "",
            "   ",
            "²",
            "⑦",
            "9" * 5000,
        ]
        for val in casos_invalidos:
            with self.subTest(val=str(val)[:20]):
                self.assertEqual(0, slots._entero_no_negativo(val))

        casos_validos = [
            ("0", 0),
            ("12", 12),
            ("007", 7),
            ("  100  ", 100),
        ]
        for val_str, esperado in casos_validos:
            with self.subTest(val_str=val_str):
                self.assertEqual(esperado, slots._entero_no_negativo(val_str))

    def test_claves_presentes_limites_y_valores_invalidos(self):
        texto = f"0 1 12 13 -1 abc {'9' * 5000} 5"
        self.assertEqual({1, 5, 12}, slots.claves_presentes(texto))

    def test_slot_de_worker_limites_y_formato(self):
        self.assertIsNone(slots.slot_de_worker("qwen-fallback-0"))
        self.assertEqual(1, slots.slot_de_worker("qwen-fallback-1"))
        self.assertEqual(12, slots.slot_de_worker("qwen-fallback-12"))
        self.assertIsNone(slots.slot_de_worker("qwen-fallback-13"))
        self.assertIsNone(slots.slot_de_worker(f"qwen-fallback-{'9' * 5000}"))
        self.assertIsNone(slots.slot_de_worker("qwen-primary"))
        self.assertIsNone(slots.slot_de_worker("gemini"))
        self.assertIsNone(slots.slot_de_worker("qwen-fallback--1"))
        self.assertIsNone(slots.slot_de_worker("qwen-fallback-abc"))

    def test_tier_de_vacios_y_valores_invalidos(self):
        casos_invalidos = ["", "0", "-1", "invalid", "9" * 5000, None]
        for val in casos_invalidos:
            with self.subTest(val=str(val)[:20]):
                vars_test = {"QWEN_FALLBACK_1_TIER": val}
                self.assertEqual(1, slots.tier_de(vars_test, 1))

        self.assertEqual(2, slots.tier_de({"QWEN_FALLBACK_1_TIER": "2"}, 1))
        self.assertEqual(5, slots.tier_de({"QWEN_FALLBACK_1_TIER": "  5  "}, 1))

    def test_max_task_bytes_de_worker_presupuestos_0_e_invalidos(self):
        casos_0 = ["", "0", "-100", "abc", "9" * 5000, None]
        for val in casos_0:
            with self.subTest(val=str(val)[:20]):
                self.assertEqual(
                    0,
                    slots.max_task_bytes_de_worker(
                        {"QWEN_FALLBACK_1_MAX_TASK_BYTES": val}, "qwen-fallback-1"
                    ),
                )
                self.assertEqual(
                    0,
                    slots.max_task_bytes_de_worker(
                        {"QWEN_PRIMARY_MAX_TASK_BYTES": val}, "qwen-primary"
                    ),
                )

        self.assertEqual(
            2048,
            slots.max_task_bytes_de_worker(
                {"QWEN_FALLBACK_1_MAX_TASK_BYTES": "2048"}, "qwen-fallback-1"
            ),
        )

    def test_secreto_de_herencia_de_claves_permitidas_y_no_permitidas(self):
        # Claves permitidas: slots 1..12 y proveedores base "qwen" y "gemini"
        self.assertEqual("QWEN_FALLBACK_1_API_KEY", slots.secreto_de({"QWEN_FALLBACK_2_KEY_FROM": "1"}, 2))
        self.assertEqual("QWEN_FALLBACK_12_API_KEY", slots.secreto_de({"QWEN_FALLBACK_2_KEY_FROM": "12"}, 2))
        self.assertEqual("QWEN_API_KEY", slots.secreto_de({"QWEN_FALLBACK_2_KEY_FROM": "qwen"}, 2))
        self.assertEqual("GEMINI_API_KEY", slots.secreto_de({"QWEN_FALLBACK_2_KEY_FROM": "gemini"}, 2))

        # Claves no permitidas u orígenes desconocidos
        origenes_prohibidos = [
            "0",
            "13",
            "OMNIROUTE_API_KEY",
            "AWS_SECRET_ACCESS_KEY",
            "TAILSCALE_KEY",
            "9" * 5000,
            "../etc/passwd",
            "QWEN_FALLBACK_1_API_KEY",
        ]
        for origen in origenes_prohibidos:
            with self.subTest(origen=origen[:20]):
                self.assertEqual("", slots.secreto_de({"QWEN_FALLBACK_2_KEY_FROM": origen}, 2))

        # Por defecto sin KEY_FROM
        self.assertEqual("QWEN_FALLBACK_2_API_KEY", slots.secreto_de({}, 2))

    def test_fallbacks_y_resolver_orden_por_tier_y_limites(self):
        variables = {
            "QWEN_FALLBACK_1_BASE_URL": "https://openrouter.ai/api/v1",
            "QWEN_FALLBACK_1_TIER": "3",
            "QWEN_FALLBACK_2_BASE_URL": "https://integrate.api.nvidia.com/v1",
            "QWEN_FALLBACK_2_TIER": "1",
            "QWEN_FALLBACK_3_BASE_URL": "https://api.groq.com/openai/v1",
            "QWEN_FALLBACK_3_TIER": "2",
            "QWEN_FALLBACK_13_BASE_URL": "https://openrouter.ai/api/v1",
            "QWEN_FALLBACK_13_TIER": "1",
        }
        con_clave = {1, 2, 3, 13}

        fallbacks = slots.fallbacks(variables, con_clave)
        workers = [f["worker"] for f in fallbacks]
        # El slot 13 excede MAX_FALLBACKS (12) y se ignora. Orden por tier: 2 (tier 1), 3 (tier 2), 1 (tier 3)
        self.assertEqual(["qwen-fallback-2", "qwen-fallback-3", "qwen-fallback-1"], workers)

        # Resolver "primera" selecciona el fallback con menor tier (slot 2)
        res_primera = slots.resolver(variables, "primera", con_clave)
        self.assertIsNotNone(res_primera)
        self.assertEqual("qwen-fallback-2", res_primera["worker"])

        # Resolver slot 0 o slot 13 devuelve None
        self.assertIsNone(slots.resolver(variables, "qwen-fallback-0", con_clave))
        self.assertIsNone(slots.resolver(variables, "qwen-fallback-13", con_clave))


if __name__ == "__main__":
    unittest.main()
