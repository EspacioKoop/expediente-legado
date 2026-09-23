import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PATCH = ROOT / "patches" / "godot_popup_fix.patch"
DOC = ROOT / "docs" / "godot-popup-801.md"
VERSION = ROOT / ".godot-version"


class GodotPopupPatch801Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.patch = PATCH.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")
        cls.version = VERSION.read_text(encoding="utf-8").strip()

    def test_el_parche_apunta_al_popup_del_motor(self) -> None:
        self.assertIn("a/scene/gui/popup.cpp", self.patch)
        self.assertIn("b/scene/gui/popup.cpp", self.patch)
        self.assertNotIn("index xx..xx", self.patch)

    def test_conexiones_y_desconexiones_quedan_guardadas(self) -> None:
        self.assertGreaterEqual(self.patch.count("is_connected("), 4)
        self.assertIn(
            "!parent_window->is_connected(SceneStringName(focus_entered)",
            self.patch,
        )
        self.assertIn(
            "!parent_window->is_connected(SceneStringName(tree_exited)",
            self.patch,
        )
        self.assertIn(
            "parent_window->is_connected(SceneStringName(focus_entered)",
            self.patch,
        )
        self.assertIn(
            "parent_window->is_connected(SceneStringName(tree_exited)",
            self.patch,
        )

    def test_documenta_que_el_template_oficial_no_aplica_el_parche(self) -> None:
        self.assertIn("no compila ni selecciona", self.doc.lower())
        self.assertIn("templates oficiales 4.7", self.doc)
        self.assertIn("godotengine/godot/issues/87626", self.doc)
        self.assertIn("godotengine/godot/issues/89657", self.doc)

    def test_la_mitigacion_sigue_acotada_a_la_linea_actual(self) -> None:
        self.assertEqual("4.7-stable", self.version)
        self.assertIn("4.7.2-stable", self.doc)
        self.assertIn("4.8-dev4", self.doc)


if __name__ == "__main__":
    unittest.main()
