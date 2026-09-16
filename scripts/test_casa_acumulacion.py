import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
ACUMULACION = ROOT / "godot" / "guion" / "casa_acumulacion_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_acumulacion_casa_app.gd"
ESCENA = ROOT / "godot" / "escenas" / "dia.tscn"
PRUEBA_GODOT = "pruebas/pruebas_casa_acumulacion.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class CasaAcumulacionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.acumulacion = ACUMULACION.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.escena = ESCENA.read_text(encoding="utf-8")

    def test_renderer_es_acotado_y_sin_estado_paralelo(self):
        self.assertIn("const MAX_OBJETOS := 8", self.acumulacion)
        self.assertIn('estado_ambiental.get("objetos_casa", [])', self.acumulacion)
        self.assertIn('estanteria.get_node_or_null(NOMBRE_RAIZ)', self.acumulacion)
        self.assertIn('nodo.set_meta("objeto_id"', self.acumulacion)
        self.assertIn('nodo.set_meta("origen"', self.acumulacion)
        self.assertIn('salida.sort_custom(', self.acumulacion)
        self.assertNotIn("porcentaje", self.acumulacion.lower())
        self.assertNotIn("puntuacion", self.acumulacion.lower())
        self.assertNotIn("bonificacion", self.acumulacion.lower())

    def test_reutiliza_material_psx_y_no_assets_externos(self):
        self.assertIn("Modelos._pintar(malla, color)", self.acumulacion)
        self.assertIn("BoxMesh.new()", self.acumulacion)
        self.assertIn("CylinderMesh.new()", self.acumulacion)
        for extension in (".glb", ".png", ".jpg", ".webp"):
            self.assertNotIn(extension, self.acumulacion.lower())

    def test_controller_deriva_desde_estado_oficial(self):
        self.assertIn('fase != "casa"', self.controller)
        self.assertIn('partida.estado.get("inventario", {})', self.controller)
        self.assertIn("CasaEstadoAmbientalScript.derivar", self.controller)
        self.assertIn("CasaAcumulacion.montar", self.controller)
        self.assertIn("CasaAcumulacion.firma", self.controller)
        self.assertNotIn("Inventario.recoger", self.controller)
        self.assertNotIn("Inventario.guardar_en_casa", self.controller)

    def test_dia_monta_controller_hijo_sin_reemplazar_raiz(self):
        self.assertIn('path="res://guion/dia_clima_app.gd" id="1"', self.escena)
        self.assertIn('path="res://guion/dia_acumulacion_casa_app.gd" id="22"', self.escena)
        self.assertIn('[node name="AcumulacionCasaController" type="Node" parent="."]', self.escena)
        self.assertIn('script = ExtResource("22")', self.escena)

    def test_vertical_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importacion = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--editor",
                "--import",
                "--quit",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        self.assertEqual(importacion.returncode, 0, importacion.stdout)

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
        self.assertGreaterEqual(int(resumen.group(1)), 30, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
