import json
import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
INTERACTUABLE = ROOT / "godot" / "guion" / "interactuable_3d.gd"
SONIDO = ROOT / "godot" / "guion" / "sonido.gd"
PROCEDENCIA = ROOT / "godot" / "assets" / "procedencia.json"
PRUEBA_GODOT = "pruebas/pruebas_sonido_interacciones.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")
MUESTRAS = (
    "impactMetal_light_000.ogg",
    "impactMetal_light_001.ogg",
    "impactMetal_medium_000.ogg",
    "impactSoft_medium_000.ogg",
    "impactSoft_medium_001.ogg",
)


class SonidoInteraccionesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.interactuable = INTERACTUABLE.read_text(encoding="utf-8")
        cls.sonido = SONIDO.read_text(encoding="utf-8")

    def test_nucleo_suena_sin_conocer_reglas_de_juego(self):
        self.assertIn("var sonido_actual := nombre_sonido()", self.interactuable)
        self.assertIn("Sonido.sonar_en(self, sonido_actual)", self.interactuable)
        self.assertLess(
            self.interactuable.index("Sonido.sonar_en(self, sonido_actual)"),
            self.interactuable.index("activado.emit(actor)"),
        )
        for termino in ("Jornada", "Partida", "Inventario", "dia_app.gd"):
            self.assertNotIn(termino, self.interactuable)

    def test_muestras_nuevas_son_kenney_cc0_con_ficha(self):
        fichas = {
            ficha["ruta"]: ficha
            for ficha in json.loads(PROCEDENCIA.read_text(encoding="utf-8"))["assets"]
        }
        for muestra in MUESTRAS:
            ficha = fichas.get(f"audio/{muestra}")
            self.assertIsNotNone(ficha, muestra)
            self.assertEqual(ficha["licencia"], "CC0-1.0")
            self.assertEqual(ficha["fuente"], "https://kenney.nl/assets/impact-sounds")
            self.assertIn(muestra, self.sonido)

    def test_interacciones_suenan_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
