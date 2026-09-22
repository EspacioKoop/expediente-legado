import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
REFLECTOR = ROOT / "godot" / "guion" / "aquiles_reflector.gd"
SELLO = ROOT / "godot" / "guion" / "aquiles_sello.gd"
PUZZLE = ROOT / "godot" / "guion" / "sueno_aquiles_alineacion.gd"
ESCENA = ROOT / "godot" / "escenas" / "sueno_aquiles_alineacion.tscn"
PRUEBA_GODOT = "res://pruebas/pruebas_aquiles_alineacion.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class AquilesAlineacionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reflector = REFLECTOR.read_text(encoding="utf-8")
        cls.sello = SELLO.read_text(encoding="utf-8")
        cls.puzzle = PUZZLE.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_reflector_exige_giros_deliberados(self):
        self.assertIn("extends Interactuable3D", self.reflector)
        self.assertIn("PASO_GRADOS := -15.0", self.reflector)
        self.assertIn("ANGULO_OBJETIVO := -45.0", self.reflector)
        self.assertIn("func esta_alineado()", self.reflector)
        self.assertIn("func girar_paso()", self.reflector)
        self.assertIn("alineacion_cambiada.emit", self.reflector)
        self.assertIn("wrapf(_angulo + PASO_GRADOS, -180.0, 180.0)", self.reflector)

    def test_sello_nace_bloqueado_y_es_no_combate(self):
        self.assertIn("extends Interactuable3D", self.sello)
        self.assertIn("habilitado = false", self.sello)
        self.assertIn("signal sellado", self.sello)
        self.assertNotIn('"atacar"', self.sello)
        self.assertNotIn('"golpear"', self.sello)
        self.assertNotIn('"disparar"', self.sello)

    def test_puzzle_conecta_alineacion_talon_y_sellado(self):
        self.assertIn("extends SuenoAquiles", self.puzzle)
        self.assertIn("AquilesReflector.new()", self.puzzle)
        self.assertIn("AquilesSello.new()", self.puzzle)
        self.assertIn("aplicar_lectura_espacial(false, alineado)", self.puzzle)
        self.assertIn('aplicar_resolucion("sellar", reduccion_movimiento)', self.puzzle)
        self.assertIn("revelada and not _resuelta", self.puzzle)

    def test_escena_standalone_usa_vertical_de_alineacion(self):
        self.assertIn('path="res://guion/sueno_aquiles_alineacion.gd"', self.escena)
        self.assertIn('[node name="SuenoAquilesAlineacion" type="Node3D"]', self.escena)

    def test_corte_no_vendoriza_binarios_sin_procedencia(self):
        combinado = self.reflector + self.sello + self.puzzle + self.escena
        for extension in (".png", ".jpg", ".glb", ".obj"):
            self.assertNotIn(extension, combinado)

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
            timeout=45,
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
