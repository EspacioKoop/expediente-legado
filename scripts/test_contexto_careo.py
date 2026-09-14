import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")
CAPA = ROOT / "godot" / "guion" / "careo_contexto_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "careo.tscn"


class ContextoCareoTest(unittest.TestCase):
    def test_contrato_ejecutable_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_contexto_careo.gd",
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
        self.assertGreaterEqual(int(resumen.group(1)), 8, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)

    def test_la_escena_activa_la_capa_de_contexto(self):
        escena = ESCENA.read_text(encoding="utf-8")
        self.assertIn('path="res://guion/careo_contexto_app.gd"', escena)

    def test_la_capa_no_modifica_reglas_del_duelo(self):
        codigo = CAPA.read_text(encoding="utf-8")
        self.assertIn("ContextoCareo", codigo)
        self.assertIn("de_folio(", codigo)
        self.assertIn("super._empezar_duelo()", codigo)
        for prohibido in [
            "Combate.",
            "cargas =",
            "vida_jugador",
            "vida_rival",
            "veredictos",
            "terminado.emit",
        ]:
            self.assertNotIn(prohibido, codigo)


if __name__ == "__main__":
    unittest.main()
