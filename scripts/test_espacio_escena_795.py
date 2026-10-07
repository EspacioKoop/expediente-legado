"""Un decorado de Espacio3D puede montar una escena .tscn (#795, corte 1).

La prueba de verdad es la de Godot: monta las once verticales de sueño, una
ruta rota y un rodaje real en el reproductor común. Aquí solo se fija lo que no
se ve ejecutando: que el reproductor no tuvo que cambiar para esto.
"""

import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import comprobar_contrato

ROOT = Path(__file__).resolve().parents[1]
ESPACIO = ROOT / "godot" / "guion" / "espacio_3d.gd"
REPRODUCTOR = ROOT / "godot" / "guion" / "cinematica_app.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_espacio_escena_795.gd"


class EspacioEscena795Test(unittest.TestCase):
    def test_la_escena_entra_por_espacio3d(self):
        espacio = ESPACIO.read_text(encoding="utf-8")
        self.assertRegex(espacio, r"static func _escena\(raiz: Node3D, espacio: Dictionary\)")
        self.assertIn('espacio.get("escena", "")', espacio)
        # El reproductor monta decorados con Espacio3D; no necesita saber de escenas.
        self.assertIn("Espacio3D.construir(_decorado, decorado)", REPRODUCTOR.read_text(encoding="utf-8"))

    def test_contrato_en_godot(self):
        salida = comprobar_contrato(self, PRUEBA_GODOT, " 0 fallos", timeout=120)
        pasadas = int(re.search(r"(\d+) pasadas, 0 fallos", salida).group(1))
        self.assertGreaterEqual(pasadas, 30, salida)


if __name__ == "__main__":
    unittest.main()
