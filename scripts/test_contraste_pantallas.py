"""Regla general: ningún texto oscuro sobre gris y nada por debajo de WCAG AA.

La comprobación de verdad corre en Godot sobre pantallas montadas
(`pruebas_contraste_pantallas.gd`); aquí se fija el contrato estático que la
sostiene: los menús del juego usan su tema propio y el OS98 ya no pinta el gris
de sistema detrás del texto.
"""

import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


RAIZ = Path(__file__).resolve().parents[1]
GUION = RAIZ / "godot" / "guion"
PRUEBA_GODOT = "pruebas/pruebas_contraste_pantallas.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


def _leer(nombre):
    return (GUION / nombre).read_text(encoding="utf-8")


class ContrastePantallasTest(unittest.TestCase):
    def test_menus_del_juego_usan_su_tema_oscuro(self):
        for nombre in ("creador_personaje_app.gd", "menu_global.gd"):
            with self.subTest(nombre=nombre):
                fuente = _leer(nombre)
                self.assertIn("EstiloJuego.tema()", fuente)
                self.assertNotIn("EstiloSiga.tema()", fuente)

    def test_el_gris_de_sistema_no_es_fondo_de_texto(self):
        for ruta in sorted(GUION.glob("*.gd")):
            if ruta.name == "estilo_siga.gd":
                continue
            with self.subTest(archivo=ruta.name):
                fuente = ruta.read_text(encoding="utf-8")
                self.assertNotRegex(fuente, r"EstiloSiga\.GRIS\b(?!_)")

    def test_la_regla_mira_lo_que_hay_detras_de_cada_texto(self):
        regla = _leer("contraste_texto.gd")
        for contrato in (
            "static func auditar(",
            "static func es_gris(",
            "static func fondo_de(",
            "static func declarar_fondo(",
            "const MIN_AA := 4.5",
        ):
            self.assertIn(contrato, regla)
        self.assertIn("declarar_bisel(lienzo as Control, fondo)", _leer("estilo_siga.gd"))

    def test_pantallas_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(RAIZ / "godot"), "--script", PRUEBA_GODOT],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=180,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIsNotNone(RESUMEN_GODOT.search(resultado.stdout), resultado.stdout)
        self.assertNotIn("texto oscuro sobre gris", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
