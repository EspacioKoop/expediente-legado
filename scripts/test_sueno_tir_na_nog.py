import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
SEMILLAS = ROOT / "godot" / "guion" / "SemillasOniricas.gd"
SUENO = ROOT / "godot" / "guion" / "sueno_tir_na_nog.gd"
VIGILIA = ROOT / "godot" / "guion" / "tir_na_nog_vigilia.gd"
ESCENA_SUENO = ROOT / "godot" / "escenas" / "sueno_tir_na_nog.tscn"
ESCENA_VIGILIA = ROOT / "godot" / "escenas" / "tir_na_nog_vigilia.tscn"
REFERENCIAS = ROOT / "docs" / "assets" / "tir-na-nog-referencias.md"
CONTROLLER = ROOT / "godot" / "guion" / "dia_tir_na_nog_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
RADIO = ROOT / "godot" / "datos" / "radio_domestica_98.json"
PRUEBA_GODOT = "res://pruebas/pruebas_tir_na_nog.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SuenoTirNaNogTest(unittest.TestCase):
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
        cls.radio = RADIO.read_text(encoding="utf-8")

    def test_semilla_usa_catalogo_comun(self):
        self.assertIn('"tir_na_nog",', self.semillas)
        self.assertIn('ID_MITO := "tir_na_nog"', self.sueno)
        self.assertIn('CLAVE_SEMILLA := "semilla_onirica_tir_na_nog"', self.sueno)
        self.assertIn("SemillasOniricas.familias_activas(estado)", self.sueno)
        self.assertRegex(
            self.sueno,
            r"SemillasOniricas\s*\.\s*activar_semilla_onirica\s*\(",
        )

    def test_radio_exige_interaccion_deliberada(self):
        self.assertIn("extends Interactuable3D", self.vigilia)
        self.assertIn("SEGMENTOS_REQUERIDOS := 2", self.vigilia)
        self.assertIn("_programa_sintonizado = true", self.vigilia)
        self.assertIn("_segmentos_escuchados >= SEGMENTOS_REQUERIDOS", self.vigilia)
        self.assertRegex(
            self.vigilia,
            r"SuenoTirNaNog\s*\.\s*registrar_semilla\s*\(",
        )
        combinado = self.sueno + self.vigilia
        self.assertNotIn("Label.new()", combinado)
        self.assertNotIn("CanvasLayer", combinado)


    def test_radio_domestica_real_puede_sembrar_tir_na_nog(self):
        self.assertIn('"id_mito": "tir_na_nog"', self.radio)
        self.assertIn('"id": "islas_fuera_del_tiempo"', self.radio)
        self.assertIn('"atencion_requerida": 2', self.radio)
        self.assertIn("radio:radio_oeste_98:islas_fuera_del_tiempo", self.radio)

    def test_controller_nocturno_usa_selector_y_asignacion_comunes(self):
        self.assertIn("SemillasOniricas", self.controller)
        self.assertIn(". seleccionar_para_noche(", self.controller)
        self.assertIn("MitologiasNoche", self.controller)
        self.assertIn(". corresponde_a_escena(", self.controller)
        self.assertIn("SuenoTirNaNog.ID_MITO", self.controller)
        self.assertIn("PreferenciasSiga.cargar()", self.controller)
        self.assertNotIn("activar_semilla_onirica", self.controller)

    def test_controller_esta_montado_en_dia_real(self):
        self.assertIn('path="res://guion/dia_tir_na_nog_app.gd"', self.dia)
        self.assertIn('[node name="TirNaNogController" type="Node" parent="."]', self.dia)

    def test_umbral_conecta_dos_estados_del_mismo_lugar(self):
        self.assertIn('VERSION_RECIENTE := "reciente"', self.sueno)
        self.assertIn('VERSION_ENVEJECIDA := "envejecida"', self.sueno)
        self.assertIn("MAX_VERSIONES_SIMULTANEAS := 2", self.sueno)
        self.assertIn('UMBRAL_PRINCIPAL := "puerta_archivo"', self.sueno)
        self.assertIn("_version_actual = _otra_version(_version_actual)", self.sueno)
        self.assertIn('"irreversible": false', self.sueno)
        self.assertIn('"objetos_criticos_borrados": false', self.sueno)

    def test_objetos_dejan_reflejo_rastreable(self):
        for objeto in ("taza", "silla", "archivador"):
            self.assertIn(f'"{objeto}"', self.sueno)
        self.assertIn("marca_circular_alfeizar", self.sueno)
        self.assertIn("silueta_polvo_junto_puerta", self.sueno)
        self.assertIn("huella_oxido_pared_norte", self.sueno)
        self.assertIn('"rastreable": true', self.sueno)
        self.assertIn("_estado_objetos[objeto][otra] = estado_reflejo", self.sueno)

    def test_puzzle_reutiliza_interaccion_3d_comun(self):
        self.assertIn("Interactuable3D.new()", self.sueno)
        self.assertIn("Interactuable3D.Verbo.USAR", self.sueno)
        self.assertIn("CollisionShape3D.new()", self.sueno)
        self.assertIn("hotspot.activado.connect", self.sueno)
        self.assertIn("cruce.activado.connect", self.sueno)
        self.assertIn("hotspot.monitorable = version_visible", self.sueno)
        self.assertIn("hotspot.collision_layer = 1 if version_visible else 0", self.sueno)
        self.assertNotIn("Input.", self.sueno)

    def test_reduccion_movimiento_no_cambia_reglas(self):
        self.assertIn('"corte_fundido" if reduccion_movimiento', self.sueno)
        self.assertIn('"duracion": 0.0 if reduccion_movimiento', self.sueno)
        self.assertIn('"time_lapse": false', self.sueno)
        self.assertIn('"reloj_contrarreloj": false', self.sueno)
        self.assertNotIn("Timer.new()", self.sueno)

    def test_fuentes_separan_archivo_literatura_y_decisiones_propias(self):
        self.assertIn("CBÉ 0027", self.referencias)
        self.assertIn("CBÉ 0033", self.referencias)
        self.assertIn("CBÉ 0514", self.referencias)
        self.assertIn("Bailiúchán na Scol", self.referencias)
        self.assertIn("reelaboración literaria", self.referencias)
        self.assertIn("Decisiones propias del sueño", self.referencias)
        self.assertIn("procedencia.json", self.referencias)

    def test_escenas_standalone_apuntan_a_verticales(self):
        self.assertIn('path="res://guion/sueno_tir_na_nog.gd"', self.escena_sueno)
        self.assertIn('[node name="SuenoTirNaNog" type="Node3D"]', self.escena_sueno)
        self.assertIn('path="res://guion/tir_na_nog_vigilia.gd"', self.escena_vigilia)
        self.assertIn('[node name="TirNaNogVigilia" type="Area3D"]', self.escena_vigilia)

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
