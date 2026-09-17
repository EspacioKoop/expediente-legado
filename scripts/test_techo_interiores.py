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
        self.assertGreaterEqual(int(resumen.group(1)), 8)
        self.assertNotIn("SCRIPT ERROR", salida)
        self.assertNotIn("Parse Error", salida)

    def test_constructor_respeta_la_politica_de_techo(self):
        motor = ESPACIO.read_text(encoding="utf-8")
        self.assertGreaterEqual(motor.count("PoliticaTecho.debe_tener(espacio)"), 2)
        self.assertIn("if con_techo:", motor)

    def test_calle_es_exterior_y_los_interiores_conservan_el_default(self):
        catalogo = CATALOGO.read_text(encoding="utf-8")
        calle = catalogo.split("const CALLE :=", 1)[1].split("const CASA :=", 1)[0]
        oficina = catalogo.split("const OFICINA :=", 1)[1].split("const CALLE :=", 1)[0]
        casa = catalogo.split("const CASA :=", 1)[1].split("const POR_FASE :=", 1)[0]
        self.assertIn('"suelo": Vector2(9, 34)', calle)
        self.assertIn('"techo": false', calle)
        self.assertNotIn('"color_techo"', calle)
        self.assertNotIn('"techo": false', oficina)
        self.assertNotIn('"techo": false', casa)


if __name__ == "__main__":
    unittest.main()
