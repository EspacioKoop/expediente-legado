import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
HOST = ROOT / "godot" / "guion" / "juicio_combate_arquetipo_host.gd"
ARENA = ROOT / "godot" / "guion" / "juicio_combate_arena_3d.gd"
PRUEBA = "res://pruebas/pruebas_enjambre_coordinador_1771.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class EnjambreCoordinador1771Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = HOST.read_text(encoding="utf-8")
        cls.arena = ARENA.read_text(encoding="utf-8")

    def test_presupuesto_tiene_suelo_y_techo(self):
        bloque = self.fuente.split("static func presupuesto_enjambre(", 1)[1].split(
            "static func nuevo_enjambre(", 1
        )[0]
        self.assertIn("maxi(1, presupuesto)", bloque)
        self.assertIn("ARQUETIPOS.ENJAMBRE_PRESUPUESTO_ATAQUES", bloque)
        self.assertIn("mini(", bloque)

    def test_coordinador_no_monta_runtime_ni_consecuencias(self):
        bloque = self.fuente.split("static func nuevo_enjambre(", 1)[1]
        for simbolo in ("Node3D.new", "Partida.", "Jornada.", "SuenoCombate.", "resolver("):
            self.assertNotIn(simbolo, bloque)

    def test_runtime_3d_monta_cuerpos_sin_consecuencias(self):
        bloque = self.arena.split("static func montar_enjambre(", 1)[1].split(
            "static func _posicion_enjambre(", 1
        )[0]
        self.assertIn("CharacterBody3D.new()", bloque)
        self.assertIn("JuicioCombateEscenografia3D.rival_sin_cara", bloque)
        self.assertIn("_montar_aviso_enjambre", bloque)
        for simbolo in (
            "Partida.",
            "Jornada.",
            "SuenoCombate.",
            "determinacion",
            "dano",
            "resolver(",
        ):
            self.assertNotIn(simbolo, bloque)

    def test_contrato_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        if shutil.which(motor) is None:
            self.skipTest(f"{motor} no disponible en este entorno")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 30, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
