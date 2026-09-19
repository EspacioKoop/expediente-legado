import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "godot/guion/evaluacion_desempeno.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_evaluacion_desempeno_v2.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class EvaluacionDesempenoV2Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_dependencia_sale_de_trabajillos_persistidos(self):
        self.assertIn('jornada.get("trabajillos", {})', self.source)
        self.assertIn('trabajillos.get("hechos", 0)', self.source)
        self.assertIn('"dependencia_dinero": _rango(trabajos_extra, 1, 3)', self.source)
        self.assertNotIn("Trabajillos._estado", self.source)

    def test_versiona_sin_romper_informes_v1(self):
        self.assertIn("const VERSION_EVALUACION_ACTUAL := 2", self.source)
        self.assertIn('registro.get("version_evaluacion", 1)', self.source)
        self.assertIn(
            "CATEGORIAS_V1 if version_evaluacion == 1 else CATEGORIAS",
            self.source,
        )
        self.assertIn(
            '"version_evaluacion": VERSION_EVALUACION_ACTUAL',
            self.source,
        )

    def test_flujo_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 7, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
