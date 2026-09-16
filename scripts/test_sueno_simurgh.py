import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
SEMILLAS = ROOT / "godot" / "guion" / "SemillasOniricas.gd"
SUENO = ROOT / "godot" / "guion" / "sueno_simurgh.gd"
VIGILIA = ROOT / "godot" / "guion" / "simurgh_vigilia.gd"
ESCENA_SUENO = ROOT / "godot" / "escenas" / "sueno_simurgh.tscn"
ESCENA_VIGILIA = ROOT / "godot" / "escenas" / "simurgh_vigilia.tscn"
PRUEBA_GODOT = "res://pruebas/pruebas_simurgh.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SuenoSimurghTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.semillas = SEMILLAS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.escena_sueno = ESCENA_SUENO.read_text(encoding="utf-8")
        cls.escena_vigilia = ESCENA_VIGILIA.read_text(encoding="utf-8")

    def test_semilla_usa_catalogo_comun(self):
        self.assertIn('"simurgh",', self.semillas)
        self.assertIn('ID_MITO := "simurgh"', self.sueno)
        self.assertIn('CLAVE_SEMILLA := "semilla_onirica_simurgh"', self.sueno)
        self.assertIn("SemillasOniricas.familias_activas(estado)", self.sueno)
        self.assertIn("SemillasOniricas.activar_semilla_onirica(", self.sueno)

    def test_vigilia_es_deliberada_y_sin_hud(self):
        self.assertIn("extends Interactuable3D", self.vigilia)
        self.assertIn("INSPECCIONES_MINIMAS := 2", self.vigilia)
        self.assertIn("_girada = true", self.vigilia)
        self.assertIn("SuenoSimurgh.registrar_semilla(", self.vigilia)
        combinado = self.sueno + self.vigilia
        self.assertNotIn("Label.new()", combinado)
        self.assertNotIn("CanvasLayer", combinado)

    def test_capas_comparten_anclas_y_no_escalan_jugador(self):
        self.assertIn('const CAPAS := ["escritorio", "monumental"]', self.sueno)
        self.assertIn('"escritorio": "Pluma"', self.sueno)
        self.assertIn('"monumental": "PasarelaPluma"', self.sueno)
        self.assertIn('"escritorio": "Lampara"', self.sueno)
        self.assertIn('"monumental": "NidoLuminaria"', self.sueno)
        self.assertIn('"escalar_jugador": false', self.sueno)
        self.assertIn('"mover_camara": false', self.sueno)
        self.assertIn('"corte_fundido"', self.sueno)
        self.assertIn('"Retorno"', self.sueno)

    def test_escenas_standalone_apuntan_a_verticales(self):
        self.assertIn('path="res://guion/sueno_simurgh.gd"', self.escena_sueno)
        self.assertIn('[node name="SuenoSimurgh" type="Node3D"]', self.escena_sueno)
        self.assertIn('path="res://guion/simurgh_vigilia.gd"', self.escena_vigilia)
        self.assertIn('[node name="SimurghVigilia" type="Area3D"]', self.escena_vigilia)

    def test_contrato_funciona_en_godot_headless(self):
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
        self.assertGreaterEqual(int(resumen.group(1)), 25, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
