import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
PARTIDA = (ROOT / "godot/guion/partida.gd").read_text(encoding="utf-8")
PRONOSTICOS = (ROOT / "godot/guion/pronosticos.gd").read_text(encoding="utf-8")
PRUEBA_GODOT = "res://pruebas/pruebas_pronosticos_persistencia.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class PronosticosPersistenciaTests(unittest.TestCase):
    def test_partida_declara_y_normaliza_pronosticos(self):
        self.assertIn('"pronosticos": Pronosticos.nuevo()', PARTIDA)
        self.assertIn('Pronosticos.completar(fusionado["pronosticos"])', PARTIDA)

    def test_partida_valida_el_contrato_antes_de_fusionar(self):
        bloque = PARTIDA.split("static func validar", 1)[1].split(
            "static func _validar_inventario", 1
        )[0]
        self.assertIn('guardado.has("pronosticos")', bloque)
        self.assertIn('typeof(guardado["pronosticos"]) != TYPE_DICTIONARY', bloque)
        self.assertIn('Pronosticos.validar(guardado["pronosticos"])', bloque)

    def test_contrato_valida_entradas_persistidas(self):
        self.assertIn("static func validar(estado) -> Array:", PRONOSTICOS)
        self.assertIn('"por_expediente no es un objeto"', PRONOSTICOS)
        self.assertIn('"%s.tipo inválido" % id', PRONOSTICOS)
        self.assertIn('"%s.valor ausente" % id', PRONOSTICOS)
        self.assertIn('"%s.estado inválido" % id', PRONOSTICOS)

    def test_round_trip_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 18, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
