import unittest

from scripts.godot_pruebas import comprobar_contrato


class Issue779FeedbackTest(unittest.TestCase):
    def test_feedback_ritual(self):
        comprobar_contrato(
            self,
            "pruebas/issue_779_feedback_smoke.gd",
            "issue_779_feedback: 6 pasadas, 0 fallos",
        )


if __name__ == "__main__":
    unittest.main()
