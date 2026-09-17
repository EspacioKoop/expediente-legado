import os
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
ACUMULACION = ROOT / "godot" / "guion" / "casa_acumulacion_3d.gd"
FISICA = ROOT / "godot" / "guion" / "publicacion_fisica_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_acumulacion_casa_app.gd"
DOC = ROOT / "docs" / "publicaciones-98.md"
PRUEBA_GODOT = "pruebas/pruebas_publicaciones_casa_3d.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class PublicacionesCasa674Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.acumulacion = ACUMULACION.read_text(encoding="utf-8")
        cls.fisica = FISICA.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_publicacion_reutiliza_interaccion_3d(self):
        self.assertIn("Interactuable3D.new()", self.acumulacion)
        self.assertIn("Interactuable3D.Verbo.LEER", self.acumulacion)
        self.assertIn('set_meta("publicacion_id"', self.acumulacion)
        self.assertIn('set_meta("titulo_publicacion"', self.acumulacion)
        self.assertIn('set_meta("portada_titulo"', self.acumulacion)
        self.assertIn("PublicacionFisica3D.montar", self.acumulacion)
        self.assertIn("CollisionShape3D.new()", self.fisica)

    def test_geometria_sale_del_catalogo_y_no_de_assets_nuevos(self):
        self.assertIn("Publicaciones98.por_id(item_id)", self.acumulacion)
        self.assertIn("PublicacionFisica3D.formato_de(ficha)", self.acumulacion)
        self.assertIn('return "periodico"', self.fisica)
        self.assertIn('return "libro"', self.fisica)
        self.assertIn('return "revista"', self.fisica)
        self.assertIn("paleta_de(item_id)", self.fisica)
        combinado = self.acumulacion + self.fisica
        for extension in (".glb", ".png", ".jpg", ".webp"):
            self.assertNotIn(extension, combinado.lower())

    def test_controller_abre_el_visor_mergeado_y_guarda_lectura(self):
        self.assertIn("_conectar_publicaciones(acumulacion)", self.controller)
        self.assertIn("nodo.activado.connect(_abrir_publicacion.bind(publicacion_id))", self.controller)
        self.assertIn("VisorPublicacion.new()", self.controller)
        self.assertIn("visor.abrir(dia.jornada, publicacion_id)", self.controller)
        self.assertIn("_visor.cerrada.connect(_guardar_lectura)", self.controller)
        self.assertIn('dia._guardar_o_avisar("")', self.controller)

    def test_no_duplica_inventario_ni_economia(self):
        combinado = self.acumulacion + self.fisica + self.controller
        self.assertNotIn("Inventario.recoger", combinado)
        self.assertNotIn("Inventario.guardar_en_casa", combinado)
        self.assertNotIn("Jornada.gastar", combinado)
        self.assertNotIn("ComercioBarrio.comprar", combinado)

    def test_documenta_el_vertical_y_lo_que_sigue_pendiente(self):
        texto = self.doc.lower()
        self.assertIn("publicaciones físicas en casa", texto)
        self.assertIn("interactuable3d", texto)
        self.assertIn("home_storage", texto)
        self.assertIn("encontrables", texto)
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
        self.assertGreaterEqual(int(resumen.group(1)), 30, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
