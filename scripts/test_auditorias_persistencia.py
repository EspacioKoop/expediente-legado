import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
PARTIDA = (ROOT / "godot/guion/partida.gd").read_text(encoding="utf-8")
AUDITORIAS = (ROOT / "godot/guion/auditorias.gd").read_text(encoding="utf-8")
PRUEBA_GODOT = "res://pruebas/pruebas_auditorias_persistencia.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class AuditoriasPersistenciaTests(unittest.TestCase):
    def test_partida_declara_y_migra_el_bloque(self):
        self.assertIn("Auditorias.CLAVE_ESTADO: Auditorias.nueva()", PARTIDA)
        self.assertIn("Auditorias.asegurar_en_estado(fusionado)", PARTIDA)

    def test_partida_valida_el_contrato_antes_de_fusionar(self):
        bloque = PARTIDA.split("static func validar", 1)[1].split(
            "static func _validar_inventario", 1
        )[0]
        self.assertIn("guardado.has(Auditorias.CLAVE_ESTADO)", bloque)
        self.assertIn("Auditorias.validar(guardado[Auditorias.CLAVE_ESTADO])", bloque)

    def test_el_predicado_es_puro_respecto_a_salida_y_recompensas(self):
        bloque = AUDITORIAS.split("static func resolver_fin_archivo", 1)[1].split(
            "static func validar", 1
        )[0]
        self.assertIn('jornada.get("acciones", 0)', bloque)
        self.assertIn('"sin_accion_al_fichar"', bloque)
        for prohibido in ("Jornada.fichar_salida", "Sellos.", "Steam", "guardar("):
            self.assertNotIn(prohibido, bloque)

    def test_round_trip_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 15, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
