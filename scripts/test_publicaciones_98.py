import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
PUBLICACIONES = ROOT / "godot" / "guion" / "publicaciones_98.gd"
COMERCIO = ROOT / "godot" / "guion" / "comercio_barrio.gd"
DOC = ROOT / "docs" / "publicaciones-98.md"
PRUEBA_GODOT = "res://pruebas/pruebas_publicaciones_98.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class Publicaciones98Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.publicaciones = PUBLICACIONES.read_text(encoding="utf-8")
        cls.comercio = COMERCIO.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_catalogo_declara_siete_publicaciones_originales(self):
        for item_id in (
            "revista_umbral_98",
            "libro_popol_wuj_98",
            "periodico_tarde_98",
            "byte_domestico_42",
            "marcador_98_deportes",
            "estratos_ciudad_06",
            "manual_casa_98",
        ):
            self.assertIn(f'"id": "{item_id}"', self.publicaciones)
        for categoria in (
            "misterio",
            "cultura_kiche",
            "prensa_general",
            "informatica",
            "deportes",
            "arqueologia_cultura",
            "guia_practica",
        ):
            self.assertIn(f'"categoria": "{categoria}"', self.publicaciones)

    def test_dos_publicaciones_tienen_contenido_hojeable_real(self):
        self.assertIn('"titulo": "Umbral — nº 17"', self.publicaciones)
        self.assertIn('"titulo": "La Tarde Local"', self.publicaciones)
        self.assertIn('"id": "dossier"', self.publicaciones)
        self.assertIn('"id": "agenda"', self.publicaciones)
        self.assertGreaterEqual(self.publicaciones.count('"texto":'), 12)

    def test_compra_delega_en_economia_ya_integrada(self):
        cuerpo_compra = self.publicaciones.split("static func comprar", 1)[1].split(
            "static func hojear", 1
        )[0]
        self.assertIn(
            'ComercioBarrio.comprar(jornada, inventario, "quiosco", item_id)',
            cuerpo_compra,
        )
        self.assertNotIn("Jornada.gastar", cuerpo_compra)
        self.assertIn('"id": "revista_umbral_98"', self.comercio)
        self.assertIn('"id": "periodico_tarde_98"', self.comercio)
        self.assertIn('"id": "libro_popol_wuj_98"', self.comercio)

    def test_lectura_es_persistente_e_idempotente(self):
        self.assertIn('const CLAVE_LECTURAS := "publicaciones_98_lecturas"', self.publicaciones)
        self.assertIn("vistas.has(pieza_id)", self.publicaciones)
        self.assertIn('estado["ultima_pieza"] = pieza_id', self.publicaciones)
        self.assertIn("static func contenido_visto", self.publicaciones)

    def test_semilla_exige_lectura_y_cierre_deliberado(self):
        self.assertIn('"semilla_onirica": "minotauro"', self.publicaciones)
        self.assertIn('"fuente_semilla": "publicacion:revista_umbral_98"', self.publicaciones)
        self.assertIn('"semilla_onirica": "popol_wuj"', self.publicaciones)
        self.assertIn('"fuente_semilla": "libro:popol_wuj_98"', self.publicaciones)
        self.assertIn("static func puede_sembrar", self.publicaciones)
        self.assertIn("static func cerrar_tras_lectura", self.publicaciones)
        self.assertIn("SemillasOniricas.activar_semilla_onirica", self.publicaciones)
        cuerpo_compra = self.publicaciones.split("static func comprar", 1)[1].split(
            "static func hojear", 1
        )[0]
        self.assertNotIn("SemillasOniricas", cuerpo_compra)

    def test_documenta_alcance_y_pendientes(self):
        for referencia in ("#93", "#96", "#442", "#674", "#676"):
            self.assertIn(referencia, self.doc)
        self.assertIn("no cierra #674", self.doc.lower())
        self.assertIn("interfaz de lectura", self.doc.lower())
        self.assertIn("materialización 3d", self.doc.lower())

    def test_contrato_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--quit-after",
                "600",
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout, resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout, resultado.stdout)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 55, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
