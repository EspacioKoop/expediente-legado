import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
DIA_GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"


class GatoAsistenteEscritorioTest(unittest.TestCase):
    def test_prometeo_se_monta_dentro_del_visor(self):
        fuente = DIA_GATO.read_text(encoding="utf-8")
        self.assertIn('var visor := _pantalla.get_node_or_null("Visor") as Control', fuente)
        self.assertIn("visor.add_child(conjunto)", fuente)
        self.assertNotIn("_pantalla.add_child(conjunto)", fuente)

    def test_adopcion_os98_conserva_visibilidad_del_asistente(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_gato_asistente_escritorio.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("6 pasadas, 0 fallos", resultado.stdout)
        self.assertNotIn("ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
