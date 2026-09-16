import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]


class CorreoPostalTest(unittest.TestCase):
    def test_contrato_de_correo_postal_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_correo_postal.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("22 pasadas, 0 fallos", resultado.stdout)

    def test_integracion_no_abre_economia_paralela(self):
        correo = (ROOT / "godot" / "guion" / "correo_postal.gd").read_text()
        controlador = (ROOT / "godot" / "guion" / "dia_correo_postal_app.gd").read_text()
        escena = (ROOT / "godot" / "escenas" / "dia.tscn").read_text()

        self.assertNotIn("Jornada.gastar(", correo)
        self.assertIn("Inventario.recoger", correo)
        self.assertIn('jornada.get("fase", "")', correo)
        self.assertIn('"fuera_del_portal"', correo)
        self.assertIn('buzon.name = "BuzonPostal"', controlador)
        self.assertIn("dia_correo_postal_app.gd", escena)


if __name__ == "__main__":
    unittest.main()
