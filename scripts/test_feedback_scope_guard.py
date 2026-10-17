"""Los cuatro adaptadores F9 deben aplicar el mismo preflight público.

No ejecuta red ni dependencias de Cloudflare/Deno.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
GATEWAYS = (
    "api/report.js",
    "infra/feedback-vercel/api/report.js",
    "infra/feedback-worker/worker.js",
    "infra/feedback-deno/main.ts",
)


class F9ScopePolicyTest(unittest.TestCase):
    def test_all_writers_validate_repo_and_content_before_post(self):
        for filename in GATEWAYS:
            with self.subTest(filename=filename):
                source = (ROOT / filename).read_text(encoding="utf-8")
                self.assertIn("const PRIVATE_FEEDBACK", source)
                self.assertIn("function contieneInfraPrivada(", source)
                self.assertIn("contieneInfraPrivada(payload.title, payload.body)", source)
                self.assertIn("Destino GitHub no permitido", source)
                self.assertIn("Reporte no apto para un repositorio público", source)
                self.assertLess(
                    source.index("contieneInfraPrivada(payload.title, payload.body)"),
                    source.index("https://api.github.com/repos/${repository}/issues"),
                )
                self.assertLess(
                    source.index("Destino GitHub no permitido"),
                    source.index("https://api.github.com/repos/${repository}/issues"),
                )

    def test_matching_rules_do_not_drift_between_gateways(self):
        snippets = []
        for filename in GATEWAYS:
            source = (ROOT / filename).read_text(encoding="utf-8")
            start = source.index("const PRIVATE_FEEDBACK = [")
            end = source.index("];", start) + 2
            snippets.append(source[start:end])
        self.assertEqual(len(set(snippets)), 1)


if __name__ == "__main__":
    unittest.main()
