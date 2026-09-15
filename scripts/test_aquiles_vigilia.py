import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
VIGILIA = ROOT / "godot" / "guion" / "aquiles_vigilia.gd"
SUENO = ROOT / "godot" / "guion" / "sueno_aquiles.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_aquiles_vigilia_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "aquiles_vigilia.tscn"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "res://pruebas/pruebas_aquiles_vigilia.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class AquilesVigiliaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_usa_contrato_comun_de_semillas(self):
        self.assertIn('ID_MITO := "aquiles"', self.sueno)
        self.assertIn("SemillasOniricas.familias_activas(estado)", self.sueno)
        self.assertIn("SemillasOniricas", self.sueno)
        self.assertIn("activar_semilla_onirica(", self.sueno)
        self.assertIn('FUENTE_VIGILIA := "estampa:bautismo_aquiles_cc0"', self.sueno)

    def test_la_estampa_exige_manipulacion_y_observacion(self):
        self.assertIn("extends Interactuable3D", self.vigilia)
        self.assertIn("GIRO_MINIMO_OBSERVACION", self.vigilia)
        self.assertIn("func observar_talon()", self.vigilia)
        self.assertIn("SuenoAquiles", self.vigilia)
        self.assertIn("registrar_semilla(", self.vigilia)
        self.assertIn("activado.connect(_al_examinar)", self.vigilia)

    def test_feedback_es_diegetico_y_sin_hud(self):
        self.assertIn('"DetalleTalon"', self.vigilia)
        self.assertIn("material.emission_enabled = _activada", self.vigilia)
        self.assertNotIn("Label.new()", self.vigilia)
        self.assertNotIn("RichTextLabel", self.vigilia)
        self.assertNotIn("CanvasLayer", self.vigilia)

    def test_no_vendoriza_binarios_antes_de_procedencia(self):
        combinado = self.vigilia + self.escena
        self.assertNotIn("load(", combinado)
        self.assertNotIn("preload(", combinado)
        self.assertNotIn(".png", combinado)
        self.assertNotIn(".jpg", combinado)
        self.assertNotIn(".glb", combinado)

    def test_escena_standalone_usa_la_contraparte(self):
        self.assertIn('path="res://guion/aquiles_vigilia.gd"', self.escena)
        self.assertIn('[node name="AquilesVigilia" type="Area3D"]', self.escena)

    def test_vigilia_alcanzable_desde_casa_real(self):
        self.assertIn('String(dia.jornada.get("fase", "")) != "casa"', self.controller)
        self.assertIn("AquilesVigilia.new()", self.controller)
        self.assertIn("estampa.configurar(jornada)", self.controller)
        self.assertIn('mundo.get_node_or_null("AquilesVigiliaCasa")', self.controller)
        self.assertIn(
            'path="res://guion/dia_aquiles_vigilia_app.gd"',
            self.dia,
        )
        self.assertIn('[node name="AquilesVigiliaController" type="Node" parent="."]', self.dia)

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
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
