from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_alquiler_app.gd"
INVENTARIO = ROOT / "godot" / "guion" / "inventario.gd"


class ViviendaInventarioTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.inventario = INVENTARIO.read_text(encoding="utf-8")

    def test_impago_materializa_una_unica_transicion_de_vivienda(self):
        self.assertIn("_perder_vivienda()", self.dia)
        self.assertIn("and _impago_inminente()", self.dia)

    def test_perder_vivienda_expulsa_al_gato_sin_cinematica(self):
        self.assertIn('jornada["gato"]["presente"] = false', self.dia)
        self.assertNotIn("cinematica", self.dia.lower().split("func _perder_vivienda", 1)[1].split("func ", 1)[0])

    def test_consumimos_el_contrato_de_inventario_solo_si_existe(self):
        bloque = self.dia.split("func _perder_vivienda", 1)[1].split("func ", 1)[0]
        self.assertIn('partida.estado.get("inventario", null)', bloque)
        self.assertIn("typeof(inventario) == TYPE_DICTIONARY", bloque)
        self.assertIn("Inventario.perder_casa(inventario)", bloque)

    def test_el_contrato_de_inventario_vacia_solo_home_storage(self):
        bloque = self.inventario.split("static func perder_casa", 1)[1].split("static func ", 1)[0]
        self.assertIn("estado[HOME_STORAGE].clear()", bloque)
        self.assertNotIn("estado[CARRIED].clear()", bloque)


if __name__ == "__main__":
    unittest.main()
