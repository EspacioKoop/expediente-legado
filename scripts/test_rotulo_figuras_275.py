"""El nombre de una figura va sobre su cabeza y no se entra encima de nadie (#275).

Las dos comprobaciones salieron de un playtest y se validan en Godot real: la
inspección textual aquí solo fija que la cuenta de altura no vuelva a suponer un
origen a media altura que `persona.fbx` no tiene.
"""

import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ESPACIO = ROOT / "godot" / "guion" / "espacio_3d.gd"
CATALOGO = ROOT / "godot" / "guion" / "espacios_catalogo.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_rotulo_figuras_275.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class RotuloFiguras275Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.espacio = ESPACIO.read_text(encoding="utf-8")
        cls.catalogo = CATALOGO.read_text(encoding="utf-8")

    def test_la_altura_del_rotulo_no_supone_un_origen_a_media_altura(self):
        # Silueta y modelo llegan los dos con los pies en su origen: restar media
        # silueta dejaba el nombre a la altura del pecho.
        self.assertNotIn("alto_rotulo -= FiguraSilueta.altura()", self.espacio)
        self.assertIn("Modelos.ALTO_PERSONA", self.espacio)

    def test_la_entrada_del_archivo_deja_sitio_al_companero_sentado(self):
        self.assertNotIn('"entrada": Vector3(0, 0, 3),', self.catalogo)

    def test_contrato_3d_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=60,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 4, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
