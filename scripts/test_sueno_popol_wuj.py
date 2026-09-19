import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
SEMILLAS = ROOT / "godot" / "guion" / "SemillasOniricas.gd"
SUENO = ROOT / "godot" / "guion" / "sueno_popol_wuj.gd"
VIGILIA = ROOT / "godot" / "guion" / "popol_wuj_vigilia.gd"
CIELOS = ROOT / "godot" / "guion" / "sueno_cielos.gd"
ESCENA_SUENO = ROOT / "godot" / "escenas" / "sueno_popol_wuj.tscn"
ESCENA_VIGILIA = ROOT / "godot" / "escenas" / "popol_wuj_vigilia.tscn"
REFERENCIAS = ROOT / "docs" / "assets" / "popol-wuj-referencias.md"
PRUEBA_GODOT = "res://pruebas/pruebas_popol_wuj.gd"
RESUMEN_GODOT = re.compile(r"(\\d+) pasadas, 0 fallos")


class SuenoPopolWujTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.semillas = SEMILLAS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.cielos = CIELOS.read_text(encoding="utf-8")
        cls.escena_sueno = ESCENA_SUENO.read_text(encoding="utf-8")
        cls.escena_vigilia = ESCENA_VIGILIA.read_text(encoding="utf-8")
        cls.referencias = REFERENCIAS.read_text(encoding="utf-8")

    def test_semilla_usa_catalogo_comun(self):
        self.assertIn('"popol_wuj",', self.semillas)
        self.assertIn('ID_MITO := "popol_wuj"', self.sueno)
        self.assertIn('CLAVE_SEMILLA := "semilla_onirica_popol_wuj"', self.sueno)
        self.assertIn("SemillasOniricas.familias_activas(estado)", self.sueno)
        self.assertRegex(
            self.sueno,
            r"SemillasOniricas\s*\.\s*activar_semilla_onirica\s*\(",
        )

    def test_vigilia_es_deliberada_y_no_es_trivia(self):
        self.assertIn("extends Interactuable3D", self.vigilia)
        self.assertIn("INSPECCIONES_MINIMAS := 2", self.vigilia)
        self.assertIn("_pareja_comparada = true", self.vigilia)
        self.assertRegex(
            self.vigilia,
            r"SuenoPopolWuj\s*\.\s*registrar_semilla\s*\(",
        )
        combinado = self.sueno + self.vigilia
        self.assertNotIn("Label.new()", combinado)
        self.assertNotIn("CanvasLayer", combinado)
        self.assertNotIn("LineEdit.new()", combinado)

    def test_dos_pares_y_eco_causal(self):
        self.assertIn("const ARCHIVO_OESTE", self.sueno)
        self.assertIn("const ARCHIVO_ESTE", self.sueno)
        self.assertIn("const TELEFONO_OESTE", self.sueno)
        self.assertIn("const TELEFONO_ESTE", self.sueno)
        self.assertIn("const PAREJAS :=", self.sueno)
        self.assertIn('"eco_destino": pareja', self.sueno)
        self.assertIn('"eco_util": true', self.sueno)
        self.assertIn("parejas_equivalentes()", self.sueno)
        self.assertIn("puerta_abierta()", self.sueno)
        self.assertIn('"Retorno"', self.sueno)

    def test_familia_tiene_perfil_en_gramatica_global_de_cielos(self):
        self.assertIn('"popol_wuj":', self.cielos)
        self.assertIn("No pretende reconstruir Xibalbá", self.cielos)

    def test_reduccion_movimiento_no_cambia_regla(self):
        self.assertIn('"corte_fundido" if reduccion_movimiento', self.sueno)
        self.assertIn('"duracion": 0.0 if reduccion_movimiento', self.sueno)
        self.assertIn('"desplazar_camara": false', self.sueno)
        self.assertIn('"eco_visual": true', self.sueno)
        self.assertIn('"eco_sonoro": true', self.sueno)

    def test_fuentes_identifican_popol_wuj_como_kiche(self):
        texto = self.referencias.lower()
        self.assertIn("k’iche’", self.referencias)
        self.assertIn("smithsonian", texto)
        self.assertIn("library of congress", texto)
        self.assertIn("xibalbá", texto)
        self.assertIn("no reconstruye", texto)
        self.assertIn("procedural", texto)

    def test_escenas_standalone_apuntan_a_verticales(self):
        self.assertIn('path="res://guion/sueno_popol_wuj.gd"', self.escena_sueno)
        self.assertIn('[node name="SuenoPopolWuj" type="Node3D"]', self.escena_sueno)
        self.assertIn('path="res://guion/popol_wuj_vigilia.gd"', self.escena_vigilia)
        self.assertIn('[node name="PopolWujVigilia" type="Area3D"]', self.escena_vigilia)

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
        self.assertGreaterEqual(int(resumen.group(1)), 45, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
