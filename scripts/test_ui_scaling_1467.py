import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot" / "project.godot"


class UiScaling1467Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.proyecto = PROJECT.read_text(encoding="utf-8")

    def test_la_interfaz_usa_un_viewport_logico_1080p(self):
        self.assertIn("window/size/viewport_width=1920", self.proyecto)
        self.assertIn("window/size/viewport_height=1080", self.proyecto)

    def test_canvas_items_escala_la_ui_en_4k(self):
        self.assertIn('window/stretch/mode="canvas_items"', self.proyecto)

    def test_se_conserva_la_composicion_16_9(self):
        self.assertIn('window/stretch/aspect="keep"', self.proyecto)


if __name__ == "__main__":
    unittest.main()
