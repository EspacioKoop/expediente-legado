import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
DIA_GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"
ECO = ROOT / "godot" / "guion" / "gato_eco_sueno.gd"


class GatoEcoSuenoTest(unittest.TestCase):
    def test_integracion_casa_sueno_no_toca_objetivos(self):
        dia = DIA_GATO.read_text(encoding="utf-8")
        eco = ECO.read_text(encoding="utf-8")

        self.assertIn("GatoEcoSueno.registrar", dia)
        self.assertIn("super._dar_de_comer()", dia)
        self.assertIn("hambre_antes > 0 and hambre_despues == 0", dia)
        self.assertIn("var eco := GatoEcoSueno.efecto", dia)
        self.assertIn('_gato_guia.presentar_estado(String(eco.get("estado", "parado")))', dia)
        self.assertIn("_orientar_gato_guia()", dia)

        self.assertNotIn("SuenoObjetivos", eco)
        self.assertNotIn("PistaOnirica", eco)
        self.assertNotIn("Partida", eco)
        self.assertNotIn("afinidad", eco.lower())

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
                "pruebas/pruebas_gato_eco_sueno.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("16 pasadas, 0 fallos", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
