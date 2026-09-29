import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CONTROLADOR = ROOT / "godot" / "guion" / "dia_sueno_reactivo_app.gd"
ESTADO = ROOT / "godot" / "guion" / "grabacion_onirica_estado.gd"
PRUEBA = "res://pruebas/pruebas_selector_toma_onirica_1682.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class SelectorTomaOnirica1682Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")
        cls.estado = ESTADO.read_text(encoding="utf-8")

    def test_reutiliza_estado_canonico_y_guardado_existente(self):
        self.assertIn(
            "GrabacionOniricaEstado.seleccionar_toma(partida_actual.estado, indice)",
            self.controlador,
        )
        self.assertIn('dia._guardar_o_avisar("")', self.controlador)
        self.assertIn('contenedor.get("toma_seleccionada"', self.controlador)
        self.assertNotIn('"toma_elegida"', self.controlador)

    def test_selector_es_foco_nativo_y_no_añade_input_paralelo(self):
        self.assertIn("Button.new()", self.controlador)
        self.assertIn("Control.FOCUS_ALL", self.controlador)
        self.assertIn("boton.pressed.connect(_al_seleccionar_toma.bind(indice))", self.controlador)
        self.assertNotIn("InputMap", self.controlador)
        self.assertNotIn("_input(", self.controlador)

    def test_no_autoselecciona_al_registrar(self):
        registrar = self.estado.split("static func registrar_toma", 1)[1].split(
            "\n\nstatic func ", 1
        )[0]
        self.assertNotIn("toma_seleccionada", registrar)
        self.assertNotIn("seleccionar_toma", registrar)

    def test_no_necesita_copy_nuevo(self):
        self.assertNotIn("CAMARA_ONIRICA_SELECCION", self.controlador)
        self.assertIn('"✓" if estado == GrabacionOniricaContrato.ESTADO_VALIDA else "~"', self.controlador)

    def test_contrato_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        if shutil.which(motor) is None:
            self.skipTest(f"{motor} no disponible en este entorno")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 15, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
