import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "godot" / "guion" / "sueno_minotauro.gd"
VERTICAL = ROOT / "godot" / "guion" / "sueno_minotauro_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_minotauro_sueno_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
SMOKE = ROOT / "godot" / "pruebas" / "pruebas_minotauro_noche.gd"


class MinotauroNocheRuntimeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = CORE.read_text(encoding="utf-8")
        cls.vertical = VERTICAL.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.smoke = SMOKE.read_text(encoding="utf-8")

    def test_vertical_reutiliza_topologia_segura(self):
        self.assertIn('const ID_MITO := "minotauro"', self.vertical)
        self.assertIn("SuenoMinotauro.estado_nuevo()", self.vertical)
        self.assertIn("SuenoMinotauro.poner_marca", self.vertical)
        self.assertIn("SuenoMinotauro.cruzar", self.vertical)
        self.assertIn("SuenoMinotauro.responder_minotauro", self.vertical)
        self.assertIn("static func hay_ruta(", self.core)

    def test_vertical_materializa_regla_espacial_y_marcas(self):
        self.assertIn('arquitectura.name = "LaberintoMinotauro"', self.vertical)
        self.assertIn('ancla.name = "AnclaAriadna_" + nodo_id', self.vertical)
        self.assertIn('"AlaReplegable"', self.vertical)
        self.assertIn('"Hilo_" + real', self.vertical)
        self.assertIn('"HiloAriadna"', self.vertical)
        self.assertIn('"NudoReal_" + real', self.vertical)
        self.assertIn('"Tramo%02d" % indice', self.vertical)
        self.assertIn("_reconstruir_hilo_ariadna()", self.vertical)
        self.assertIn('"PresenciaMinotauro"', self.vertical)
        self.assertIn('"SombraBloqueo"', self.vertical)
        self.assertIn("var _luz_archivo: OmniLight3D", self.vertical)
        self.assertIn("_aplicar_luz_presencia(presencia)", self.vertical)
        self.assertIn("_luz_archivo.light_energy = energia", self.vertical)
        self.assertIn("_luz_archivo.omni_range = alcance", self.vertical)
        self.assertIn("_luz_archivo.light_color = color", self.vertical)
        self.assertIn("Interactuable3D.new()", self.vertical)

    def test_reduccion_movimiento_no_cambia_regla(self):
        self.assertIn(
            "SuenoMinotauro.presentacion_transformacion(_estado, reduccion_movimiento)",
            self.vertical,
        )
        self.assertIn("if reduccion_movimiento or not animar_repliegue:", self.vertical)
        self.assertNotIn("Input.", self.vertical)
        self.assertNotIn("Camera3D.new()", self.vertical)
        self.assertNotIn(".current = true", self.vertical)

    def test_controller_consume_selector_y_asignacion_comunes(self):
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

    def test_controller_monta_sobre_sala_existente(self):
        self.assertIn('fase != "sueño"', self.controller)
        self.assertIn("var minotauro := SuenoMinotauro3D.new()", self.controller)
        self.assertIn("minotauro.reduccion_movimiento", self.controller)
        self.assertIn("minotauro.preparar()", self.controller)
        self.assertIn("_ancla_entre_entrada_y_salida", self.controller)
        self.assertIn("mundo.add_child(minotauro)", self.controller)
        self.assertNotIn("mundo.queue_free", self.controller)

    def test_dia_monta_controller_minotauro(self):
        self.assertIn('path="res://guion/dia_minotauro_sueno_app.gd"', self.dia)
        self.assertIn(
            '[node name="MinotauroSuenoController" type="Node" parent="."]', self.dia
        )

    def test_smoke_cubre_repliegue_hilo_presencia_y_ruta(self):
        self.assertIn("minotauro.marcar_y_cruzar(SuenoMinotauro.CRUCE_NORTE)", self.smoke)
        self.assertIn("minotauro.marcar_y_cruzar(SuenoMinotauro.BISAGRA)", self.smoke)
        self.assertIn("fase_topologica", self.smoke)
        self.assertIn('== "fundido_discreto"', self.smoke)
        self.assertIn("minotauro.marcar_y_cruzar(SuenoMinotauro.CENTRO)", self.smoke)
        self.assertIn('"HiloAriadna/NudoReal_cruce_norte"', self.smoke)
        self.assertIn("marca_norte.position.distance_to(nudo_norte.position) > 1.0", self.smoke)
        self.assertIn('"LuzArchivo"', self.smoke)
        self.assertIn("luz.light_energy > energia_lejana", self.smoke)
        self.assertIn("is_equal_approx(luz.light_energy, 4.2)", self.smoke)
        self.assertIn("is_equal_approx(luz.omni_range, 16.0)", self.smoke)
        self.assertIn("SuenoMinotauro.hay_ruta", self.smoke)

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
