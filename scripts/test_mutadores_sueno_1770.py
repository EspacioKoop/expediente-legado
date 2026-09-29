import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MUTADORES = ROOT / "godot" / "guion" / "mutadores_sueno.gd"
PRUEBA = "res://pruebas/pruebas_mutadores_sueno_1770.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class MutadoresSueno1770Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = MUTADORES.read_text(encoding="utf-8")

    def test_catalogo_acotado_y_derivacion_existente(self):
        for mutador in ("humedad", "apagones", "repeticion", "desfase"):
            self.assertIn(f'"{mutador}"', self.fuente)
        self.assertIn("Clima.estado(dia)", self.fuente)
        self.assertIn('Azar.derivar(raiz, "sueno"', self.fuente)
        self.assertIn('jornada.get("leido_hoy"', self.fuente)
        self.assertIn("Estres.CAMPO_JORNADA", self.fuente)

    def test_no_introduce_azar_ni_estado_paralelo(self):
        self.assertNotIn("RandomNumberGenerator.new()", self.fuente)
        self.assertNotRegex(self.fuente, r"\brand[if]\s*\(")
        self.assertNotRegex(self.fuente, r'jornada\s*\[[^\]]+\]\s*=')
        self.assertIn('"afecta_navegacion": false', self.fuente)
        self.assertIn('"afecta_objetivo": false', self.fuente)

    def test_no_hardcodea_familias_oniricas(self):
        for familia in ("mari", "minotauro", "gilgamesh", "duat", "aquiles"):
            self.assertNotIn(familia, self.fuente.lower())

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
        self.assertGreaterEqual(int(resumen.group(1)), 35, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
