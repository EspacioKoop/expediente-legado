import unittest

from scripts.godot_pruebas import comprobar_contrato


class Issue779Test(unittest.TestCase):
    def test_careo_documental_y_juicio(self):
        comprobar_contrato(
            self,
            "pruebas/issue_779_smoke.gd",
            "issue_779: 51 pasadas, 0 fallos",
        )


if __name__ == "__main__":
    unittest.main()
