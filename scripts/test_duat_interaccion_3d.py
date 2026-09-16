import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "godot" / "guion" / "sueno_duat.gd"
INTERACTION = ROOT / "godot" / "guion" / "sueno_duat_interaccion_3d.gd"
SMOKE = ROOT / "godot" / "pruebas" / "pruebas_duat_interaccion.gd"


class DuatInteraccion3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = CORE.read_text(encoding="utf-8")
        cls.interaction = INTERACTION.read_text(encoding="utf-8")
        cls.smoke = SMOKE.read_text(encoding="utf-8")

    def test_reutiliza_regla_y_prototipo_existentes(self):
        self.assertIn("class_name SuenoDuatInteraccion3D", self.interaction)
        self.assertIn("SuenoDuat.preparar_pesaje(objetos_conocidos, semilla)", self.interaction)
        self.assertIn("SuenoDuat.crear_prototipo_3d", self.interaction)
        self.assertIn("aplicar_pesaje_3d(", self.interaction)
        self.assertNotIn("SemillasOniricas.activar_semilla_onirica", self.interaction)
        self.assertNotIn("Input.", self.interaction)

    def test_pesos_entran_en_detector_comun(self):
        self.assertIn("Interactuable3D.new()", self.interaction)
        self.assertIn("Interactuable3D.Verbo.USAR", self.interaction)
        self.assertIn("CollisionShape3D.new()", self.interaction)
        self.assertIn('hotspot.set_meta("duat_objeto_id", id_objeto)', self.interaction)
        self.assertIn('area.collision_layer = 0', self.interaction)
        self.assertIn('area.collision_mask = 0', self.interaction)

    def test_ciclo_es_explicito_y_reversible(self):
        self.assertIn("if not _seleccion.has(id_objeto):", self.interaction)
        self.assertIn("_seleccion[id_objeto] = false", self.interaction)
        self.assertIn("_seleccion[id_objeto] = true", self.interaction)
        self.assertIn("_seleccion.erase(id_objeto)", self.interaction)
        for estado in ('"fuera"', '"observado"', '"sellado"'):
            self.assertIn(estado, self.interaction)

    def test_resolucion_bloquea_repeticion(self):
        self.assertIn("signal duat_equilibrado", self.interaction)
        self.assertIn('get("equilibrado", false) == true', self.interaction)
        self.assertIn("hotspot.habilitado = false", self.interaction)
        self.assertIn("duat_equilibrado.emit()", self.interaction)
        self.assertIn("func resuelto() -> bool:", self.interaction)

    def test_reduccion_movimiento_no_cambia_regla(self):
        self.assertIn("if _reduccion_movimiento:", self.interaction)
        self.assertIn("area.position = destino", self.interaction)
        self.assertIn('"transicion_piramide": "estado_discreto"', self.core)
        self.assertIn('"regla": "peso_observable"', self.core)

    def test_smoke_ejerce_los_tres_estados_y_transformacion(self):
        self.assertIn('rom.get_meta("duat_estado", "") == "observado"', self.smoke)
        self.assertIn('rom.get_meta("duat_estado", "") == "sellado"', self.smoke)
        self.assertIn('not encuentro.seleccion_actual().has("rom")', self.smoke)
        self.assertIn("encuentro.resuelto()", self.smoke)
        self.assertIn("SuenoDuat.POS_PIRAMIDE_INFERIOR_EQUILIBRIO", self.smoke)
        self.assertIn("SuenoDuat.POS_PIRAMIDE_INVERTIDA_EQUILIBRIO", self.smoke)

    @unittest.skipUnless(
        shutil.which(os.environ.get("GODOT_BIN", "godot4")),
        "Godot no está disponible en PATH",
    )
    def test_smoke_godot_real(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="duat-interaccion-qa-") as temporal:
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
                    "res://pruebas/pruebas_duat_interaccion.gd",
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
