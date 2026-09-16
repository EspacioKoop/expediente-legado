import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
VERTICAL = ROOT / "godot" / "guion" / "sueno_minotauro_3d.gd"
CONTRATO = ROOT / "godot" / "guion" / "sueno_minotauro.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_minotauro_sueno_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
SMOKE = ROOT / "godot" / "pruebas" / "pruebas_minotauro_noche.gd"


class MinotauroNocheRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.vertical = VERTICAL.read_text(encoding="utf-8")
        cls.contrato = CONTRATO.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.smoke = SMOKE.read_text(encoding="utf-8")

    def test_presentacion_reutiliza_contrato_sin_duplicar_topologia(self):
        self.assertIn('const ID_MITO := "minotauro"', self.vertical)
        self.assertIn("SuenoMinotauro.estado_nuevo()", self.vertical)
        self.assertIn("SuenoMinotauro.plano()", self.vertical)
        self.assertIn("SuenoMinotauro.cruzar", self.vertical)
        self.assertIn("SuenoMinotauro.poner_marca", self.vertical)
        self.assertIn("SuenoMinotauro.leer_marca", self.vertical)
        self.assertIn("SuenoMinotauro.responder_minotauro", self.vertical)
        self.assertNotIn("var _vecinos", self.vertical)
        self.assertIn("static var _vecinos", self.contrato)

    def test_laberinto_es_fisico_y_no_una_reticula_paralela(self):
        self.assertIn("StaticBody3D.new()", self.vertical)
        self.assertIn("BoxShape3D.new()", self.vertical)
        self.assertIn("cuerpo.look_at", self.vertical)
        self.assertIn("SuenoMinotauro.posicion(desde)", self.vertical)
        self.assertIn("SuenoMinotauro.posicion(hasta)", self.vertical)
        self.assertNotIn("GridMap", self.vertical)
        self.assertNotIn("AStarGrid2D", self.vertical)

    def test_ariadna_es_interactiva_visible_y_persistente_por_id_real(self):
        self.assertIn('anclaje.nombre_objeto = "hilo de Ariadna"', self.vertical)
        self.assertIn("Interactuable3D.new()", self.vertical)
        self.assertIn("anclaje.activado.connect(_poner_marca.bind", self.vertical)
        self.assertIn('"MarcaVisible%02d"', self.vertical)
        self.assertIn('"Hilo%02d"', self.vertical)
        self.assertIn("nodo_aparente", self.vertical)
        self.assertNotIn("Input.", self.vertical)

    def test_repliegue_mueve_lectura_aparente_sin_mutar_ruta_real(self):
        self.assertIn('repliegue.name = "RepliegueTopologico"', self.vertical)
        self.assertIn("SuenoMinotauro.nodo_aparente(real, fase)", self.vertical)
        self.assertIn("SuenoMinotauro.transformacion_actual(_estado)", self.vertical)
        self.assertIn('== "escala_imposible"', self.vertical)
        self.assertIn("if not animar or reduccion_movimiento:", self.vertical)
        self.assertNotIn("_vecinos[", self.vertical)

    def test_minotauro_es_presencia_sin_combate_ni_cuerpo_jugable(self):
        self.assertIn('minotauro.name = "SuenoMinotauroNoche"', self.controller)
        self.assertIn('"PresenciaMinotauro"', self.vertical)
        self.assertIn('visual.name = "Cuerno%s"', self.vertical)
        self.assertIn('ojo_visual.name = "Ojo%s"', self.vertical)
        self.assertNotIn("RigidBody3D", self.vertical)
        self.assertNotIn("CharacterBody3D", self.vertical)
        self.assertNotIn("ataque", self.vertical.lower())
        self.assertNotIn("dano", self.vertical.lower())

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
        self.assertIn("SuenoMinotauro3D.ID_MITO", self.controller)
        self.assertNotIn("activar_semilla_onirica", self.controller)

    def test_controller_encaja_laberinto_en_sala_existente(self):
        self.assertIn('fase != "sueño"', self.controller)
        self.assertIn("var minotauro := SuenoMinotauro3D.new()", self.controller)
        self.assertIn("minotauro.reduccion_movimiento", self.controller)
        self.assertIn("minotauro.preparar()", self.controller)
        self.assertIn("_encajar_en_recorrido(minotauro, espacio)", self.controller)
        self.assertIn("SuenoMinotauro.ENTRADA", self.controller)
        self.assertIn("SuenoMinotauro.SALIDA", self.controller)
        self.assertIn("mundo.add_child(minotauro)", self.controller)

    def test_dia_monta_controller_minotauro(self):
        self.assertIn('path="res://guion/dia_minotauro_sueno_app.gd"', self.dia)
        self.assertIn('[node name="MinotauroSuenoController" type="Node" parent="."]', self.dia)

    def test_smoke_ejerce_marca_repliegue_y_ruta_recuperable(self):
        self.assertIn("marca.interactuar(actor)", self.smoke)
        self.assertEqual(self.smoke.count("bisagra.interactuar(actor)"), 2)
        self.assertIn('== "desplazada"', self.smoke)
        self.assertIn('minotauro.presencia_actual() == "cruce"', self.smoke)
        self.assertIn("minotauro.ruta_recuperable()", self.smoke)

    @unittest.skipUnless(
        shutil.which(os.environ.get("GODOT_BIN", "godot4")),
        "Godot no está disponible en PATH",
    )
    def test_smoke_godot_real(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="minotauro-noche-qa-") as temporal:
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
                    "res://pruebas/pruebas_minotauro_noche.gd",
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
