import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
SEMILLAS = ROOT / "godot" / "guion" / "SemillasOniricas.gd"
SUENO = ROOT / "godot" / "guion" / "sueno_baba_yaga.gd"
VIGILIA = ROOT / "godot" / "guion" / "baba_yaga_vigilia.gd"
ESCENA_SUENO = ROOT / "godot" / "escenas" / "sueno_baba_yaga.tscn"
ESCENA_VIGILIA = ROOT / "godot" / "escenas" / "baba_yaga_vigilia.tscn"
REFERENCIAS = ROOT / "docs" / "assets" / "baba-yaga-referencias.md"
PRUEBA_GODOT = "res://pruebas/pruebas_baba_yaga.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SuenoBabaYagaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.semillas = SEMILLAS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.escena_sueno = ESCENA_SUENO.read_text(encoding="utf-8")
        cls.escena_vigilia = ESCENA_VIGILIA.read_text(encoding="utf-8")
        cls.referencias = REFERENCIAS.read_text(encoding="utf-8")

    def test_semilla_usa_catalogo_comun(self):
        self.assertIn('"baba_yaga",', self.semillas)
        self.assertIn('ID_MITO := "baba_yaga"', self.sueno)
        self.assertIn('CLAVE_SEMILLA := "semilla_onirica_baba_yaga"', self.sueno)
        self.assertIn("SemillasOniricas.familias_activas(estado)", self.sueno)
        self.assertRegex(
            self.sueno,
            r"SemillasOniricas\s*\.\s*activar_semilla_onirica\s*\(",
        )

    def test_vigilia_es_deliberada_y_sin_hud(self):
        self.assertIn("extends Interactuable3D", self.vigilia)
        self.assertIn("LECTURAS_MINIMAS := 2", self.vigilia)
        self.assertIn("_abierto = true", self.vigilia)
        self.assertIn("_comparo_versiones = true", self.vigilia)
        self.assertRegex(
            self.vigilia,
            r"SuenoBabaYaga\s*\.\s*registrar_semilla\s*\(",
        )
        combinado = self.sueno + self.vigilia
        self.assertNotIn("Label.new()", combinado)
        self.assertNotIn("CanvasLayer", combinado)

    def test_arquitectura_movil_es_determinista(self):
        self.assertIn('EVENTO_UMBRAL := "cruzar_umbral"', self.sueno)
        self.assertIn('EVENTO_FUERA_CAMPO := "perder_de_vista"', self.sueno)
        self.assertIn("POSICIONES_ARBOL", self.sueno)
        self.assertIn("POSICIONES_VALLA", self.sueno)
        self.assertIn("POSICIONES_ARCHIVADOR", self.sueno)
        self.assertIn("POSICIONES_CABANA", self.sueno)
        self.assertNotIn("RandomNumberGenerator", self.sueno)
        self.assertNotIn("randf", self.sueno)
        self.assertNotIn("randi", self.sueno)

    def test_marcas_cabana_y_retorno(self):
        self.assertIn("func dejar_marca(", self.sueno)
        self.assertIn("func comparar_marca(", self.sueno)
        self.assertIn('"MarcasPersistentes"', self.sueno)
        self.assertIn('"CabanaAncla"', self.sueno)
        self.assertIn('"InteriorImposible"', self.sueno)
        self.assertIn('"RetornoSeguro"', self.sueno)
        self.assertIn('get_node("CabanaAncla").visible = true', self.sueno)
        self.assertIn('get_node("RetornoSeguro").visible = true', self.sueno)

    def test_reduccion_movimiento_conserva_mecanica(self):
        self.assertIn('"corte_fundido" if reduccion_movimiento', self.sueno)
        self.assertIn('"duracion": 0.0 if reduccion_movimiento', self.sueno)
        self.assertIn('"animar_geometria": not reduccion_movimiento', self.sueno)
        self.assertIn('"mover_camara": false', self.sueno)
        self.assertIn('"desplazar_jugador": false', self.sueno)
        self.assertIn('"flash": false', self.sueno)

    def test_fuentes_culturales_preceden_arte_final(self):
        self.assertIn("Sibelan Forrester", self.referencias)
        self.assertIn("University Press of Mississippi", self.referencias)
        self.assertIn("Aleksandr Afanas", self.referencias)
        self.assertIn("Arthur Ransome", self.referencias)
        self.assertIn("fuentes rusas", self.referencias)
        self.assertIn("no se presenta como tradición pan-eslava uniforme", self.referencias)
        self.assertIn("procedencia.json", self.referencias)

    def test_escenas_standalone_apuntan_a_verticales(self):
        self.assertIn('path="res://guion/sueno_baba_yaga.gd"', self.escena_sueno)
        self.assertIn('[node name="SuenoBabaYaga" type="Node3D"]', self.escena_sueno)
        self.assertIn('path="res://guion/baba_yaga_vigilia.gd"', self.escena_vigilia)
        self.assertIn('[node name="BabaYagaVigilia" type="Area3D"]', self.escena_vigilia)

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
        self.assertGreaterEqual(int(resumen.group(1)), 50, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
