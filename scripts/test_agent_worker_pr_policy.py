from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "agent-worker.yml"


class AgentWorkerPrPolicyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")
        cls.guard = cls.workflow.split(
            "- id: guard\n", 1
        )[1].split("\n      - name: Checkout", 1)[0]
        cls.publish = cls.workflow.split(
            "name: Publicar PR draft y lanzar CI canonica", 1
        )[1].split("\n      - name: Limpiar fallo o cancelacion", 1)[0]

    def test_guard_reconoce_refs_closes_y_fixes_sin_prefijos_numericos(self):
        self.assertIn('--arg issue "$ISSUE"', self.guard)
        self.assertIn("(Refs|Closes|Fixes)", self.guard)
        self.assertIn('$issue + "([[:space:]]|[.,;:]|$)"', self.guard)
        self.assertNotIn('--arg n "Refs #$ISSUE"', self.guard)

    def test_pr_existente_normaliza_issue_y_no_arranca_worker(self):
        self.assertIn("--add-label agent:pr-open", self.guard)
        for label in ("agent:auto", "agent:pool", "agent:qwen", "agent:gemini"):
            self.assertIn(f"--remove-label {label}", self.guard)
        self.assertIn('echo "run=false" >> "$GITHUB_OUTPUT"', self.guard)
        self.assertIn("ya tiene una PR abierta", self.guard)

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

    def test_euriclea_se_dispara_por_pr_y_es_best_effort(self):
        self.assertIn('pr_number="$(gh pr view "$url"', self.publish)
        self.assertIn("if ! gh workflow run agent-review.yml", self.publish)
        self.assertIn('--ref main -f pr="$pr_number"', self.publish)
        self.assertIn("queda el barrido periódico", self.publish)
        self.assertLess(
            self.publish.index("gh workflow run agent-review.yml"),
            self.publish.index("gh workflow run ci.yml"),
        )


if __name__ == "__main__":
    unittest.main()
