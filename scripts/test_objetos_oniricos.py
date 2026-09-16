import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")
DRESSING = ROOT / "godot" / "guion" / "dia_dressing_cc0_app.gd"
REACTIVO = ROOT / "godot" / "guion" / "dia_sueno_reactivo_app.gd"


class ObjetosOniricosTest(unittest.TestCase):
    def test_contrato_ejecutable_en_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                "pruebas/pruebas_objetos_oniricos.gd",
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
        self.assertGreaterEqual(int(resumen.group(1)), 14, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)

    def test_vigilia_registra_solo_familias_catalogadas(self):
        codigo = DRESSING.read_text(encoding="utf-8")
        self.assertRegex(codigo, r'"monitor CRT",\s*"monitor"')
        self.assertRegex(codigo, r'"silla",\s*"silla"')
        self.assertIn('"archivador vintage", "archivador"', codigo)
        self.assertIn("ObjetosOniricos.registrar(dia.jornada, objeto_id)", codigo)
        self.assertIn('dia._guardar_o_avisar("")', codigo)

    def test_sueno_consume_memoria_del_mismo_dia(self):
        codigo = REACTIVO.read_text(encoding="utf-8")
        self.assertRegex(
            codigo,
            r"SuenoUtileria\s*\.\s*montar\([\s\S]*?ObjetosOniricos\.del_dia\(dia\.jornada\)",
        )


if __name__ == "__main__":
    unittest.main()
