import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CORCHO = ROOT / "godot" / "guion" / "corcho.gd"
CORCHO_3D = ROOT / "godot" / "guion" / "corcho_3d.gd"
CORCHO_PANEL = ROOT / "godot" / "guion" / "corcho_panel.gd"
TEXTOS = ROOT / "godot" / "datos" / "textos.csv"
PRUEBA_GODOT = "pruebas/pruebas_corcho.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class CorchoConceptosTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.estado = CORCHO.read_text(encoding="utf-8")
        cls.vista = CORCHO_3D.read_text(encoding="utf-8")
        cls.panel = CORCHO_PANEL.read_text(encoding="utf-8")
        cls.textos = TEXTOS.read_text(encoding="utf-8")

    def test_tablero_de_tamano_real_fuera_de_la_ventana(self):
        self.assertIn("const ESCALA := 0.34", self.vista)
        self.assertIn("const POSICION := Vector3(-2.3, 1.45, -0.52)", self.vista)
        self.assertIn('"MarcoCorcho"', self.vista)
        self.assertIn('uso.nombre_objeto = "corcho de conceptos"', self.vista)
        self.assertNotIn("Vector3(2.65, 1.55, 0.07)", self.vista)
        self.assertNotIn("Vector3(0.0, 1.55, -3.42)", self.vista)

    def test_se_reordena_en_una_interfaz_propia(self):
        panel = (ROOT / "godot" / "guion" / "corcho_panel.gd").read_text(encoding="utf-8")
        controlador = (ROOT / "godot" / "guion" / "dia_corcho_app.gd").read_text(
            encoding="utf-8"
        )
        self.assertIn("class_name CorchoPanel", panel)
        self.assertIn("Corcho.mover(_jornada, id, pos)", panel)
        self.assertIn("Corcho.alternar_enlace(_jornada, anterior, id)", panel)
        self.assertIn("JOY_BUTTON_X", panel)
        self.assertIn("_corcho_3d.abrir_pedido.connect(abrir_panel)", controlador)
        self.assertIn("_corcho_3d.refrescar()", controlador)
        self.assertNotIn("Interactuable3D.new()", self.vista.split("func _montar_ficha")[1])

    def test_lectura_ampliada_no_filtra_conceptos_ocultos_y_esta_localizada(self):
        self.assertIn("func inspeccionar(id: String)", self.panel)
        self.assertIn("Marcas.REFERENCIA", self.panel)
        self.assertIn("visibles.has(nombre)", self.panel)
        self.assertIn("tr(DATO_OCULTO)", self.panel)
        for clave in (
            "CORCHO_TITULO",
            "CORCHO_AYUDA_RATON",
            "CORCHO_AYUDA_MANDO",
            "CORCHO_DETALLE_TITULO",
            "CORCHO_DETALLE_VACIO",
            "CORCHO_DETALLE_SIN_RESUMEN",
            "CORCHO_DATO_OCULTO",
        ):
            self.assertIn(clave + ",", self.textos)
        self.assertNotIn('const TITULO := "Corcho de conceptos"', self.panel)

    def test_posiciones_persistidas_se_sanean_al_area_util(self):
        self.assertIn("static func limitar_posiciones", self.estado)
        self.assertIn("static func mover", self.estado)
        self.assertIn("clampf", self.estado)
        self.assertIn("Corcho.limitar_posiciones(_jornada, Corcho.limite())", self.vista)
        self.assertIn("const COLUMNAS_INICIALES := 5", self.estado)
        self.assertIn("const PASO_INICIAL := Vector2(0.48, 0.32)", self.estado)

    def test_sigue_sin_inferir_relaciones_del_grafo(self):
        panel = (ROOT / "godot" / "guion" / "corcho_panel.gd").read_text(encoding="utf-8")
        combinado = self.estado + self.vista + panel
        self.assertNotIn('get("referencias"', combinado)
        self.assertNotIn("Marcas.referencias", combinado)
        self.assertIn("Corcho.alternar_enlace", panel)

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
