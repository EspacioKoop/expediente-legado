from pathlib import Path
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / ".github" / "dependabot.yml"


class DependabotConfigTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = yaml.safe_load(CONFIG.read_text(encoding="utf-8"))

    def _github_actions(self):
        for update in self.data.get("updates", []):
            if update.get("package-ecosystem") == "github-actions":
                return update
        self.fail("falta configuración de Dependabot para github-actions")

    def test_grupo_automatico_solo_agrupa_minor_y_patch(self):
        update = self._github_actions()
        group = update["groups"]["github-actions-minor-patch"]
        self.assertEqual(group.get("applies-to"), "version-updates")
        self.assertEqual(group.get("patterns"), ["*"])
        self.assertEqual(set(group.get("update-types", [])), {"minor", "patch"})
        self.assertNotIn("major", group.get("update-types", []))

    def test_major_no_queda_ignorado_globalmente(self):
        update = self._github_actions()
        self.assertNotIn("ignore", update)


if __name__ == "__main__":
    unittest.main()
