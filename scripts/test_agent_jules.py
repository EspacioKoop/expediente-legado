"""Contrato del puente de reservas de Jules (#1917).

Jules no publica CLAIM/RELEASE: `agent-jules.yml` lo hace por él con las mismas
herramientas y límites del pool, para que ningún otro agente pise sus rutas.
"""

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "agent-jules.yml"


class PuenteJulesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Sin PyYAML: el job rápido de CI no lo instala (#1929).
        cls.texto = WORKFLOW.read_text(encoding="utf-8")
        primer_run = cls.texto.index("        run: |")
        siguiente_job = cls.texto.index("\n  pr_real:", primer_run)
        cls.script_reserva = cls.texto[primer_run:siguiente_job]
        segundo_run = cls.texto.index("        run: |", siguiente_job)
        tercer_job = cls.texto.index("\n  pr_ready:", segundo_run)
        cls.script_pr = cls.texto[segundo_run:tercer_job]
        tercer_run = cls.texto.index("        run: |", tercer_job)
        cuarto_job = cls.texto.index("\n  fallback_pool:", tercer_run)
        cls.script_ready = cls.texto[tercer_run:cuarto_job]
        cuarto_run = cls.texto.index("        run: |", cuarto_job)
        cls.script_fallback = cls.texto[cuarto_run:]

    def test_escucha_label_y_cierre_del_issue(self):
        self.assertRegex(self.texto, r"types:\s*\[labeled, unlabeled, closed\]")
        self.assertIn("github.event.label.name == 'jules'", self.texto)
        self.assertIn("contains(github.event.issue.labels.*.name, 'jules')", self.texto)

    def test_permisos_minimos_y_sin_secretos(self):
        self.assertRegex(
            self.texto,
            r"permissions:\n  contents: read\n  issues: write\n  pull-requests: read\n  actions: write\n",
        )
        self.assertNotIn("write-all", self.texto)
        self.assertNotIn("secrets.", self.texto)

    def test_valida_con_las_herramientas_del_pool(self):
        self.assertIn("scripts/agent_delegated_plan.py", self.texto)
        self.assertIn("scripts/agent_plan_parse.py", self.texto)
        self.assertIn("scripts/agent_scope_limit.py --issue-json /tmp/issue.json", self.texto)
        self.assertRegex(self.texto, r'--max-files\s+"\$MAX_FILES"')

    def test_claim_y_release_en_el_registro_activo(self):
        self.assertIn("gestionar_reservas_rollover.py --active", self.texto)
        self.assertRegex(
            self.texto,
            r"CLAIM issue=#\$ISSUE agent=Jules branch=\$branch files=\$files goal=\$goal lease=48h",
        )
        self.assertIn("RELEASE issue=#$ISSUE branch=$branch", self.texto)

    def test_sin_plan_valido_no_hay_reserva(self):
        paso = self.texto[self.texto.index("status=0"):self.texto.index("files=\"$(jq")]
        self.assertIn("agent:needs-human", paso)
        self.assertIn("exit 0", paso)

    def test_no_interpola_texto_del_issue_en_el_script(self):
        # Título y cuerpo son de terceros: solo entran por fichero, nunca por ${{ }}.
        self.assertNotRegex(self.texto, r"\$\{\{[^}]*github\.event\.issue\.(title|body)")
        self.assertIsNone(re.search(r"\$\{\{", self.script_reserva))
        self.assertIsNone(re.search(r"\$\{\{", self.script_pr))
        self.assertIsNone(re.search(r"\$\{\{", self.script_ready))
        self.assertIsNone(re.search(r"\$\{\{", self.script_fallback))

    def test_fallback_escucha_solo_error_terminal_del_bot_jules(self):
        self.assertRegex(
            self.texto,
            r"issue_comment:\n\s+types: \[created\]",
        )
        self.assertIn(
            "github.event.comment.user.login == 'google-labs-jules[bot]'",
            self.texto,
        )
        self.assertIn("encountered an unexpected error", self.texto)
        self.assertIn("wasn''t able to complete", self.texto)
        self.assertIn("contains(github.event.issue.labels.*.name, 'jules')", self.texto)

    def test_fallback_revalida_plan_y_evitar_pr_duplicada(self):
        self.assertIn("scripts/agent_delegated_plan.py", self.script_fallback)
        self.assertIn("scripts/agent_plan_parse.py", self.script_fallback)
        self.assertRegex(self.script_fallback, r'--max-files\s+"\$MAX_FILES"')
        self.assertIn("gh pr list", self.script_fallback)
        self.assertIn("Fallback Jules omitido: #$ISSUE ya tiene una PR abierta.", self.script_fallback)
        self.assertIn("agent:needs-human", self.script_fallback)

    def test_fallback_libera_reencola_y_despacha_pool(self):
        self.assertIn(
            "RELEASE issue=#$ISSUE branch=jules/issue-$ISSUE motivo=jules-error-sin-PR-fallback-pool",
            self.script_fallback,
        )
        self.assertIn("--remove-label jules --add-label agent:auto", self.script_fallback)
        self.assertIn("gh workflow run agent-pool.yml", self.script_fallback)
        self.assertIn("-f max_parallel=6", self.script_fallback)
        self.assertNotIn("gh pr merge", self.script_fallback)

    def test_pr_real_se_autentica_por_tres_senales(self):
        self.assertRegex(self.texto, r"pull_request:\n\s+types: \[opened, reopened, synchronize, closed\]")
        self.assertIn("github.event.pull_request.head.repo.full_name == github.repository", self.texto)
        self.assertIn("PR created automatically by Jules for task [", self.texto)
        self.assertIn('[[ ! "$HEAD_BRANCH" =~ -([0-9]{12,})$ ]]', self.texto)
        self.assertIn("fixes_re='Fixes[[:space:]]+#([0-9]+)'", self.texto)
        self.assertIn('[[ "$BODY" =~ $fixes_re ]]', self.texto)
        self.assertIn("grep -Fxq jules", self.texto)

    def test_pr_ready_solo_nace_de_ci_canonico_verde(self):
        self.assertRegex(
            self.texto,
            r"workflow_run:\n\s+workflows: \[CI\]\n\s+types: \[completed\]",
        )
        self.assertIn("github.event.workflow_run.conclusion == 'success'", self.texto)
        self.assertIn("github.event.workflow_run.event == 'pull_request'", self.texto)
        self.assertIn("github.event.workflow_run.head_sha", self.texto)

    def test_pr_ready_revalida_jules_sha_issue_y_checks_core(self):
        self.assertIn('gh api "repos/$GITHUB_REPOSITORY/pulls/$PR"', self.script_ready)
        self.assertIn('[[ "$head_repo" != "$GITHUB_REPOSITORY" ]]', self.script_ready)
        self.assertIn('[[ "$head_sha" != "$CI_HEAD_SHA" ]]', self.script_ready)
        self.assertIn('[[ ! "$head_branch" =~ -([0-9]{12,})$ ]]', self.script_ready)
        self.assertIn("PR created automatically by Jules for task [$task_id]", self.script_ready)
        self.assertIn("fixes_re='Fixes[[:space:]]+#([0-9]+)'", self.script_ready)
        self.assertIn("grep -Fxq jules", self.script_ready)
        self.assertIn("actions/runs?head_sha=$head_sha&event=pull_request", self.script_ready)
        for check in ("CI", "Secretos", "GBC fixtures", "Auto-label by area"):
            self.assertIn(f'.name == "{check}"', self.script_ready)

    def test_pr_ready_exige_diff_exacto_del_plan_delegado(self):
        self.assertIn("scripts/agent_scope_limit.py --issue-json /tmp/issue.json", self.texto)
        self.assertIn("scripts/agent_delegated_plan.py", self.script_ready)
        self.assertIn("scripts/agent_plan_parse.py", self.script_ready)
        self.assertIn("jq -r '.files[]' /tmp/plan.json | sort -u", self.script_ready)
        self.assertIn('pulls/$PR/files?per_page=100', self.script_ready)
        self.assertIn("diff -u /tmp/plan_files /tmp/pr_files", self.script_ready)
        self.assertIn("--add-label agent:needs-human", self.script_ready)
        self.assertIn("archivos reales fuera o ausentes del AGENT_PLAN", self.script_ready)

    def test_pr_ready_es_idempotente_y_no_fusiona(self):
        self.assertIn('marca="PR_READY issue=#$issue pr=#$PR sha=$head_sha"', self.script_ready)
        self.assertIn('grep -Fq "$marca"', self.script_ready)
        self.assertIn('"$marca pruebas=CI-canonica+checks-core-verdes', self.script_ready)
        self.assertNotIn("gh pr merge", self.script_ready)
        self.assertNotRegex(self.texto, r"contents:\s+write")

    def test_pr_real_espeja_draft_y_libera_claim_sintetico(self):
        self.assertIn("PR_DRAFT issue=#$issue pr=#$PR sha=$HEAD_SHA branch=$HEAD_BRANCH", self.texto)
        self.assertIn('claim_branch="jules/issue-$issue"', self.texto)
        self.assertIn("RELEASE issue=#$issue pr=#$PR branch=$claim_branch", self.texto)
        self.assertIn("actual_branch=$HEAD_BRANCH", self.texto)
        self.assertNotIn("gh pr merge", self.texto)
        self.assertNotRegex(self.texto, r"contents:\s+write")


if __name__ == "__main__":
    unittest.main()
