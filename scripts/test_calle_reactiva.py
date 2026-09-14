import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
CALLE = ROOT / "godot" / "guion" / "dia_calle_app.gd"
PERSIANA = ROOT / "godot" / "guion" / "persiana_calle_interactiva_3d.gd"
PRUEBA_GODOT = "pruebas/pruebas_persiana_calle.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class CalleReactivaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.calle = CALLE.read_text(encoding="utf-8")
        cls.persiana = PERSIANA.read_text(encoding="utf-8")

    def test_persiana_se_monta_solo_en_trayecto(self):
        self.assertIn('if fase == "trayecto":', self.calle)
        self.assertIn("_montar_persiana_calle()", self.calle)
        self.assertIn("PersianaCalleInteractiva3D.new()", self.calle)
        self.assertIn('persiana.name = "PersianaCalleInteractuable"', self.calle)
        self.assertIn("Vector3(5.28, 1.22, -10.0)", self.calle)

    def test_reutiliza_ventana_existente_y_no_bloquea_portal(self):
        self.assertIn("Vector3(5.42, 1.85, -10.0)", self.calle)
        self.assertIn("Vector3(0, 2.95, 15.8)", self.calle)
        self.assertNotIn('persiana.position = Vector3(0,', self.calle)

    def test_interaccion_es_semantica_y_feedback_fisico(self):
        self.assertIn('extends "res://guion/interactuable_3d.gd"', self.persiana)
        self.assertIn("verbo = Verbo.ABRIR", self.persiana)
        self.assertIn("Verbo.CERRAR", self.persiana)
        self.assertIn('nombre_objeto = "persiana"', self.persiana)
        self.assertIn("CollisionShape3D.new()", self.persiana)
        self.assertIn('hoja.name = "HojaPersianaCalle"', self.persiana)
        self.assertIn("_hoja.position = POS_ABIERTA", self.persiana)
        self.assertNotIn("Tween", self.persiana)

    def test_persiana_no_toca_estado_de_juego_ni_assets(self):
        for termino in (
            "Partida",
            "Jornada",
            "pistas_descubiertas",
            "inventario",
            "guardar(",
            "load(",
            "preload(",
            ".glb",
            ".png",
        ):
            self.assertNotIn(termino, self.persiana)

    def test_persiana_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importacion = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--editor",
                "--import",
                "--quit",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        self.assertEqual(importacion.returncode, 0, importacion.stdout)

        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 13, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
