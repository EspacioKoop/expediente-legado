from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"


class AmbienteIntegracionTest(unittest.TestCase):
    def test_el_cambio_de_fase_reproduce_el_ambiente(self):
        codigo = DIA.read_text(encoding="utf-8")
        self.assertIn("Ambiente.reproducir(self, fase, -24.0", codigo)
        self.assertIn('"hora": Jornada.hora_decimal(jornada)', codigo)

    def test_el_wiring_no_duplica_reglas_de_jornada(self):
        codigo = DIA.read_text(encoding="utf-8")
        self.assertNotIn("Jornada.fichar_salida", codigo)
        self.assertNotIn("Jornada.dormir", codigo)
        self.assertNotIn("partida.guardar()", codigo)


if __name__ == "__main__":
    unittest.main()
