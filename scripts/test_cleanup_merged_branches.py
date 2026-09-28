import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github" / "workflows" / "cleanup-merged-branches.yml"


class CleanupMergedBranchesWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = WORKFLOW.read_text(encoding="utf-8")

    def test_only_runs_for_merged_internal_prs_to_main(self):
        self.assertIn("pull_request_target:", self.text)
        self.assertIn("types: [closed]", self.text)
        self.assertIn("github.event.pull_request.merged == true", self.text)
        self.assertIn("github.event.pull_request.base.ref == 'main'", self.text)
        self.assertIn(
            "github.event.pull_request.head.repo.full_name == github.repository",
            self.text,
        )

    def test_deletes_only_known_work_branch_prefixes(self):
        for prefix in (
            "feature/",
            "fix/",
            "docs/",
            "agent/",
            "infra/",
            "chore/",
            "test/",
        ):
            self.assertIn(repr(prefix), self.text)
        self.assertIn("allowedPrefixes.some", self.text)
        self.assertIn("github.rest.git.deleteRef", self.text)

    def test_does_not_execute_pull_request_head_code(self):
        self.assertNotIn("actions/checkout", self.text)
        self.assertNotIn("\n        run:", self.text)
        self.assertIn(
            "uses: actions/github-script@3a2844b7e9c422d3c10d287c895573f7108da1b3 # v9.0.0",
            self.text,
        )
        self.assertNotIn("uses: actions/github-script@v", self.text)


if __name__ == "__main__":
    unittest.main()
