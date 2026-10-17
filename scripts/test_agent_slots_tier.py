#!/usr/bin/env python3
"""Pruebas unitarias para tier_de_worker en agent_slots (#1685)."""

import unittest
from typing import Any

from agent_slots import tier_de_worker


class TierDeWorkerTest(unittest.TestCase):
    def test_fallback_worker_tier_explicito(self) -> None:
        variables: dict[str, Any] = {
            "QWEN_FALLBACK_1_TIER": "2",
            "QWEN_FALLBACK_3_TIER": "5",
            "QWEN_FALLBACK_12_TIER": "10",
        }
        self.assertEqual(2, tier_de_worker(variables, "qwen-fallback-1"))
        self.assertEqual(5, tier_de_worker(variables, "qwen-fallback-3"))
        self.assertEqual(10, tier_de_worker(variables, "qwen-fallback-12"))

    def test_worker_base_tier_explicito(self) -> None:
        variables: dict[str, Any] = {
            "QWEN_PRIMARY_TIER": "3",
            "GEMINI_TIER": "4",
        }
        self.assertEqual(3, tier_de_worker(variables, "qwen-primary"))
        self.assertEqual(4, tier_de_worker(variables, "gemini"))

    def test_tier_por_defecto_cuando_variable_ausente(self) -> None:
        variables: dict[str, Any] = {}
        self.assertEqual(1, tier_de_worker(variables, "qwen-fallback-1"))
        self.assertEqual(1, tier_de_worker(variables, "qwen-primary"))
        self.assertEqual(1, tier_de_worker(variables, "gemini"))

    def test_tier_mal_formado_devuelve_defecto(self) -> None:
        casos_mal_formados = [
            "",
            "0",
            "-1",
            "-5",
            "invalid",
            "3.5",
            "²",
            None,
            [],
            {},
            False,
        ]
        for valor in casos_mal_formados:
            with self.subTest(valor=valor):
                variables = {"QWEN_FALLBACK_1_TIER": valor, "QWEN_PRIMARY_TIER": valor}
                self.assertEqual(1, tier_de_worker(variables, "qwen-fallback-1"))
                self.assertEqual(1, tier_de_worker(variables, "qwen-primary"))

    def test_formato_numerico_con_espacios_y_ceros(self) -> None:
        variables: dict[str, Any] = {
            "QWEN_FALLBACK_1_TIER": " 2 ",
            "QWEN_FALLBACK_2_TIER": "03",
        }
        self.assertEqual(2, tier_de_worker(variables, "qwen-fallback-1"))
        self.assertEqual(3, tier_de_worker(variables, "qwen-fallback-2"))

    def test_worker_desconocido_o_fuera_de_rango(self) -> None:
        variables: dict[str, Any] = {
            "QWEN_FALLBACK_13_TIER": "5",
            "QWEN_FALLBACK_0_TIER": "5",
        }
        self.assertEqual(1, tier_de_worker(variables, "qwen-fallback-13"))
        self.assertEqual(1, tier_de_worker(variables, "qwen-fallback-0"))
        self.assertEqual(1, tier_de_worker(variables, "unknown-worker"))
        self.assertEqual(1, tier_de_worker(variables, ""))


if __name__ == "__main__":
    unittest.main()
