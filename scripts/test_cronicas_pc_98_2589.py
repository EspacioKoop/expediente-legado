import unittest
from scripts.godot_pruebas import comprobar_contrato


class CronicasPc98Test(unittest.TestCase):
    def test_menu_y_retorno(self) -> None:
        comprobar_contrato(
            self, "pruebas/pruebas_cronicas_pc_98_2589.gd", "15 pasadas, 0 fallos", timeout=40
        )
