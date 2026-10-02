import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
POLITICA = ROOT / "godot" / "guion" / "juicio_combate_obstaculo_1772.gd"
PRUEBA = "res://pruebas/pruebas_combate_obstaculo_1772.gd"
RESUMEN = re.compile(r"combate_obstaculo_1772: (\d+) pasadas, 0 fallos")


class CombateObstaculo1772Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = POLITICA.read_text(encoding="utf-8")

    def test_politica_es_pura_y_no_crea_otra_navegacion(self):
        self.assertIn("class_name JuicioCombateObstaculo1772", self.fuente)
        for prohibido in (
            "extends Node",
            "Node3D",
            "CharacterBody3D",
            "PhysicsDirectSpaceState3D",
            "NavigationServer",
            "NavigationAgent",
            "Partida.",
            "Jornada.",
            "SuenoCombate",
            "Input.",
        ):
            self.assertNotIn(prohibido, self.fuente)

    def test_contrato_expone_directo_rodeo_y_espera(self):
        self.assertIn('"directo"', self.fuente)
        self.assertIn('"rodear"', self.fuente)
        self.assertIn('"esperar"', self.fuente)
        self.assertIn('"bloqueado_directo"', self.fuente)
        self.assertIn("segmento_bloqueado(", self.fuente)
        self.assertIn("MARGEN_SEGURIDAD := 0.28", self.fuente)

    def test_semilla_decide_lado_sin_rng(self):
        self.assertIn("absi(semilla) % 2", self.fuente)
        self.assertNotIn("RandomNumberGenerator", self.fuente)
        self.assertNotIn("randi", self.fuente)
        self.assertNotIn("randf", self.fuente)

    def test_regresion_godot(self):
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
        self.assertGreaterEqual(int(resumen.group(1)), 15, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
