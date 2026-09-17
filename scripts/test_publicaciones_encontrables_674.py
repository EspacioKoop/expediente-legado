import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
ENCONTRABLES = ROOT / "godot" / "guion" / "publicaciones_encontrables_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_publicaciones_encontrables_app.gd"
DIA = ROOT / "godot" / "escenas" / "dia.tscn"
DOC = ROOT / "docs" / "publicaciones-98.md"
PRUEBA_GODOT = "pruebas/pruebas_publicaciones_encontrables_3d.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class PublicacionesEncontrables674Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.encontrables = ENCONTRABLES.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_cuatro_ids_no_comprables_tienen_anclas_reales(self):
        for item_id in (
            "byte_domestico_42",
            "marcador_98_deportes",
            "estratos_ciudad_06",
            "manual_casa_98",
        ):
            self.assertIn(f'"id": "{item_id}"', self.encontrables)
        for ancla in (
            "PuestoUtileria1",
            "MaquinaCafeInteractuable",
            "PuestoUtileria3",
            "SofaCasa",
        ):
            self.assertIn(f'"ancla": "{ancla}"', self.encontrables)

    def test_recogida_reutiliza_recogible_e_inventario(self):
        self.assertIn("Recogible3D.new()", self.encontrables)
        self.assertIn("recogible.configurar(inventario, datos)", self.encontrables)
        self.assertIn("Inventario.contiene(inventario, item_id)", self.encontrables)
        self.assertIn('"vendible": false', self.encontrables)
        self.assertIn('"categoria": "publicacion"', self.encontrables)
        self.assertNotIn("Inventario.recoger", self.encontrables)
        self.assertNotIn("ComercioBarrio", self.encontrables)
        self.assertNotIn("Jornada.gastar", self.encontrables)

    def test_controller_guarda_y_evita_respawn_por_firma(self):
        self.assertIn("Encontrables.firma(fase, numero_dia, inventario)", self.controller)
        self.assertIn("nodo.recogido.connect(_al_recoger)", self.controller)
        self.assertIn('dia._guardar_o_avisar("")', self.controller)
        self.assertIn('_firma = ""', self.controller)

    def test_dia_activa_el_controller_despues_de_utileria(self):
        self.assertIn("dia_publicaciones_encontrables_app.gd", self.dia)
        self.assertIn('name="PublicacionesEncontrablesController"', self.dia)
        self.assertLess(
            self.dia.index('name="OficinaUtileriaController"'),
            self.dia.index('name="PublicacionesEncontrablesController"'),
        )
        self.assertLess(
            self.dia.index('name="AcumulacionCasaController"'),
            self.dia.index('name="PublicacionesEncontrablesController"'),
        )

    def test_documenta_hallazgos_sin_bloqueo(self):
        texto = self.doc.lower()
        self.assertIn("ejemplares encontrables", texto)
        self.assertIn("recogible3d", texto)
        self.assertIn("puesto", texto)
        self.assertIn("sofá", texto)
        self.assertIn("ignorar", texto)
        self.assertIn("no cierra #674", texto)

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
                "--quit-after",
                "600",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 40, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
