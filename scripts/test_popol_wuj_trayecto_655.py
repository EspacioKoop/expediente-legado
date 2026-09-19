import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "godot" / "guion" / "popol_wuj_trayecto_3d.gd"
CONTROLLER = ROOT / "godot" / "guion" / "dia_publicaciones_encontrables_app.gd"
PUBLICACIONES = ROOT / "godot" / "guion" / "publicaciones_98.gd"
COMERCIO = ROOT / "godot" / "guion" / "comercio_barrio.gd"
DOC = ROOT / "docs" / "publicaciones-98.md"
PRUEBA_GODOT = "res://pruebas/pruebas_popol_wuj_trayecto.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class PopolWujTrayecto655Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.helper = HELPER.read_text(encoding="utf-8")
        cls.controller = CONTROLLER.read_text(encoding="utf-8")
        cls.publicaciones = PUBLICACIONES.read_text(encoding="utf-8")
        cls.comercio = COMERCIO.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_trayecto_monta_lectura_sin_nueva_regla_de_semilla(self):
        self.assertIn('fase == "trayecto"', self.controller)
        self.assertIn("PopolTrayecto.montar(mundo)", self.controller)
        self.assertIn("VisorPublicacion.new()", self.controller)
        self.assertIn(
            "visor.abrir(dia.jornada, PopolTrayecto.ITEM_ID)",
            self.controller,
        )
        self.assertIn('dia._guardar_o_avisar("")', self.controller)
        self.assertNotIn("SemillasOniricas", self.controller)
        self.assertNotIn("SemillasOniricas", self.helper)

    def test_punto_fisico_reutiliza_publicacion_y_no_assets_externos(self):
        self.assertIn("class_name PopolWujTrayecto3D", self.helper)
        self.assertIn('ITEM_ID := "libro_popol_wuj_98"', self.helper)
        self.assertIn('FUENTE := "libro:popol_wuj_98"', self.helper)
        self.assertIn("PublicacionFisica3D.montar(lectura, ITEM_ID)", self.helper)
        self.assertIn("Interactuable3D.Verbo.LEER", self.helper)
        self.assertIn("Label3D.new()", self.helper)
        for extension in (".glb", ".png", ".jpg", ".webp", ".ogg", ".wav"):
            self.assertNotIn(extension, self.helper.lower())

    def test_compra_y_lectura_comparten_identidad_sin_activar_al_comprar(self):
        self.assertIn('"id": "libro_popol_wuj_98"', self.publicaciones)
        self.assertIn('"semilla_onirica": "popol_wuj"', self.publicaciones)
        self.assertIn('"fuente_semilla": "libro:popol_wuj_98"', self.publicaciones)
        self.assertIn('"id": "libro_popol_wuj_98"', self.comercio)
        self.assertIn('"fuente_semilla": "libro:popol_wuj_98"', self.comercio)
        cuerpo_compra = self.publicaciones.split("static func comprar", 1)[1].split(
            "static func hojear", 1
        )[0]
        self.assertNotIn("activar_semilla_onirica", cuerpo_compra)

    def test_documenta_lectura_real_fuera_de_oficina(self):
        texto = self.doc.lower()
        self.assertIn("libro_popol_wuj_98", self.doc)
        self.assertIn("trayecto", texto)
        self.assertIn("punto de lectura", texto)
        self.assertIn("comprar", texto)
        self.assertIn("no activa", texto)

    def test_punto_3d_funciona_en_godot_headless(self):
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
        self.assertGreaterEqual(int(resumen.group(1)), 12, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
