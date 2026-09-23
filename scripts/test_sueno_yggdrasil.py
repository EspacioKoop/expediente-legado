import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
SEMILLAS = ROOT / "godot" / "guion" / "SemillasOniricas.gd"
SUENO = ROOT / "godot" / "guion" / "sueno_yggdrasil.gd"
VIGILIA = ROOT / "godot" / "guion" / "yggdrasil_vigilia.gd"
ESCENA_SUENO = ROOT / "godot" / "escenas" / "sueno_yggdrasil.tscn"
ESCENA_VIGILIA = ROOT / "godot" / "escenas" / "yggdrasil_vigilia.tscn"
REFERENCIAS = ROOT / "docs" / "assets" / "yggdrasil-referencias.md"
CONTROLLER = ROOT / "godot" / "guion" / "dia_yggdrasil_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "res://pruebas/pruebas_yggdrasil.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SuenoYggdrasilTest(unittest.TestCase):
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
        self.assertIn('"yggdrasil",', self.semillas)
        self.assertIn('ID_MITO := "yggdrasil"', self.sueno)
        self.assertIn('CLAVE_SEMILLA := "semilla_onirica_yggdrasil"', self.sueno)
        self.assertIn("SemillasOniricas.familias_activas(estado)", self.sueno)
        self.assertRegex(
            self.sueno,
            r"SemillasOniricas\s*\.\s*activar_semilla_onirica\s*\(",
        )

    def test_vigilia_es_deliberada_y_sin_hud(self):
        self.assertIn("extends Interactuable3D", self.vigilia)
        self.assertIn("INSPECCIONES_MINIMAS := 2", self.vigilia)
        self.assertIn("_conexion_reconocida = true", self.vigilia)
        self.assertRegex(
            self.vigilia,
            r"SuenoYggdrasil\s*\.\s*registrar_semilla\s*\(",
        )
        combinado = self.sueno + self.vigilia
        self.assertNotIn("Label.new()", combinado)
        self.assertNotIn("CanvasLayer", combinado)

    def test_vigilia_esta_en_la_casa_real_y_no_activa_por_presencia(self):
        self.assertIn('fase == "casa"', self.controller)
        self.assertIn('String(dia._vivienda()) != "casa"', self.controller)
        self.assertIn("YggdrasilVigilia.new()", self.controller)
        self.assertIn("poster.configurar(jornada)", self.controller)
        self.assertNotIn("activar_semilla_onirica", self.controller)

    def test_controller_nocturno_usa_selector_y_asignacion_comunes(self):
        self.assertIn("SemillasOniricas", self.controller)
        self.assertIn(". seleccionar_para_noche(", self.controller)
        self.assertIn("MitologiasNoche", self.controller)
        self.assertIn(". corresponde_a_escena(", self.controller)
        self.assertIn("SuenoYggdrasil.ID_MITO", self.controller)
        self.assertIn("PreferenciasSiga.cargar()", self.controller)
        self.assertIn("SuenoYggdrasil.new()", self.controller)

    def test_controller_esta_montado_en_dia_real(self):
        self.assertIn('path="res://guion/dia_yggdrasil_app.gd"', self.dia)
        self.assertIn('[node name="YggdrasilController" type="Node" parent="."]', self.dia)

    def test_grafo_causal_es_visible_y_acotado(self):
        self.assertIn("const NODO_RAIZ", self.sueno)
        self.assertIn("const NODO_TRONCO", self.sueno)
        self.assertIn("const NODO_RAMA", self.sueno)
        self.assertIn("const CONEXIONES :=", self.sueno)
        self.assertIn('"alimentar"', self.sueno)
        self.assertIn('"tensar"', self.sueno)
        self.assertIn('"bloquear"', self.sueno)
        self.assertIn('"feedback_causal": true', self.sueno)
        self.assertIn('"Retorno"', self.sueno)
        self.assertIn("clampi(", self.sueno)

    def test_grafo_causal_usa_interaccion_3d_comun(self):
        self.assertIn("Interactuable3D.new()", self.sueno)
        self.assertIn("Interactuable3D.Verbo.USAR", self.sueno)
        self.assertIn("CollisionShape3D.new()", self.sueno)
        self.assertIn("hotspot.activado.connect", self.sueno)
        self.assertIn("_al_intervenir", self.sueno)
        self.assertNotIn("Input.", self.sueno)

    def test_reduccion_movimiento_no_cambia_causalidad(self):
        self.assertIn('"corte_fundido" if reduccion_movimiento', self.sueno)
        self.assertIn('"duracion": 0.0 if reduccion_movimiento', self.sueno)
        self.assertIn('"desplazar_sala": not reduccion_movimiento', self.sueno)
        self.assertIn("var destino := String(CONEXIONES[origen])", self.sueno)
        self.assertIn("var reduccion_movimiento := false", self.sueno)
        self.assertIn("yggdrasil.reduccion_movimiento", self.controller)

    def test_fuentes_culturales_preceden_arte_final(self):
        self.assertIn("Völuspá 19–20", self.referencias)
        self.assertIn("Grímnismál 29–35", self.referencias)
        self.assertIn("Gylfaginning XV", self.referencias)
        self.assertIn("reconstrucción", self.referencias)
        self.assertIn("convención pop", self.referencias)
        self.assertIn("procedencia.json", self.referencias)

    def test_escenas_standalone_apuntan_a_verticales(self):
        self.assertIn('path="res://guion/sueno_yggdrasil.gd"', self.escena_sueno)
        self.assertIn('[node name="SuenoYggdrasil" type="Node3D"]', self.escena_sueno)
        self.assertIn('path="res://guion/yggdrasil_vigilia.gd"', self.escena_vigilia)
        self.assertIn('[node name="YggdrasilVigilia" type="Area3D"]', self.escena_vigilia)

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
        self.assertGreaterEqual(int(resumen.group(1)), 35, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
