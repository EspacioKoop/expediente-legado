from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "feedback-deno-deploy.yml"


class DenoDeployWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = WORKFLOW.read_text(encoding="utf-8")

    def test_usa_cli_moderno_y_valida_antes_de_desplegar(self):
        # Fijado por SHA completo, sin exigir uno concreto: Dependabot lo sube.
        self.assertRegex(self.text, r"uses: denoland/setup-deno@[0-9a-f]{40} # v\d+")
        self.assertIn("deno-version: v2.9.6", self.text)
        self.assertNotIn("uses: denoland/setup-deno@v2", self.text)
        self.assertIn("run: deno task check", self.text)
        self.assertIn("deno deploy --org expediente-legado --app siga98-feedback-deno --prod", self.text)
        self.assertNotIn("deployctl", self.text)

    def test_token_real_solo_se_inyecta_en_el_paso_de_deploy(self):
        self.assertIn("HAS_DENO_DEPLOY_TOKEN: ${{ secrets.DENO_DEPLOY_TOKEN != '' }}", self.text)
        self.assertEqual(
            1,
            self.text.count("DENO_DEPLOY_TOKEN: ${{ secrets.DENO_DEPLOY_TOKEN }}"),
        )
        self.assertIn("if: steps.config.outputs.deploy == 'true'", self.text)

    def test_despliegue_se_autoverifica_con_el_contrato_de_main(self):
        self.assertIn("scripts/check_deno_production.py", self.text)
        self.assertIn("--source infra/feedback-deno/main.ts", self.text)
        self.assertIn("$base/health", self.text)
        self.assertIn("seq 1 12", self.text)

    def test_push_de_gateway_dispara_el_deploy_y_cancela_version_obsoleta(self):
        self.assertIn("- 'infra/feedback-deno/**'", self.text)
        self.assertIn("group: feedback-deno-production-deploy", self.text)
        self.assertIn("cancel-in-progress: true", self.text)


if __name__ == "__main__":
    unittest.main()
