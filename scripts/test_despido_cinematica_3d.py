"""El despido rueda en 3D (#899, decisión de #395).

La prueba de verdad es la de Godot: monta cada decorado en el reproductor
común y comprueba qué queda en el plató. Aquí solo se fija lo que no se puede
ver ejecutando: que no vuelve el corte 2D provisional.
"""

import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script

ROOT = Path(__file__).resolve().parents[1]
DESPIDO = ROOT / "godot" / "guion" / "despido_cinematica.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_despido_cinematica_3d.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class DespidoCinematica3DTest(unittest.TestCase):
    def test_sin_planos_2d(self):
        despido = DESPIDO.read_text(encoding="utf-8")
        self.assertNotIn('"tipo": "2d"', despido)
        self.assertNotIn('"figura":', despido)
        self.assertEqual(despido.count('"tipo": "3d"'), 3)

    def test_flujo_real_en_godot(self):
        resultado = ejecutar_script(PRUEBA_GODOT)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 35, resultado.stdout)


if __name__ == "__main__":
    unittest.main()
