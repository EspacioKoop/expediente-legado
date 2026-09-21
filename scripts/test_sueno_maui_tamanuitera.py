import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
SEMILLAS = ROOT / "godot" / "guion" / "SemillasOniricas.gd"
SUENO = ROOT / "godot" / "guion" / "sueno_maui_tamanuitera.gd"
VIGILIA = ROOT / "godot" / "guion" / "maui_tamanuitera_vigilia.gd"
ESCENA_SUENO = ROOT / "godot" / "escenas" / "sueno_maui_tamanuitera.tscn"
ESCENA_VIGILIA = ROOT / "godot" / "escenas" / "maui_tamanuitera_vigilia.tscn"
REFERENCIAS = ROOT / "docs" / "assets" / "maui-tamanuitera-referencias.md"
CONTROLLER = ROOT / "godot" / "guion" / "dia_maui_tamanuitera_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "res://pruebas/pruebas_maui_tamanuitera.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SuenoMauiTamanuiteraTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.semillas = SEMILLAS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.escena_sueno = ESCENA_SUENO.read_text(encoding="utf-8")
        cls.escena_vigilia = ESCENA_VIGILIA.read_text(encoding="utf-8")
        cls.referencias = REFERENCIAS.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_semilla_usa_catalogo_comun(self):
        self.assertIn('"maui_tamanuitera",', self.semillas)
        self.assertIn('ID_MITO := "maui_tamanuitera"', self.sueno)
        self.assertIn(
            'CLAVE_SEMILLA := "semilla_onirica_maui_tamanuitera"', self.sueno
        )
        self.assertIn("SemillasOniricas.familias_activas(estado)", self.sueno)
        self.assertRegex(
            self.sueno,
            r"SemillasOniricas\s*\.\s*activar_semilla_onirica\s*\(",
        )

    def test_vigilia_es_libro_deliberado_y_sin_hud(self):
        self.assertIn("extends Interactuable3D", self.vigilia)
        self.assertIn("LECTURAS_MINIMAS := 2", self.vigilia)
        self.assertIn("_cerrado = true", self.vigilia)
        self.assertIn('nombre_objeto = "libro ilustrado"', self.vigilia)
        self.assertRegex(
            self.vigilia,
            r"SuenoMauiTamanuitera\s*\.\s*registrar_semilla\s*\(",
        )
        combinado = self.sueno + self.vigilia
        self.assertNotIn("Label.new()", combinado)
        self.assertNotIn("CanvasLayer", combinado)

    def test_dos_tensores_controlan_sombra_y_colision_real(self):
        self.assertIn('TENSOR_PERSIANA := "persiana"', self.sueno)
        self.assertIn('TENSOR_CABLE := "cable"', self.sueno)
        self.assertIn('"solapamiento": solapamiento', self.sueno)
        self.assertIn('"puente_activo": solapamiento', self.sueno)
        self.assertIn("StaticBody3D", self.sueno)
        self.assertIn("CollisionShape3D", self.sueno)
        self.assertIn("_puente_colision.disabled = not activa", self.sueno)
        self.assertNotIn("Timer.new()", self.sueno)
        self.assertNotIn("create_timer", self.sueno)

    def test_reduccion_movimiento_conserva_mecanica(self):
        self.assertIn('"corte_fundido"', self.sueno)
        self.assertIn('"barrido_solar": false', self.sueno)
        self.assertIn('"mover_camara": false', self.sueno)
        self.assertIn('"timing_precision": false', self.sueno)
        self.assertIn("resolver_geometria", self.sueno)

    def test_tensores_exponen_interaccion_3d_semantica(self):
        self.assertIn("Interactuable3D.new()", self.sueno)
        self.assertIn("Interactuable3D.Verbo.USAR", self.sueno)
        self.assertIn("hotspot.activado.connect", self.sueno)
        self.assertIn("_al_usar_tensor", self.sueno)
        self.assertNotIn("Input.", self.sueno)

    def test_recorrido_real_monta_vigilia_y_sueno_sin_selector_paralelo(self):
        self.assertIn('fase == "casa"', self.controller)
        self.assertIn('String(dia._vivienda()) != "casa"', self.controller)
        self.assertIn("MauiTamanuiteraVigilia.new()", self.controller)
        self.assertRegex(
            self.controller,
            r"SemillasOniricas\s*\.\s*seleccionar_para_noche\s*\(",
        )
        self.assertRegex(
            self.controller,
            r"MitologiasNoche\s*\.\s*corresponde_a_escena\s*\(",
        )
        self.assertIn("SuenoMauiTamanuitera.ID_MITO", self.controller)
        self.assertIn("SuenoMauiTamanuitera.new()", self.controller)
        self.assertIn("CamaraStandalone", self.controller)
        self.assertNotIn("activar_semilla_onirica", self.controller)

    def test_controller_esta_montado_en_dia_real(self):
        self.assertIn(
            'path="res://guion/dia_maui_tamanuitera_app.gd"',
            self.dia,
        )
        self.assertIn(
            '[node name="MauiTamanuiteraController" type="Node" parent="."]',
            self.dia,
        )

    def test_documentacion_identifica_tradicion_concreta(self):
        self.assertIn("relato māori", self.referencias)
        self.assertIn("Māui", self.referencias)
        self.assertIn("Tamanuiterā", self.referencias)
        self.assertIn("Ministry of Education New Zealand", self.referencias)
        self.assertIn("Te Ara", self.referencias)
        self.assertIn("no intenta recrear literalmente", self.referencias)

    def test_escenas_standalone_apuntan_a_verticales(self):
        self.assertIn(
            'path="res://guion/sueno_maui_tamanuitera.gd"', self.escena_sueno
        )
        self.assertIn(
            '[node name="SuenoMauiTamanuitera" type="Node3D"]', self.escena_sueno
        )
        self.assertIn(
            'path="res://guion/maui_tamanuitera_vigilia.gd"', self.escena_vigilia
        )
        self.assertIn(
            '[node name="MauiTamanuiteraVigilia" type="Area3D"]',
            self.escena_vigilia,
        )

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
        self.assertGreaterEqual(int(resumen.group(1)), 30, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
