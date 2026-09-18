import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
CONTROLADOR = ROOT / "godot" / "guion" / "sueno_objetivos_legibilidad.gd"


class SuenoObjetivosLegibilidadTest(unittest.TestCase):
    def test_controller_se_monta_sin_tocar_regla_de_progreso(self):
        escena = ESCENA.read_text(encoding="utf-8")
        codigo = CONTROLADOR.read_text(encoding="utf-8")

        self.assertIn(
            'path="res://guion/sueno_objetivos_legibilidad.gd"',
            escena,
        )
        self.assertIn('name="ObjetivosLegibilidadController"', escena)
        self.assertIn('find_children("ObjetivoSueno_*", "Area3D"', codigo)
        self.assertIn("OmniLight3D.new()", codigo)
        self.assertIn("luz.visible = false", codigo)

        self.assertNotIn("SuenoObjetivos.completar", codigo)
        self.assertNotIn("_guardar_o_avisar", codigo)
        self.assertNotIn("Label3D", codigo)
        self.assertNotIn("Control.new()", codigo)
        self.assertNotIn('destino = "salida"', codigo)

    def test_contrato_ejecutable_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_sueno_objetivos_legibilidad.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("12 pasadas, 0 fallos", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
