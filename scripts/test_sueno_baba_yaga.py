import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
SEMILLAS = ROOT / "godot" / "guion" / "SemillasOniricas.gd"
SUENO = ROOT / "godot" / "guion" / "sueno_baba_yaga.gd"
SUENO_CIELOS = ROOT / "godot" / "guion" / "sueno_cielos.gd"
VIGILIA = ROOT / "godot" / "guion" / "baba_yaga_vigilia.gd"
ESCENA_SUENO = ROOT / "godot" / "escenas" / "sueno_baba_yaga.tscn"
ESCENA_VIGILIA = ROOT / "godot" / "escenas" / "baba_yaga_vigilia.tscn"
REFERENCIAS = ROOT / "docs" / "assets" / "baba-yaga-referencias.md"
CONTROLLER = ROOT / "godot" / "guion" / "dia_baba_yaga_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "res://pruebas/pruebas_baba_yaga.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SuenoBabaYagaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.semillas = SEMILLAS.read_text(encoding="utf-8")
        cls.sueno = SUENO.read_text(encoding="utf-8")
        cls.sueno_cielos = SUENO_CIELOS.read_text(encoding="utf-8")
        cls.vigilia = VIGILIA.read_text(encoding="utf-8")
        cls.escena_sueno = ESCENA_SUENO.read_text(encoding="utf-8")
        cls.escena_vigilia = ESCENA_VIGILIA.read_text(encoding="utf-8")
        cls.referencias = REFERENCIAS.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")

    def test_semilla_usa_catalogo_comun(self):
        self.assertIn('"baba_yaga",', self.semillas)
        self.assertIn('ID_MITO := "baba_yaga"', self.sueno)
        self.assertIn('CLAVE_SEMILLA := "semilla_onirica_baba_yaga"', self.sueno)
        self.assertIn("SemillasOniricas.familias_activas(estado)", self.sueno)
        self.assertRegex(
            self.sueno,
            r"SemillasOniricas\s*\.\s*activar_semilla_onirica\s*\(",
        )

    def test_familia_tiene_perfil_de_cielo(self):
        self.assertRegex(self.sueno_cielos, r'(?m)^\s*"baba_yaga":\s*$')
        self.assertIn('"bruma_fuerza": 0.66', self.sueno_cielos)
        self.assertIn('"nubes": 0.62', self.sueno_cielos)

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
        self.assertIn('"DintelRetorno"', self.sueno)
        self.assertIn('"LecturaComparacion"', self.sueno)
        self.assertIn('"OrigenMarca"', self.sueno)
        self.assertIn('"DestinoActual"', self.sueno)
        self.assertIn("func ultima_comparacion()", self.sueno)
        self.assertIn("PASOS_RASTRO := 5", self.sueno)
        self.assertIn('get_node("CabanaAncla").visible = true', self.sueno)
        self.assertIn('get_node("RetornoSeguro").visible = true', self.sueno)

    def test_acabado_ambiental_es_procedural_y_no_figurativo(self):
        self.assertIn("func _montar_acabado_ambiental()", self.sueno)
        self.assertIn('"AcabadoAmbiental"', self.sueno)
        self.assertIn('"BosqueFondo"', self.sueno)
        self.assertIn('"TechoOficinaInvertido"', self.sueno)
        self.assertIn('"PlanoAdministrativoPlegado"', self.sueno)
        self.assertIn('"CocinaSIGA98"', self.sueno)
        self.assertIn('"Fluorescente%02d"', self.sueno)
        self.assertNotIn("Sprite3D.new()", self.sueno)
        self.assertNotIn("Decal.new()", self.sueno)

    def test_interior_cabana_cambia_sin_mover_el_marco(self):
        self.assertIn("INTERIORES_CABANA := [", self.sueno)
        self.assertIn('"EstadosInterior"', self.sueno)
        self.assertIn('"CocinaSIGA98"', self.sueno)
        self.assertIn('"ArchivoInvertido"', self.sueno)
        self.assertIn('"BosqueInterior"', self.sueno)
        self.assertIn('"SalaUmbral"', self.sueno)
        self.assertIn("func interior_actual()", self.sueno)
        self.assertIn("func _actualizar_interior_cabana()", self.sueno)
        self.assertIn('"interior_cabana": interior_actual()', self.sueno)
        self.assertIn('"MarcoPuerta"', self.sueno)

    def test_reduccion_movimiento_conserva_mecanica(self):
        self.assertIn('"corte_fundido" if reduccion_movimiento', self.sueno)
        self.assertIn('"duracion": 0.0 if reduccion_movimiento', self.sueno)
        self.assertIn('"animar_geometria": not reduccion_movimiento', self.sueno)
        self.assertIn('"mover_camara": false', self.sueno)
        self.assertIn('"desplazar_jugador": false', self.sueno)
        self.assertIn('"flash": false', self.sueno)

    def test_recorrido_real_reutiliza_vigilia_y_selector_comunes(self):
        self.assertIn('String(dia._vivienda()) != "casa"', self.controller)
        self.assertIn("BabaYagaVigilia.new()", self.controller)
        self.assertIn("libro.configurar(jornada)", self.controller)
        self.assertIn("SemillasOniricas", self.controller)
        self.assertIn(". seleccionar_para_noche(", self.controller)
        self.assertIn("MitologiasNoche", self.controller)
        self.assertIn(". corresponde_a_escena(", self.controller)
        self.assertIn("SuenoBabaYaga.ID_MITO", self.controller)
        self.assertNotIn("activar_semilla_onirica", self.controller)
        self.assertIn('path="res://guion/dia_baba_yaga_app.gd"', self.dia)
        self.assertIn('[node name="BabaYagaController" type="Node" parent="."]', self.dia)

    def test_bosque_tiene_controles_interactuables_reales(self):
        self.assertIn("Interactuable3D.new()", self.sueno)
        self.assertIn('controles.name = "ControlesBosque"', self.sueno)
        self.assertIn('"UmbralBosque"', self.sueno)
        self.assertIn('"ObservatorioArchivador"', self.sueno)
        self.assertIn('"CintaPersistente"', self.sueno)
        self.assertIn("umbral.activado.connect", self.sueno)
        self.assertIn("observatorio.activado.connect", self.sueno)
        self.assertIn("cinta.activado.connect", self.sueno)
        self.assertIn("control.add_child(colision)", self.sueno)
        self.assertIn("aplicar_evento(EVENTO_UMBRAL", self.sueno)
        self.assertIn("aplicar_evento(EVENTO_FUERA_CAMPO", self.sueno)
        self.assertIn("PreferenciasSiga.cargar()", self.sueno)

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
