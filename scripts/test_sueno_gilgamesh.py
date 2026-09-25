import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
SUENO = ROOT / "godot" / "guion" / "sueno_gilgamesh.gd"
VIGILIA = ROOT / "godot" / "guion" / "gilgamesh_vigilia.gd"
ESCENA_SUENO = ROOT / "godot" / "escenas" / "sueno_gilgamesh.tscn"
ESCENA_VIGILIA = ROOT / "godot" / "escenas" / "gilgamesh_vigilia.tscn"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_gilgamesh.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SuenoGilgameshTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.escena_sueno = ESCENA_SUENO.read_text(encoding="utf-8")
        cls.escena_vigilia = ESCENA_VIGILIA.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_usa_semilla_comun_y_no_entrada_incondicional(self):
        self.assertIn('ID_MITO := "gilgamesh"', self.sueno)
        self.assertIn('CLAVE_SEMILLA := "semilla_onirica_gilgamesh"', self.sueno)
        self.assertIn("SemillasOniricas.familias_activas(estado)", self.sueno)
        self.assertRegex(
            self.sueno,
            r"SemillasOniricas\s*\.\s*activar_semilla_onirica\s*\(",
        )
        self.assertIn('FUENTE_VIGILIA := "libro:arqueologia_uruk_98"', self.sueno)

    def test_vigilia_exige_interaccion_activa(self):
        self.assertIn("extends Interactuable3D", self.vigilia)
        self.assertIn("PAGINAS_MINIMAS := 3", self.vigilia)
        self.assertIn("func examinar()", self.vigilia)
        self.assertIn("_tablilla_observada = true", self.vigilia)
        self.assertRegex(
            self.vigilia,
            r"SuenoGilgamesh\s*\.\s*registrar_semilla\s*\(",
        )
        self.assertIn("activado.connect(_al_examinar)", self.vigilia)

    def test_puzzle_declara_cuatro_parejas_y_reversion(self):
        self.assertIn('"fragmento_puerta": "ancla_puerta"', self.sueno)
        self.assertIn('"fragmento_sello": "ancla_sello"', self.sueno)
        self.assertIn('"fragmento_ola": "ancla_ola"', self.sueno)
        self.assertIn('"fragmento_archivo": "ancla_archivo"', self.sueno)
        self.assertIn('"revertir": true', self.sueno)
        self.assertIn("var siguiente := estado.duplicate(true)", self.sueno)

    def test_transformacion_imposible_y_reduccion_movimiento(self):
        self.assertIn(
            'TRANSFORMACION_FINAL := "muralla_archivo_continua_por_techo"',
            self.sueno,
        )
        self.assertIn('"corte_fundido"', self.sueno)
        self.assertIn('"interpolacion_arquitectura"', self.sueno)
        self.assertIn('"sacudida_camara": false', self.sueno)
        self.assertIn('"desplazar_camara": false', self.sueno)
        self.assertIn('"MurallaArchivoTecho"', self.sueno)
        self.assertIn('"RutaFinal"', self.sueno)
        self.assertIn('"HitosUruk"', self.sueno)
        self.assertIn('"ZiguratArchivo"', self.sueno)
        self.assertIn('"PuertaMonumentalArchivo"', self.sueno)
        self.assertIn('"InundacionVertical"', self.sueno)
        self.assertIn('"SellosCelestes"', self.sueno)

    def test_no_depende_de_hud_ni_assets_externos(self):
        combinado = self.sueno + self.vigilia
        self.assertNotIn("Label.new()", combinado)
        self.assertNotIn("RichTextLabel", combinado)
        self.assertNotIn("CanvasLayer", combinado)
        self.assertNotIn(".png", combinado)
        self.assertNotIn(".jpg", combinado)
        self.assertNotIn(".glb", combinado)
        self.assertNotIn("http://", combinado)
        self.assertNotIn("https://", combinado)

    def test_escenas_standalone_apuntan_a_sus_verticales(self):
        self.assertIn('path="res://guion/sueno_gilgamesh.gd"', self.escena_sueno)
        self.assertIn('[node name="SuenoGilgamesh" type="Node3D"]', self.escena_sueno)
        self.assertIn('path="res://guion/gilgamesh_vigilia.gd"', self.escena_vigilia)
        self.assertIn('[node name="GilgameshVigilia" type="Area3D"]', self.escena_vigilia)

    def test_vigilia_alcanzable_desde_casa_real(self):
        self.assertIn('elif fase == "casa":', self.dia)
        self.assertIn("CasaUtileria.montar(_mundo)", self.dia)
        self.assertIn("_montar_gilgamesh_vigilia()", self.dia)
        self.assertIn("GilgameshVigilia.new()", self.dia)
        self.assertIn("libro.configurar(jornada)", self.dia)

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
