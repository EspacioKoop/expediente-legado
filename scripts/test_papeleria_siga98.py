import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
PAPELERIA = ROOT / "godot" / "guion" / "papeleria_siga98.gd"
UTILERIA = ROOT / "godot" / "guion" / "oficina_utileria.gd"
PRUEBA_GODOT = "pruebas/pruebas_papeleria_siga98.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class PapeleriaSiga98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.papeleria = PAPELERIA.read_text(encoding="utf-8")
        cls.utileria = UTILERIA.read_text(encoding="utf-8")

    def test_biblioteca_tiene_diez_familias_reutilizables(self):
        for familia in (
            "formulario_a4",
            "formulario_a5",
            "multicopia",
            "carpeta",
            "separadores",
            "sobre_interno",
            "sello_tampon",
            "consumibles",
            "bandejas",
            "lomos_expediente",
        ):
            self.assertIn(f'"{familia}"', self.papeleria)
        self.assertIn("static func montar_mesa_clasificacion", self.papeleria)
        self.assertIn("static func agregar_formulario_a4", self.papeleria)
        self.assertIn("static func agregar_lomos_expediente", self.papeleria)

    def test_no_hay_texto_ni_datos_de_expediente(self):
        for termino in (
            "Label3D",
            "RichTextLabel",
            "TextMesh.new",
            "numero_expediente",
            "nombre_persona",
            "caso_id",
            "documento_id",
        ):
            self.assertNotIn(termino, self.papeleria)
        self.assertIn('"EtiquetaSinTexto"', self.papeleria)
        self.assertIn('"MarcaRutaSinTexto"', self.papeleria)

    def test_es_procedural_sin_assets_ni_azar_global(self):
        for termino in (
            "preload(",
            "load(",
            ".png",
            ".jpg",
            ".webp",
            ".svg",
            ".glb",
            "randi(",
            "randf(",
            "randomize(",
        ):
            self.assertNotIn(termino, self.papeleria)
        self.assertIn("posmod(semilla * 31 + salto * 17, cantidad)", self.papeleria)
        self.assertIn("Modelos._pintar", self.papeleria)

    def test_montaje_se_limita_a_la_mesa_de_clasificacion(self):
        self.assertIn("PapeleriaSiga98.montar_mesa_clasificacion(raiz)", self.utileria)
        self.assertIn("Vector3(3.10, 0.895, -0.28)", self.papeleria)
        self.assertIn("Vector3(4.07, 0.905, 0.27)", self.papeleria)
        self.assertNotIn("PUESTOS", self.papeleria)
        self.assertNotIn("Interactuable3D", self.papeleria)
        self.assertNotIn("CollisionShape3D.new", self.papeleria)

    def test_bandejas_detallan_los_volumenes_que_ya_existen(self):
        self.assertIn('var centros := [Vector3(3.32, 0.855, -0.12), Vector3(3.88, 0.865, 0.12)]', self.papeleria)
        self.assertIn('"BandejasEntradaSalida"', self.papeleria)
        self.assertNotIn("Partida", self.papeleria)
        self.assertNotIn("Jornada", self.papeleria)
        self.assertNotIn("FileAccess", self.papeleria)

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
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
