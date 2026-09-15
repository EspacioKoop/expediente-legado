import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ANOMALIA = ROOT / "godot" / "guion" / "anomalia_sueno_3d.gd"
UTILERIA = ROOT / "godot" / "guion" / "sueno_utileria.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_sueno_reactivo_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "pruebas/pruebas_sueno_reactivo.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SuenoReactivoTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.anomalia = ANOMALIA.read_text(encoding="utf-8")
        cls.utileria = UTILERIA.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_controller_hijo_no_sustituye_la_raiz(self):
        self.assertIn('path="res://guion/dia_clima_app.gd" id="1"', self.escena)
        self.assertIn('path="res://guion/dia_sueno_reactivo_app.gd" id="8"', self.escena)
        self.assertIn('[node name="SuenoReactivoController"', self.escena)
        self.assertIn('!= "sueño"', self.controlador)
        self.assertRegex(self.controlador, r"SuenoUtileria\s*\.\s*montar\(")
        self.assertNotIn('== "archivo"', self.controlador)
        self.assertNotIn('== "casa"', self.controlador)
        self.assertNotIn('== "trayecto"', self.controlador)

    def test_utileria_reutiliza_objetos_familiares_sin_assets_nuevos(self):
        for modelo in ('"chairDesk"', '"computerScreen"', '"bookcaseClosed"'):
            self.assertIn(modelo, self.utileria)
        for extension in (".glb", ".fbx", ".png", ".jpg"):
            self.assertNotIn(extension, self.utileria + self.anomalia)
        self.assertIn("Modelos.mueble", self.anomalia)

    def test_colocacion_depende_de_la_planta_real(self):
        self.assertIn("SuenoFormas.de(id)", self.utileria)
        self.assertIn("Planta.a_la_vista", self.utileria)
        self.assertIn("Planta.repartidas", self.utileria)
        self.assertIn("Planta.mas_lejana", self.utileria)
        self.assertIn("Planta.centro_en_metros", self.utileria)
        self.assertNotIn("Sueno.espacio", self.utileria)
        self.assertNotIn("SuenoFormas.FORMAS", self.utileria)

    def test_variacion_es_reproducible_y_no_usa_azar_libre(self):
        self.assertIn("Azar.derivar_texto", self.utileria)
        self.assertIn("[dia]", self.utileria)
        self.assertIn("raiz_azar", self.utileria)
        combinado = self.utileria + self.anomalia + self.controlador
        for termino in ("randomize", "randi(", "randf(", "RandomNumberGenerator.new"):
            self.assertNotIn(termino, combinado)

    def test_microinteraccion_es_semantica_y_visible(self):
        self.assertIn("extends Interactuable3D", self.anomalia)
        self.assertIn("verbo = Verbo.EXAMINAR", self.anomalia)
        self.assertIn("CollisionShape3D.new()", self.anomalia)
        self.assertIn("OmniLight3D.new()", self.anomalia)
        self.assertIn("_visual.scale =", self.anomalia)
        self.assertIn("_visual.rotation_degrees =", self.anomalia)
        self.assertIn("_luz.visible = _reactiva", self.anomalia)
        self.assertNotIn("Tween", self.anomalia)
        self.assertNotIn("create_tween", self.anomalia)
        self.assertNotIn("InputEventKey", self.anomalia + self.controlador)
        self.assertNotIn("KEY_", self.anomalia + self.controlador)

    def test_no_interfiere_con_progreso_ni_persistencia(self):
        combinado = self.utileria + self.anomalia + self.controlador
        for termino in (
            "SuenoObjetivos",
            "completar(",
            "recordar(",
            "Partida.new",
            "Jornada.",
            "guardar(",
            "FileAccess",
            "pistas_descubiertas",
            "veredictos",
        ):
            self.assertNotIn(termino, combinado)
        self.assertNotRegex(self.controlador, r"jornada\s*\[")

    def test_corte_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()

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
        self.assertGreaterEqual(int(resumen.group(1)), 180, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
