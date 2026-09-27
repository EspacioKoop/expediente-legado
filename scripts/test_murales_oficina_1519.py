import unittest

from scripts.godot_pruebas import comprobar_contrato


class MuralesOficinaTest(unittest.TestCase):
    def test_ninguna_pieza_mural_pisa_a_otra(self):
        # #1519: pósteres, láminas, señalética y reloj se montan juntos y se
        # proyectan sobre su pared contra tablón, puerta y ventanas.
        comprobar_contrato(
            self,
            "pruebas/pruebas_murales_oficina_1519.gd",
            "4 pasadas, 0 fallos",
        )


if __name__ == "__main__":
    unittest.main()
