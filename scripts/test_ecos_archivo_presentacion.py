import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")
PRESENTACION = ROOT / "godot" / "guion" / "ecos_archivo_presentacion.gd"


class EcosArchivoPresentacionTest(unittest.TestCase):
    def test_contrato_ejecutable_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_ecos_archivo_presentacion.gd",
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
        self.assertGreaterEqual(int(resumen.group(1)), 25, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)

    def test_no_acopla_entrada_fisica_ni_recompensas(self):
        codigo = PRESENTACION.read_text(encoding="utf-8")
        sin_comentarios = "\n".join(
            linea for linea in codigo.splitlines() if not linea.lstrip().startswith("#")
        )
        for termino in (
            "Input.",
            "InputEventKey",
            "KEY_",
            "JOY_BUTTON_",
            "dinero",
            "acciones",
            "veredicto",
            "Jornada.",
            "Sueno.",
            "Espacio3D",
        ):
            self.assertNotIn(termino, sin_comentarios)
        self.assertIn('"salida_disponible": true', codigo)


if __name__ == "__main__":
    unittest.main()
