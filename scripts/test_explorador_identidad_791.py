import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot/guion/explorador_siga.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_explorador_identidad_791.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class ExploradorIdentidad791Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_identidad_es_local_y_diferencia_las_superficies(self):
        for token in (
            'const FONDO_BARRA := Color("#c9dbe8")',
            'const FONDO_RUTA := Color("#f8fbfc")',
            'const FONDO_LISTA := Color("#eef4f7")',
            'const FONDO_VISOR := Color("#fffaf0")',
            '"normal", _caja(FONDO_RUTA, BORDE',
            '"panel", _caja(FONDO_LISTA, BORDE',
            '"normal", _caja(FONDO_VISOR, Color("#9d967f")',
        ):
            self.assertIn(token, self.source)

    def test_no_convierte_la_identidad_en_otro_modelo_o_filesystem(self):
        self.assertIn("ExploradorSigaModelo.new()", self.source)
        self.assertIn("MediosExtraiblesSigaModelo.new()", self.source)
        self.assertNotIn("FileAccess.", self.source)
        self.assertNotIn("DirAccess.", self.source)
        self.assertNotIn("OS.execute", self.source)

    def test_preserva_navegacion_y_foco(self):
        for token in (
            "_boton_atras.pressed.connect(_ir_atras)",
            "_boton_adelante.pressed.connect(_ir_adelante)",
            "_boton_arriba.pressed.connect(_ir_arriba)",
            "_ruta.text_submitted.connect(_ruta_introducida)",
            "_lista.item_activated.connect(_activar_indice)",
            '"focus", _caja(FONDO_RUTA, FOCO',
            '"focus", _caja(Color("#d9e8f1"), FOCO',
        ):
            self.assertIn(token, self.source)

    def test_flujo_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 14, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
