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

    def test_el_modo_de_sombra_es_el_que_dibuja_en_cada_sitio(self):
        # #789 midió en GPU lo que esta prueba daba por bueno: en paraboloide
        # dual, encender y apagar la sombra de las lámparas de la oficina
        # devuelve una imagen idéntica píxel a píxel. Forward+ no dibuja ese
        # modo, así que el ahorro de cuatro pasadas era el ahorro de no dibujar
        # ninguna sombra.
        #
        # Sigue habiendo dos modos y eso es deliberado: el cubo se paga donde la
        # envolvente se ilumina por píxel y puede recibir la sombra, y el resto
        # del mundo —que va por vértice y la descarta— no paga nada.
        self.assertIn("OmniLight3D.SHADOW_CUBE", self.espacio)
        self.assertIn("OmniLight3D.SHADOW_DUAL_PARABOLOID", self.espacio)
        self.assertIn("_shader_del_sitio == SHADER_PSX_LUZ_PIXEL", self.espacio)

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
