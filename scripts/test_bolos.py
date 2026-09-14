from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "bolos.gd"


class BolosTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")

    def test_modulo_puro_y_superficie(self):
        self.assertIn("class_name Bolos", self.source)
        self.assertIn("static func nueva(lanzadores: Array)", self.source)
        self.assertIn("static func derribar(estado: Dictionary, bolos: int)", self.source)
        self.assertIn("static func turno_terminado(estado: Dictionary)", self.source)
        self.assertIn("static func resultado(estado: Dictionary)", self.source)
        self.assertNotIn("extends Node", self.source)
        self.assertNotIn("partida.estado", self.source)

    def test_reglas_del_turno(self):
        self.assertIn("const BOLOS_POR_TURNO := 10", self.source)
        self.assertIn("const LANZAMIENTOS_POR_TURNO := 2", self.source)
        self.assertIn('"lanzadores": lanzadores.duplicate()', self.source)
        self.assertIn('"turno": 0', self.source)
        self.assertIn('"lanzamiento": 0', self.source)

    def test_limita_bolos_y_no_arrastra_partidas(self):
        self.assertIn("clampi(bolos, 0, restantes)", self.source)
        self.assertIn("static func nueva(lanzadores: Array)", self.source)
        self.assertIn('"puntuaciones": lanzadores.map', self.source)

    def test_abandono_y_empate_tienen_resultado_valido(self):
        self.assertIn("static func abandonar(estado: Dictionary)", self.source)
        self.assertIn('"ganador": ganadores[0] if ganadores.size() == 1 else "empate"', self.source)
        self.assertIn('"abandonada": estado.get("abandonada", false)', self.source)


if __name__ == "__main__":
    unittest.main()
