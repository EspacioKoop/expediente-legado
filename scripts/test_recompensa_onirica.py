import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
RECOMPENSA = ROOT / "godot" / "guion" / "recompensa_onirica.gd"
DIA_GATO = ROOT / "godot" / "guion" / "dia_gato_app.gd"
PRUEBA = "pruebas/pruebas_recompensa_onirica.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class RecompensaOniricaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.recompensa = RECOMPENSA.read_text(encoding="utf-8")
        cls.dia = DIA_GATO.read_text(encoding="utf-8")

    def test_contrato_no_economico_y_uso_semantico(self):
        self.assertIn('const ID := "cuna_imposible"', self.recompensa)
        self.assertIn('const USO := "forzar"', self.recompensa)
        self.assertIn('"origen": "sueno"', self.recompensa)
        self.assertIn('"vendible": false', self.recompensa)
        self.assertIn('"precio": 0', self.recompensa)
        self.assertIn('"usos": [USO]', self.recompensa)
        self.assertNotIn('jornada["dinero"]', self.recompensa)
        self.assertNotIn('jornada["acciones"]', self.recompensa)

    def test_puzzle_valido_materializa_en_partida_existente(self):
        bloque = self.dia.split("func _al_resultado_puzzle_onirico", 1)[1].split(
            "func _abrir_expediente", 1
        )[0]
        self.assertIn("PistaOnirica.resolver(caso, resultado)", bloque)
        self.assertIn("RecompensaOnirica.conceder(partida.estado)", bloque)
        self.assertIn("progreso_nuevo or pista_nueva or objeto_nuevo", bloque)
        self.assertNotIn("Partida.nueva()", bloque)

    def test_vertical_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA,
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
        self.assertGreaterEqual(int(resumen.group(1)), 24, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
