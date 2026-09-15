import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CORCHO = ROOT / "godot" / "guion" / "corcho.gd"
CORCHO_3D = ROOT / "godot" / "guion" / "corcho_3d.gd"
PRUEBA_GODOT = "pruebas/pruebas_corcho.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class CorchoConceptosTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.estado = CORCHO.read_text(encoding="utf-8")
        cls.vista = CORCHO_3D.read_text(encoding="utf-8")

    def test_tablero_es_mas_compacto_y_reconocible(self):
        self.assertIn("const TAM_TABLON := Vector3(2.65, 1.55, 0.07)", self.vista)
        self.assertIn('"MarcoCorcho"', self.vista)
        self.assertIn('"CORCHO DE CONCEPTOS"', self.vista)
        self.assertIn('"USA DOS FICHAS PARA PONER / QUITAR HILO"', self.vista)
        self.assertNotIn("Vector3(3.7, 2.15, 0.08)", self.vista)

    def test_fichas_explican_la_interaccion_y_marcan_seleccion(self):
        self.assertIn('ficha.nombre_objeto = "ficha «%s»" % nombre_visible', self.vista)
        self.assertIn("COLOR_FICHA_SELECCIONADA", self.vista)
        self.assertIn("_actualizar_seleccion()", self.vista)
        self.assertIn('papel.name = "Papel"', self.vista)

    def test_posiciones_persistidas_se_sanean_al_area_util(self):
        self.assertIn("static func limitar_posiciones", self.estado)
        self.assertIn("clampf", self.estado)
        self.assertIn("Corcho.limitar_posiciones(_jornada, _limite_fichas())", self.vista)
        self.assertIn("const COLUMNAS_INICIALES := 5", self.estado)
        self.assertIn("const PASO_INICIAL := Vector2(0.48, 0.32)", self.estado)

    def test_sigue_sin_inferir_relaciones_del_grafo(self):
        combinado = self.estado + self.vista
        self.assertNotIn('get("referencias"', combinado)
        self.assertNotIn("Marcas.referencias", combinado)
        self.assertIn("Corcho.alternar_enlace", self.vista)

    def test_corte_funciona_en_godot_headless(self):
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
        self.assertGreaterEqual(int(resumen.group(1)), 80, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
