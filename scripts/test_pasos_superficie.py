import json
import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
SONIDO = ROOT / "godot" / "guion" / "sonido.gd"
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
PROCEDENCIA = ROOT / "godot" / "assets" / "procedencia.json"
PRUEBA_GODOT = "pruebas/pruebas_pasos_superficie.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class PasosSuperficieTest(unittest.TestCase):
    def test_tomas_nuevas_son_kenney_cc0_con_ficha(self):
        fichas = {
            ficha["ruta"]: ficha
            for ficha in json.loads(PROCEDENCIA.read_text(encoding="utf-8"))["assets"]
        }
        nombres = re.findall(r'"(footstep_[a-z]+_\d{3}\.ogg|impactWood_heavy_\d{3}\.ogg)"', SONIDO.read_text(encoding="utf-8"))
        self.assertGreaterEqual(len(set(nombres)), 16)
        for nombre in set(nombres):
            ficha = fichas.get(f"audio/{nombre}")
            self.assertIsNotNone(ficha, nombre)
            self.assertEqual(ficha["licencia"], "CC0-1.0")
            self.assertEqual(ficha["fuente"], "https://kenney.nl/assets/impact-sounds")

    def test_careo_deja_de_ser_procedural(self):
        texto = SONIDO.read_text(encoding="utf-8")
        self.assertNotIn("AudioStreamWAV", texto)
        self.assertNotIn("FRECUENCIA_IMPACTO", texto)

    def test_dia_elige_el_suelo_pisado(self):
        texto = DIA.read_text(encoding="utf-8")
        self.assertIn("Sonido.paso_sobre(_suelo_pisado())", texto)

    def test_pasos_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIsNotNone(RESUMEN_GODOT.search(resultado.stdout), resultado.stdout)


if __name__ == "__main__":
    unittest.main()
