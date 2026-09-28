"""Contrato: la implementación del worker tiene límite propio y no publica
cambios a medias (#1636, piloto #1695)."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKER = (ROOT / ".github" / "workflows" / "agent-worker.yml").read_text(encoding="utf-8")


def paso(marca: str) -> str:
    inicio = WORKER.index(marca)
    return WORKER[inicio : WORKER.index("\n      - ", inicio + 1)]


class ImplementacionTest(unittest.TestCase):
    def test_implementar_tiene_timeout_por_debajo_del_job(self):
        for pid in ("implement_qwen", "implement_gemini"):
            with self.subTest(paso=pid):
                bloque = paso(f"- id: {pid}\n")
                self.assertIn("timeout-minutes: 35", bloque)
                self.assertIn("continue-on-error: true", bloque)
        self.assertIn("timeout-minutes: 60", WORKER)

    def test_implementacion_incompleta_no_se_publica(self):
        bloque = paso("- name: Validar diff y preflight\n")
        self.assertIn(
            "IMPLEMENT_OUTCOME: ${{ inputs.provider == 'qwen' && steps.implement_qwen.outcome || steps.implement_gemini.outcome }}",
            bloque,
        )
        # La comprobación va antes de preparar el diff o ejecutar el preflight.
        self.assertLess(bloque.index('"$IMPLEMENT_OUTCOME" != success'), bloque.index("git add -A"))


if __name__ == "__main__":
    unittest.main()
