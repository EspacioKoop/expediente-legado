"""Las sombras de un sitio: quién las proyecta y quién no (#275).

Desde que el proyecto usa Forward+ las luces proyectan sombra, y eso convierte
en error lo que antes era inocuo: una lámpara dentro de geometría que proyecta
se tapa a sí misma. El contrato se mide en Godot real sobre el árbol construido.
"""

import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ESPACIO = ROOT / "godot" / "guion" / "espacio_3d.gd"
PROYECTO = ROOT / "godot" / "project.godot"
PRUEBA_GODOT = "res://pruebas/pruebas_sombras_espacio_275.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class SombrasEspacio275Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.espacio = ESPACIO.read_text(encoding="utf-8")
        cls.proyecto = PROYECTO.read_text(encoding="utf-8")

    def test_el_renderer_admite_sombras(self):
        # Compatibility no ofrece SSAO ni SSIL y las sombras que sí da son otra
        # cosa: encenderlas sin este renderer sería pedir lo que no hay.
        self.assertIn('renderer/rendering_method="forward_plus"', self.proyecto)

    def test_la_carcasa_no_se_hace_sombra_a_si_misma(self):
        self.assertIn("_no_proyecta_sombra(cuerpo)", self.espacio)
        self.assertIn("SHADOW_CASTING_SETTING_OFF", self.espacio)

    def test_la_sombra_de_una_lampara_no_cuesta_seis_pasadas(self):
        self.assertIn("OmniLight3D.SHADOW_DUAL_PARABOLOID", self.espacio)

    def test_contrato_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=90,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 8, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
