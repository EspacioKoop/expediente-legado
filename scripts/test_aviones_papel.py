from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot" / "guion" / "aviones_papel.gd"


class AvionesPapelTest(unittest.TestCase):
    def setUp(self):
        self.source = SOURCE.read_text(encoding="utf-8")

    def test_superficie_pura(self):
        self.assertIn("class_name AvionesPapel", self.source)
        self.assertIn("extends RefCounted", self.source)
        self.assertIn("static func nueva(participantes: Array", self.source)
        self.assertIn("static func simular(", self.source)
        self.assertIn("static func lanzar(", self.source)
        self.assertIn("static func resultado(estado: Dictionary)", self.source)
        self.assertNotIn("extends Node", self.source)
        self.assertNotIn("Partida", self.source)

    def test_tres_modelos_y_tres_lanzamientos(self):
        self.assertIn('"estable": {', self.source)
        self.assertIn('"rapido": {', self.source)
        self.assertIn('"impredecible": {', self.source)
        self.assertIn("const LANZAMIENTOS_POR_PARTICIPANTE := 3", self.source)
        self.assertIn(
            'if int(estado["lanzamiento"]) >= LANZAMIENTOS_POR_PARTICIPANTE:',
            self.source,
        )

    def test_trayectoria_siempre_acotada(self):
        self.assertIn("const TIEMPO_MAX := 8.0", self.source)
        self.assertIn("const LIMITE_LATERAL := 5.5", self.source)
        self.assertIn("const LIMITE_FONDO := 32.0", self.source)
        self.assertIn('motivo = "aterrizaje"', self.source)
        self.assertIn('motivo = "borde"', self.source)
        self.assertIn('"tiempo": minf(tiempo, TIEMPO_MAX)', self.source)

    def test_distancia_precision_y_zona(self):
        self.assertIn('"distancia": maxf(posicion.z, 0.0)', self.source)
        self.assertIn('"precision": maxf(0.0, 100.0 - error * 7.5)', self.source)
        self.assertIn('"zona": error <= RADIO_ZONA', self.source)
        self.assertIn('"precision":', self.source)
        self.assertIn('"zona":', self.source)

    def test_companeros_deterministas_y_cunado_torcido(self):
        self.assertIn('"distancia": {"modelo": "rapido"', self.source)
        self.assertIn('"papelera": {"modelo": "estable"', self.source)
        self.assertIn('"cunado": {', self.source)
        self.assertIn('"modelo": "impredecible"', self.source)
        self.assertIn('"direccion": -0.34', self.source)
        self.assertNotIn("randf", self.source)
        self.assertNotIn("RandomNumberGenerator", self.source)

    def test_abandono_devuelve_resultado_sin_efectos_externos(self):
        self.assertIn("static func abandonar(estado: Dictionary)", self.source)
        self.assertIn('estado["abandonada"] = true', self.source)
        self.assertIn('"completa": estado.get("terminada", false)', self.source)
        self.assertIn('"abandonada": estado.get("abandonada", false)', self.source)
        self.assertNotIn("guardar", self.source.lower())
        self.assertNotIn("sello", self.source.lower())


if __name__ == "__main__":
    unittest.main()
