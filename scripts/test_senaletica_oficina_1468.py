import os
from pathlib import Path
import re
import subprocess
import sys
import unittest
import xml.etree.ElementTree as ET

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ARTE = ROOT / "godot" / "arte" / "oficina_1468"
GENERADOR = ROOT / "scripts" / "generar_senaletica_oficina_1468.py"
RUNTIME = ROOT / "godot" / "guion" / "senaletica_oficina_98.gd"
CONTROLADOR = ROOT / "godot" / "guion" / "dia_oficina_utileria_app.gd"
PRUEBA_GODOT = "pruebas/pruebas_senaletica_oficina_1468.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SenaleticaOficina1468Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runtime = RUNTIME.read_text(encoding="utf-8")
        cls.controlador = CONTROLADOR.read_text(encoding="utf-8")

    def test_tres_svg_propios_y_validos(self):
        rutas = [
            ARTE / "salida_emergencia.svg",
            ARTE / "extintor.svg",
            ARTE / "calendario.svg",
        ]
        for ruta in rutas:
            self.assertTrue(ruta.is_file(), ruta)
            self.assertLess(ruta.stat().st_size, 10_000, ruta)
            raiz = ET.fromstring(ruta.read_text(encoding="utf-8"))
            self.assertTrue(raiz.tag.endswith("svg"), ruta)

    def test_svg_no_contienen_texto(self):
        for ruta in ARTE.glob("*.svg"):
            contenido = ruta.read_text(encoding="utf-8").lower()
            self.assertNotIn("<text", contenido)
            self.assertNotIn("font-", contenido)

    def test_generador_es_reproducible(self):
        resultado = subprocess.run(
            [sys.executable, str(GENERADOR), "--check"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)

    def test_runtime_es_fijo_idempotente_y_sin_gameplay(self):
        self.assertIn('mundo.get_node_or_null("SenaleticaOficina98")', self.runtime)
        self.assertIn("QuadMesh.new()", self.runtime)
        self.assertNotIn("Sprite3D", self.runtime)
        self.assertNotIn("CollisionShape3D.new", self.runtime)
        self.assertNotIn("Interactuable3D", self.runtime)
        self.assertNotIn("Jornada", self.runtime)
        self.assertNotIn("Partida", self.runtime)
        self.assertNotIn("billboard", self.runtime.lower().replace("no son billboards", ""))

    def test_se_monta_solo_con_el_dressing_de_archivo(self):
        self.assertIn("SenaleticaOficina98.montar(mundo)", self.controlador)
        self.assertIn('String(dia.jornada.get("fase", "")) == "archivo"', self.controlador)

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
        self.assertGreaterEqual(int(resumen.group(1)), 13, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
