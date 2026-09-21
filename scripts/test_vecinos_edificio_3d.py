import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
PRESENTACION = ROOT / "godot" / "guion" / "vecinos_edificio_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_vecinos_edificio_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "pruebas/pruebas_vecinos_edificio_3d.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class VecinosEdificio3DTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.presentacion = PRESENTACION.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_reutiliza_contrato_y_no_inventa_sistemas(self):
        self.assertIn("VecinosEdificio.estado_portal", self.presentacion)
        self.assertIn("VecinosEdificio.presencias", self.presentacion)
        self.assertIn("VecinosEdificio.interacciones", self.presentacion)
        self.assertNotIn("Jornada.gastar", self.presentacion)
        self.assertNotIn('jornada["dinero"]', self.presentacion)
        self.assertNotIn('jornada["dinero"]', self.controller)

    def test_paquete_usa_interaccion_semantica_y_ancla_postal(self):
        self.assertIn("Interactuable3D.Verbo.COGER", self.presentacion)
        self.assertIn('get("correo_postal"', self.presentacion)
        self.assertIn("resolver_interaccion", self.controller)
        for patron in ("KEY_", "physical_keycode", "is_key_pressed"):
            self.assertNotIn(patron, self.presentacion)
            self.assertNotIn(patron, self.controller)

    def test_controller_esta_montado_en_dia(self):
        self.assertIn("dia_vecinos_edificio_app.gd", self.escena)
        self.assertIn('node name="VecinosEdificioController"', self.escena)
        self.assertIn('"trayecto"', self.controller)
        self.assertIn("PreferenciasSiga.cargar()", self.controller)
        self.assertIn("_guardar_o_avisar", self.controller)

    def test_vertical_3d_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
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
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 18, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
