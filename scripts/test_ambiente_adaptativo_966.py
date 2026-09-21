import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
AMBIENTE = ROOT / "godot" / "guion" / "ambiente.gd"
PRUEBA_GODOT = "pruebas/pruebas_ambiente_adaptativo_966.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class AmbienteAdaptativo966Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = AMBIENTE.read_text(encoding="utf-8")

    def test_no_crea_fuentes_de_estado_paralelas(self):
        for termino in (
            "Jornada.",
            "Partida.",
            "Time.get_",
            "DateTime",
            "estres_global",
            "meticulosidad_global",
        ):
            self.assertNotIn(termino, self.source)

    def test_contrato_adaptativo_es_opt_in_y_discretizado(self):
        self.assertIn("static func perfil_adaptativo(", self.source)
        self.assertIn("static func stream_adaptativo(", self.source)
        self.assertIn("static func _nivel(", self.source)
        self.assertIn('contexto.has("hora")', self.source)
        self.assertIn('contexto.has("estres")', self.source)
        self.assertIn('contexto.has("meticulosidad")', self.source)
        self.assertIn('"vigilia_fase"', self.source)

    def test_comportamiento_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20)


if __name__ == "__main__":
    unittest.main()
