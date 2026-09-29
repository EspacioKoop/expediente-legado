from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
WRAPPER = ROOT / ".github" / "actions" / "upload-artifact" / "action.yml"
GBC = ROOT / ".github" / "workflows" / "gbc-fixtures.yml"
CI_BRAIN = ROOT / ".github" / "workflows" / "ci-brain.yml"


class UploadArtifactWrapper1888Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.wrapper = WRAPPER.read_text(encoding="utf-8")
        cls.gbc = GBC.read_text(encoding="utf-8")
        cls.ci_brain = CI_BRAIN.read_text(encoding="utf-8")

    def test_wrapper_fija_upstream_por_sha_y_version(self):
        self.assertRegex(
            self.wrapper,
            re.compile(r"uses: actions/upload-artifact@[0-9a-f]{40}\s+# v\d+\.\d+\.\d+"),
        )
        self.assertNotRegex(self.wrapper, r"actions/upload-artifact@v\d")

    def test_wrapper_expone_y_reenvia_inputs_del_smoke(self):
        for nombre in ("name", "path", "if-no-files-found", "retention-days"):
            self.assertIn(f"  {nombre}:", self.wrapper)
            self.assertIn("$" + "{{ inputs." + nombre + " }}", self.wrapper)

    def test_workflows_smoke_usan_wrapper_sin_pin_duplicado(self):
        for workflow in (self.gbc, self.ci_brain):
            self.assertIn("uses: ./.github/actions/upload-artifact", workflow)
            self.assertNotIn("actions/upload-artifact@", workflow)
            self.assertLess(
                workflow.index("actions/checkout@"),
                workflow.index("uses: ./.github/actions/upload-artifact"),
            )

    def test_gbc_reacciona_a_cambios_del_wrapper(self):
        self.assertIn('".github/actions/upload-artifact/**"', self.gbc)


if __name__ == "__main__":
    unittest.main()
