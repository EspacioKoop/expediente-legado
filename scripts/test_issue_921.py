import unittest

from scripts.godot_pruebas import comprobar_contrato


class Issue921Test(unittest.TestCase):
    def test_doctrinas_transversales_y_rituales(self):
        comprobar_contrato(
            self,
            "pruebas/issue_921_smoke.gd",
            "issue_921: 45 pasadas, 0 fallos",
        )


if __name__ == "__main__":
    unittest.main()
