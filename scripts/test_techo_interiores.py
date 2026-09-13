from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "godot" / "pruebas" / "pruebas_politica_techo.gd"
ESPACIO = ROOT / "godot" / "guion" / "espacio_3d.gd"
CATALOGO = ROOT / "godot" / "guion" / "espacios_catalogo.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class PoliticaTechoTest(unittest.TestCase):
    def test_contrato_ejecutable_en_godot(self):
        proceso = subprocess.run(
            [
                "godot4",
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_politica_techo.gd",
            ],
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
        salida = proceso.stdout + proceso.stderr
        self.assertEqual(proceso.returncode, 0, salida)
        resumen = RESUMEN.search(salida)
        self.assertIsNotNone(resumen, salida)
        self.assertGreaterEqual(int(resumen.group(1)), 6)
        self.assertNotIn("SCRIPT ERROR", salida)
        self.assertNotIn("Parse Error", salida)

    def test_documenta_la_causa_raiz_actual(self):
        motor = ESPACIO.read_text(encoding="utf-8")
        catalogo = CATALOGO.read_text(encoding="utf-8")
        self.assertIn("_techo(", motor)
        calle = catalogo.split("const CALLE :=", 1)[1]
        self.assertIn('"suelo": Vector2(9, 34)', calle)
        self.assertIn('"color_techo"', calle)

    def test_el_corte_no_modifica_constructor_ni_catalogo(self):
        politica = (ROOT / "godot" / "guion" / "politica_techo.gd").read_text(encoding="utf-8")
        self.assertNotIn("EspaciosCatalogo", politica)
        self.assertNotIn("Espacio3D", politica)
        self.assertNotIn("CALLE", politica)


if __name__ == "__main__":
    unittest.main()
