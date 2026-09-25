"""Dependientes de las tiendas del trayecto, con su voz, y su eco en el sueño."""

import csv
import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


RAIZ = Path(__file__).resolve().parents[1]
MODULO = (RAIZ / "godot/guion/dependientes_tiendas.gd").read_text(encoding="utf-8")
DIA = (RAIZ / "godot/guion/dia_clima_app.gd").read_text(encoding="utf-8")
TEXTOS = RAIZ / "godot/datos/textos.csv"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class DependientesTiendasTest(unittest.TestCase):
    def test_se_montan_al_entrar_en_el_trayecto(self):
        self.assertIn("DependientesTiendas3D.montar(_mundo)", DIA)
        self.assertIn("DependientesTiendas3D.siguiente_frase(", DIA)

    def test_cada_voz_tiene_sus_textos_y_no_se_repiten(self):
        with TEXTOS.open(encoding="utf-8") as fichero:
            filas = {fila[0]: fila[1] for fila in csv.reader(fichero) if fila}
        claves = re.findall(r'"clave": "(DEPEND_[A-Z]+)"', MODULO)
        self.assertEqual(len(claves), 4)
        textos = []
        for clave in claves:
            propias = [valor for nombre, valor in filas.items() if nombre.startswith(clave + "_")]
            # Cinco saludos, tres climas e insistencia como mínimo.
            self.assertGreaterEqual(len(propias), 9, clave)
            textos.extend(propias)
        # Una frase compartida entre dos dependientes les quitaría la voz propia.
        self.assertEqual(len(textos), len(set(textos)))

    def test_el_sueno_trae_a_quien_te_ha_hablado(self):
        self.assertIn("EcosSueno.registrar(jornada", DIA)
        self.assertIn("EcosSueno3D.montar(_mundo, _espacio_actual, jornada)", DIA)

    def test_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        for prueba in ("pruebas_dependientes_tiendas.gd", "pruebas_ecos_sueno.gd"):
            with self.subTest(prueba=prueba):
                resultado = subprocess.run(
                    [motor, "--headless", "--path", str(RAIZ / "godot"), "--script",
                     f"pruebas/{prueba}"],
                    text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120,
                    check=False,
                )
                self.assertEqual(resultado.returncode, 0, resultado.stdout)
                self.assertIsNotNone(RESUMEN.search(resultado.stdout), resultado.stdout)


if __name__ == "__main__":
    unittest.main()
