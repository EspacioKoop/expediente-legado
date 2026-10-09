#!/usr/bin/env python3
"""Suite de pruebas unittest para agent_failure_policy.py (Jules)."""

import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "agent_failure_policy.py"
SPEC = importlib.util.spec_from_file_location("agent_failure_policy", MODULE_PATH)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = mod
SPEC.loader.exec_module(mod)


class TestAgentFailurePolicyJules(unittest.TestCase):
    """Pruebas puras de regresión para prioridades y clasificación de fallos."""

    def test_priority_cascading(self):
        """Verifica el orden estricto de prioridades en classify_failure."""
        mixed_text = (
            "HTTP 429 quota exceeded operation timed out connection reset assertionerror failed"
        )

        # 1. Cancelled le gana a todo
        res = mod.classify_failure(
            stage="implementing",
            job_status="cancelled",
            claim_drift=True,
            no_changes=True,
            text=mixed_text,
        )
        self.assertEqual("cancelled", res["category"])
        self.assertEqual("requeue_neutral", res["action"])

        # 2. Claim drift le gana a no_changes y texto
        res = mod.classify_failure(
            stage="implementing",
            job_status="active",
            claim_drift=True,
            no_changes=True,
            text=mixed_text,
        )
        self.assertEqual("claim_drift", res["category"])
        self.assertEqual("expand_claim", res["action"])

        # 3. No changes le gana a texto
        res = mod.classify_failure(
            stage="implementing",
            job_status="active",
            claim_drift=False,
            no_changes=True,
            text=mixed_text,
        )
        self.assertEqual("no_changes", res["category"])
        self.assertEqual("stop_noop", res["action"])

        # 4. Quota le gana a timeout, provider y test
        quota_plus_others = "operation timed out connection reset assertionerror failed 429"
        res = mod.classify_failure(stage="implementing", text=quota_plus_others)
        self.assertEqual("quota_or_overload", res["category"])

        # 5. Timeout le gana a provider y test
        timeout_plus_others = "operation timed out connection reset assertionerror failed"
        res = mod.classify_failure(stage="implementing", text=timeout_plus_others)
        self.assertEqual("timeout", res["category"])

        # 6. Provider/transporte le gana a test
        provider_plus_test = "connection reset by peer assertionerror failed"
        res = mod.classify_failure(stage="implementing", text=provider_plus_test)
        self.assertEqual("provider_or_transport", res["category"])

        # 7. Test le gana a unknown en etapas de desarrollo/validación
        test_only = "assertionerror in test_main"
        res = mod.classify_failure(stage="implementing", text=test_only)
        self.assertEqual("test_or_preflight", res["category"])

    def test_job_status_cancelled(self):
        """Verifica la clasificacion de trabajos cancelados."""
        res = mod.classify_failure(stage="validating", job_status="cancelled")
        self.assertEqual("cancelled", res["category"])
        self.assertEqual("requeue_neutral", res["action"])

    def test_claim_drift(self):
        """Verifica la clasificacion de desviacion de claim."""
        res = mod.classify_failure(stage="preflight", claim_drift=True)
        self.assertEqual("claim_drift", res["category"])
        self.assertEqual("expand_claim", res["action"])

    def test_no_changes(self):
        """Verifica la clasificacion de no_changes."""
        res = mod.classify_failure(stage="review", no_changes=True)
        self.assertEqual("no_changes", res["category"])
        self.assertEqual("stop_noop", res["action"])

    def test_quota_and_429_503(self):
        """Verifica patrones de cuota y codigos 429/503."""
        samples = [
            "Error 429 Too Many Requests",
            "HTTP 503 Service Unavailable",
            "quota exceeded for this project",
            "terminalquotaerror in stream",
            "retryablequotaerror encountered",
            "resource_exhausted: quota limit hit",
            "rate limit exceeded",
            "rate_limit_exceeded",
            "high demand on servers",
            "temporarily unavailable",
            "server is overloaded",
        ]
        for text in samples:
            with self.subTest(text=text):
                res = mod.classify_failure(stage="implementing", text=text)
                self.assertEqual("quota_or_overload", res["category"])
                self.assertEqual("rotate_provider", res["action"])

        # Asegurar que digitos como 14290 o 5030 no activan 429/503 por coincidencia parcial de digitos
        res_number = mod.classify_failure(stage="implementing", text="process ID 14290")
        self.assertEqual("unknown", res_number["category"])

    def test_timeout(self):
        """Verifica deteccion de timeouts y turnos excedidos."""
        samples = [
            "operation timed out",
            "Request timeout",
            "FatalTurnLimitedError: max turns reached",
            "maxsessionturns limit",
        ]
        for text in samples:
            with self.subTest(text=text):
                res = mod.classify_failure(stage="implementing", text=text)
                self.assertEqual("timeout", res["category"])
                self.assertEqual("split_or_same_worker", res["action"])

    def test_provider_transport_error(self):
        """Verifica errores de transporte y red."""
        samples = [
            "service unavailable due to network partition",
            "connection reset by peer",
            "connection refused",
            "bad gateway response",
            "provider error: backend unreachable",
            "transport error on socket",
            "network error during transmission",
        ]
        for text in samples:
            with self.subTest(text=text):
                res = mod.classify_failure(stage="implementing", text=text)
                self.assertEqual("provider_or_transport", res["category"])
                self.assertEqual("rotate_provider", res["action"])

    def test_test_failures_in_allowed_stages(self):
        """Verifica que fallos de test/lint se reconocen en etapas permitidas."""
        stages = ["validating", "preflight", "ci", "review", "implement", "implementing"]
        texts = [
            "1 test failed",
            "uncaught failure",
            "AssertionError: expected 1 got 2",
            "Traceback (most recent call last):",
            "parse error at line 42",
            "script error in module",
            "would reformat file.py",
            "gdlint error found",
            "unittest failure",
        ]
        for stage in stages:
            for text in texts:
                with self.subTest(stage=stage, text=text):
                    res = mod.classify_failure(stage=stage, text=text)
                    self.assertEqual("test_or_preflight", res["category"])
                    self.assertEqual("same_worker_fix", res["action"])

    def test_test_failures_in_disallowed_stages(self):
        """Verifica que en etapas no reconocidas (ej: publishing), un error de test no es test_or_preflight."""
        disallowed_stages = ["publishing", "dispatch", "deploy", "unknown"]
        for stage in disallowed_stages:
            with self.subTest(stage=stage):
                res = mod.classify_failure(stage=stage, text="AssertionError in test")
                self.assertEqual("unknown", res["category"])
                self.assertEqual("human_review", res["action"])

    def test_unknown_failures(self):
        """Verifica que mensajes sin patrones conocidos se clasifican como unknown."""
        res = mod.classify_failure(stage="implementing", text="unrecognized error occurred")
        self.assertEqual("unknown", res["category"])
        self.assertEqual("human_review", res["action"])

    def test_cli_with_large_text_file_without_memory_overflow(self):
        """Verifica que el CLI lea logs acotadamente sin desbordar memoria con archivos grandes."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            large_log = Path(tmp_dir) / "large.log"
            # Crear archivo de 2MB relleno con 'A' y con un error 429 al inicio
            large_log.write_bytes(b"Error 429 Rate Limit\n" + b"A" * (2 * 1024 * 1024))

            test_args = [
                "agent_failure_policy.py",
                "--stage",
                "implementing",
                "--text-file",
                str(large_log),
            ]

            stdout_buf = io.StringIO()
            with patch.object(sys, "argv", test_args), patch("sys.stdout", stdout_buf):
                exit_code = mod.main()

            self.assertEqual(0, exit_code)
            output = json.loads(stdout_buf.getvalue().strip())
            self.assertEqual("quota_or_overload", output["category"])
            self.assertEqual("rotate_provider", output["action"])
            self.assertEqual("implementing", output["stage"])


if __name__ == "__main__":
    unittest.main()
