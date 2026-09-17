import os
from pathlib import Path
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CONTROLADOR = ROOT / "godot" / "guion" / "dia_contaminacion_gato_app.gd"
POLITICA = ROOT / "godot" / "guion" / "gato_reaccion_contextual.gd"


class GatoReaccionContextualTest(unittest.TestCase):
    def test_controller_reutiliza_estado_real_sin_convertirse_en_gps(self):
        controlador = CONTROLADOR.read_text(encoding="utf-8")
        politica = POLITICA.read_text(encoding="utf-8")

        self.assertIn('controlador.has_method("_contexto_os98")', controlador)
        self.assertIn("ContaminacionOs98.FASE_CONTAMINACION_CRUZADA", controlador)
        self.assertIn("AnomaliaSueno3D", controlador)
        self.assertIn("GatoReaccionContextual.decidir", controlador)
        self.assertIn(".presentar_estado(", controlador)
        self.assertIn('tr("GATO_SIGA_DESCUBRIMIENTO")', controlador)

        for prohibido in (
            "_orientar_gato_guia",
            "_salida_guia",
            "_objetivos_espacio",
            "PistaOnirica",
            "establecer_estado_local",
            "RandomNumberGenerator",
        ):
            self.assertNotIn(prohibido, controlador)

        self.assertNotIn("Vector3", politica)
        self.assertNotIn("Partida", politica)
        self.assertNotIn("SuenoObjetivos", politica)
        self.assertNotIn("PistaOnirica", politica)

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
                "pruebas/pruebas_gato_reaccion_contextual.gd",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn("10 pasadas, 0 fallos", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
