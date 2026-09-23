import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
VERTICAL = ROOT / "godot" / "guion" / "sueno_ryu.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_ryu_sueno_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
SMOKE = ROOT / "godot" / "pruebas" / "pruebas_ryu_noche.gd"


class RyuNocheRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.vertical = VERTICAL.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.smoke = SMOKE.read_text(encoding="utf-8")

    def test_vertical_declara_familia_y_flujo_determinista(self):
        self.assertIn('const ID_MITO := "dragon_japones"', self.vertical)
        self.assertIn("const ESTADO_OBJETIVO := [true, false, true]", self.vertical)
        self.assertIn("var _estado_compuertas := [false, true, false]", self.vertical)
        self.assertIn("const CANTIDAD_COMPUERTAS := 3", self.vertical)
        self.assertIn("Curve3D.new()", self.vertical)
        self.assertIn("func _puntos_cauce() -> PackedVector3Array:", self.vertical)
        self.assertIn("var altura_b := 0.35 if _estado_compuertas[1] else 3.2", self.vertical)

    def test_dragon_es_procedural_y_no_plataforma_fisica(self):
        self.assertIn('dragon.name = "DragonProcedural"', self.vertical)
        self.assertIn("const SEGMENTOS_DRAGON := 15", self.vertical)
        self.assertIn("_curva.sample_baked", self.vertical)
        self.assertIn('"CuernoIzquierdo"', self.vertical)
        self.assertIn('"BigoteDerecho"', self.vertical)
        self.assertNotIn("RigidBody3D", self.vertical)
        self.assertNotIn("CharacterBody3D", self.vertical)

    def test_compuertas_reutilizan_interaccion_3d_sin_input_paralelo(self):
        self.assertIn("Interactuable3D.new()", self.vertical)
        self.assertIn("Interactuable3D.Verbo.USAR", self.vertical)
        self.assertIn("CollisionShape3D.new()", self.vertical)
        self.assertIn("compuerta.activado.connect", self.vertical)
        self.assertNotIn("Input.", self.vertical)
        self.assertNotIn("CanvasLayer", self.vertical)

    def test_reduccion_movimiento_conserva_mecanica(self):
        self.assertIn("var cantidad := 8 if reduccion_movimiento else 26", self.vertical)
        self.assertIn("var velocidad := 0.10 if reduccion_movimiento else 0.26", self.vertical)
        self.assertIn("var oscilacion := 0.04 if reduccion_movimiento else 0.22", self.vertical)
        self.assertIn("if reduccion_movimiento:", self.vertical)
        self.assertNotIn("flash", self.vertical.lower())

    def test_vertical_no_secuestra_camara(self):
        self.assertNotIn("Camera3D.new()", self.vertical)
        self.assertNotIn(".current = true", self.vertical)

    def test_escala_no_recorta_el_ojo_luna_con_techo_estandar(self):
        self.assertIn("const ESCALA_ENCUENTRO := 0.30", self.vertical)
        self.assertIn(
            "ryu.scale = Vector3.ONE * SuenoRyu.ESCALA_ENCUENTRO",
            self.controller,
        )
        self.assertNotIn("const ESCALA_ENCUENTRO := 0.48", self.controller)
        altura_ancla_habitual = 0.55
        altura_local_ojo = 6.0 + 1.4
        altura_techo = 2.8
        self.assertLess(
            altura_ancla_habitual + altura_local_ojo * 0.30,
            altura_techo,
        )

    def test_controller_usa_selector_y_asignacion_comunes(self):
        self.assertRegex(
            self.controller,
            r"SemillasOniricas\s*\.\s*seleccionar_para_noche\s*\(",
        )
        self.assertIn("MitologiasNoche.MAX_FAMILIAS_NOCHE", self.controller)
        self.assertRegex(
            self.controller,
            r"MitologiasNoche\s*\.\s*corresponde_a_escena\s*\(",
        )
        self.assertIn("SuenoRyu.ID_MITO", self.controller)
        self.assertNotIn("activar_semilla_onirica", self.controller)

    def test_controller_monta_vertical_sobre_sala_existente(self):
        self.assertIn('fase != "sueño"', self.controller)
        self.assertIn("var ryu := SuenoRyu.new()", self.controller)
        self.assertIn("ryu.reduccion_movimiento", self.controller)
        self.assertIn("ryu.preparar()", self.controller)
        self.assertIn("_ancla_entre_entrada_y_salida", self.controller)
        self.assertIn("mundo.add_child(ryu)", self.controller)

    def test_dia_monta_controller_ryu(self):
        self.assertIn('path="res://guion/dia_ryu_sueno_app.gd"', self.dia)
        self.assertIn('[node name="RyuSuenoController" type="Node" parent="."]', self.dia)

    def test_smoke_ejerce_solucion_y_bloqueo_posterior(self):
        self.assertIn("compuerta_1.interactuar(actor)", self.smoke)
        self.assertEqual(self.smoke.count("compuerta_2.interactuar(actor)"), 1)
        self.assertIn("compuerta_3.interactuar(actor)", self.smoke)
        self.assertIn("ryu.estado_compuertas() == [true, false, true]", self.smoke)
        self.assertIn("ryu.resuelto()", self.smoke)
        self.assertIn("not compuerta_1.interactuar(actor)", self.smoke)

    @unittest.skipUnless(
        shutil.which(os.environ.get("GODOT_BIN", "godot4")),
        "Godot no está disponible en PATH",
    )
    def test_smoke_godot_real(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="ryu-noche-qa-") as temporal:
            entorno = os.environ.copy()
            entorno["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for variable in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                entorno[variable] = str(Path(temporal) / variable)
            resultado = subprocess.run(
                [
                    motor,
                    "--headless",
                    "--language",
                    "es",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    "res://pruebas/pruebas_ryu_noche.gd",
                ],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=120,
                check=False,
            )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"\d+ pasadas, 0 fallos")


if __name__ == "__main__":
    unittest.main()
