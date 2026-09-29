from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
CODEOWNERS = ROOT / ".github" / "CODEOWNERS"


class SecurityCodeownersTest(unittest.TestCase):
    def test_superficie_sensible_tiene_owner_explicito(self):
        texto = CODEOWNERS.read_text(encoding="utf-8")
        esperadas = (
            "/.github/CODEOWNERS",
            "/.github/workflows/",
            "/.github/dependabot.yml",
            "/scripts/agent_*.py",
            "/scripts/gestionar_reservas*.py",
            "/scripts/reservas_registro.py",
            "/scripts/escanear_secretos.sh",
            "/infra/feedback-deno/",
            "/infra/mando-deno/",
        )
        for patron in esperadas:
            with self.subTest(pattern=patron):
                self.assertRegex(
                    texto,
                    rf"(?m)^{patron.replace('*', r'\*')}\s+@eGurucharri\s*$",
                )

    def test_codeowners_se_protege_a_si_mismo(self):
        texto = CODEOWNERS.read_text(encoding="utf-8")
        self.assertIn("/.github/CODEOWNERS @eGurucharri", texto)


if __name__ == "__main__":
    unittest.main()
