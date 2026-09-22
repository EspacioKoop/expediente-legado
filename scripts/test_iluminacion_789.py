"""La luz de la oficina (#789).

El playtest vio «techo y paredes quemados, sin sombras de muebles ni personas».
Las lámparas y las sombras estaban encendidas desde #1121: lo que fallaba es que
el material las tiraba. `vertex_lighting` no aplica sombra, así que la oficina se
dibujaba sin una sola sombra de contacto por mucho que el motor la calculara.

Aquí se fija el contrato de texto —la variante del shader no puede separarse del
canónico, y solo la pide quien la necesita— y se ejecuta el contrato real sobre
Godot.
"""

import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
CANONICO = ROOT / "godot" / "arte" / "psx.gdshader"
VARIANTE = ROOT / "godot" / "arte" / "psx_luz_pixel.gdshader"
ESPACIO = ROOT / "godot" / "guion" / "espacio_3d.gd"
CATALOGO = ROOT / "godot" / "guion" / "espacios_catalogo.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_iluminacion_789.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")
PRIMER_UNIFORM = "uniform vec4 color_base"


def cuerpo(shader: str) -> str:
    """Todo lo que no es cabecera ni `render_mode`: el tratamiento en sí."""
    return shader.split(PRIMER_UNIFORM, 1)[1]


class Iluminacion789Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.canonico = CANONICO.read_text(encoding="utf-8")
        cls.variante = VARIANTE.read_text(encoding="utf-8")
        cls.espacio = ESPACIO.read_text(encoding="utf-8")
        cls.catalogo = CATALOGO.read_text(encoding="utf-8")

    def test_la_variante_no_puede_separarse_del_canonico(self):
        # Lo único que las distingue es el modo de iluminación. Si alguien toca
        # el temblor de vértices, la cuantización o el dithering en uno de los
        # dos, esta prueba lo dice antes de que la oficina deje de parecerse al
        # resto del juego.
        self.assertEqual(cuerpo(self.canonico), cuerpo(self.variante))

    def test_cada_shader_declara_su_iluminacion(self):
        self.assertIn(
            "render_mode vertex_lighting, diffuse_lambert, specular_disabled;", self.canonico
        )
        self.assertIn("render_mode diffuse_lambert, specular_disabled;", self.variante)
        self.assertNotIn("vertex_lighting", self.variante.split(PRIMER_UNIFORM, 1)[0].split("//")[-1])

    def test_la_luz_por_pixel_es_opt_in_del_sitio(self):
        # Ningún `if` con el nombre de una sala: el sitio lo declara en su
        # entrada del catálogo y el módulo solo lee la clave.
        self.assertIn('espacio.get("luz_por_pixel", false)', self.espacio)
        self.assertNotIn('== "archivo"', self.espacio)

    def test_el_modo_de_sombra_sigue_al_shader_del_sitio(self):
        # Medido en GPU: en paraboloide dual estas lámparas dan una imagen
        # idéntica píxel a píxel con la sombra encendida y apagada, porque
        # Forward+ no dibuja ese modo. El cubo solo se paga donde hay un
        # material que pueda recibir la sombra.
        self.assertIn("OmniLight3D.SHADOW_CUBE", self.espacio)
        self.assertIn("OmniLight3D.SHADOW_DUAL_PARABOLOID", self.espacio)
        self.assertIn("_shader_del_sitio == SHADER_PSX_LUZ_PIXEL", self.espacio)

    def test_solo_la_oficina_cambia(self):
        oficina = self.catalogo.split("const OFICINA :=", 1)[1].split("const CALLE :=", 1)[0]
        self.assertIn('"luz_por_pixel": true', oficina)
        self.assertIn('"techo_emision":', oficina)
        # Y nadie más la pide todavía: el resto del mundo conserva exactamente
        # la imagen con la que se midieron #399, #282 y #284.
        self.assertEqual(self.catalogo.count('"luz_por_pixel": true'), 1)

    def test_el_techo_deja_de_ser_una_caja_de_luz(self):
        oficina = self.catalogo.split("const OFICINA :=", 1)[1].split("const CALLE :=", 1)[0]
        emision = re.search(r'"techo_emision":\s*([0-9.]+)', oficina)
        self.assertIsNotNone(emision)
        self.assertLess(float(emision.group(1)), 0.9)
        self.assertGreater(float(emision.group(1)), 0.0)
        # La emisión plena sigue siendo el valor por defecto de todo lo demás.
        self.assertIn("const EMISION_PLENA := 0.9", self.espacio)
        self.assertIn("fuerza: float = EMISION_PLENA", self.espacio)

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
        self.assertGreaterEqual(int(resumen.group(1)), 16, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
