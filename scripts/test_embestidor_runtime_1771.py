import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "godot" / "guion" / "juicio_combate_embestidor_3d.gd"
PRUEBA = "res://pruebas/pruebas_embestidor_runtime_1771.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class EmbestidorRuntime1771Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = RUNTIME.read_text(encoding="utf-8")

    def test_delega_politica_y_congela_rumbo(self):
        self.assertIn("ARQUETIPOS.avanzar(unidad, delta, contexto)", self.fuente)
        self.assertIn('"rumbo_objetivo"', self.fuente)
        self.assertIn('"rumbo_bloqueado"', self.fuente)
        self.assertIn("ARQUETIPO_HOST.direccion_linea(rumbo)", self.fuente)

    def test_expone_eventos_sin_resolver_consecuencias(self):
        for clave in ('"inicio_agresion"', '"inicio_carga"', '"abrir_ventana"'):
            self.assertIn(clave, self.fuente)
        for simbolo in (
            "Partida.",
            "Jornada.",
            "SuenoCombate",
            "resolver_impacto",
            "_terminar(",
            "JUNGIANO",
            "Sonido.sonar",
        ):
            self.assertNotIn(simbolo, self.fuente)

    def test_telegraph_es_geometria_estatica(self):
        self.assertIn("MeshInstance3D.new()", self.fuente)
        self.assertIn('telegraph == "carga_lineal"', self.fuente)
        self.assertNotIn("AnimationPlayer", self.fuente)
        self.assertNotIn("Label", self.fuente)

    def test_contrato_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        if shutil.which(motor) is None:
            self.skipTest(f"{motor} no disponible en este entorno")
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
        self.assertGreaterEqual(int(resumen.group(1)), 18, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
