import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
FISICA = ROOT / "godot" / "guion" / "publicacion_fisica_3d.gd"
CASA = ROOT / "godot" / "guion" / "casa_acumulacion_3d.gd"
ENCONTRABLES = ROOT / "godot" / "guion" / "publicaciones_encontrables_3d.gd"
DOC = ROOT / "docs" / "publicaciones-98.md"
PRUEBA_GODOT = "pruebas/pruebas_publicacion_fisica_3d.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class PublicacionFisica674Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fisica = FISICA.read_text(encoding="utf-8")
        cls.casa = CASA.read_text(encoding="utf-8")
        cls.encontrables = ENCONTRABLES.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_acabado_cubre_las_siete_cabeceras(self):
        for item_id in (
            "revista_umbral_98",
            "libro_popol_wuj_98",
            "periodico_tarde_98",
            "byte_domestico_42",
            "marcador_98_deportes",
            "estratos_ciudad_06",
            "manual_casa_98",
        ):
            self.assertIn(f'"{item_id}"', self.fisica)
        self.assertIn('"cabecera": "UMBRAL"', self.fisica)
        self.assertIn('"cabecera": "CUADERNO CULTURAL"', self.fisica)
        self.assertIn('"edicion": "POPOL WUJ · 1998"', self.fisica)
        self.assertIn('"cabecera": "LA TARDE LOCAL"', self.fisica)
        self.assertIn('"cabecera": "BYTE DOMÉSTICO"', self.fisica)
        self.assertIn('"cabecera": "MARCADOR 98"', self.fisica)
        self.assertIn('"cabecera": "ESTRATOS Y CIUDAD"', self.fisica)
        self.assertIn('"cabecera": "ARREGLOS DE CASA"', self.fisica)

    def test_portada_y_lomo_son_texto_del_mundo(self):
        self.assertIn("Label3D.new()", self.fisica)
        self.assertIn('cabecera.name = "TituloPortada"', self.fisica)
        self.assertIn('edicion.name = "EdicionPortada"', self.fisica)
        self.assertIn('lomo.name = "LomoPublicacion"', self.fisica)
        self.assertIn("EstiloSiga.fuente_mono()", self.fisica)
        self.assertIn("etiqueta.shaded = false", self.fisica)
        self.assertNotIn("Control.new()", self.fisica)
        self.assertNotIn("CanvasLayer", self.fisica)

    def test_casa_y_hallazgos_reutilizan_el_mismo_acabado(self):
        llamada = "PublicacionFisica3D.montar"
        self.assertIn(llamada, self.casa)
        self.assertIn(llamada, self.encontrables)
        self.assertNotIn("_paleta_publicacion", self.casa)
        self.assertNotIn("static func _decorar", self.encontrables)
        self.assertNotIn("static func _color", self.encontrables)

    def test_capa_visual_no_toca_reglas_de_juego(self):
        for prohibido in (
            "ComercioBarrio",
            "Jornada.gastar",
            "Inventario.guardar_en_casa",
            "Inventario.recoger",
            "SemillasOniricas",
            "cerrar_tras_lectura",
        ):
            self.assertNotIn(prohibido, self.fisica)

    def test_documentacion_recoge_el_acabado_editorial(self):
        texto = self.doc.lower()
        self.assertIn("portadas y lomos", texto)
        self.assertIn("label3d", texto)
        self.assertIn("misma representación", texto)
        self.assertIn("no cierra #674", texto)

    def test_acabado_funciona_en_godot_headless(self):
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
        self.assertGreaterEqual(int(resumen.group(1)), 50, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
