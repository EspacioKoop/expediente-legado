from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "agent-worker.yml"


class AgentWorkerPrPolicyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        cls.publish = cls.workflow.split(
            "name: Publicar PR draft y lanzar CI canonica", 1
        )[1].split("\n      - name: Limpiar fallo o cancelacion", 1)[0]

    def test_rama_se_publica_antes_de_intentar_crear_pr(self):
        self.assertLess(
            self.publish.index('git push -u origin "$BRANCH"'),
            self.publish.index("gh pr create"),
        )

    def test_bloqueo_de_politica_hace_handoff_sin_penalizar_worker(self):
        self.assertIn("not permitted to create or approve pull requests", self.publish)
        self.assertIn("createPullRequest", self.publish)
        self.assertIn("agent-pool-pr-policy-block", self.publish)
        self.assertIn("--add-label agent:needs-human", self.publish)
        self.assertIn("El worker no se penaliza.", self.publish)
        self.assertIn("exit 0", self.publish)

    def test_otros_fallos_de_creacion_siguen_fallando(self):
        self.assertIn("printf '%s\\n' \"$pr_salida\" >&2", self.publish)
        self.assertIn("exit 1", self.publish)
        self.assertIn('url="$pr_salida"', self.publish)


if __name__ == "__main__":
    unittest.main()
