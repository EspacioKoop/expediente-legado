"""Lo que hay dentro de la oficina también se ilumina por píxel (#789).

La envolvente pasó a luz por píxel en #1243, pero muebles, assets, personas y
su ropa fijaban el shader canónico y seguían sin recibir sombra. El contrato
real se ejecuta en Godot: oficina montada sin una sola superficie por vértice,
y trayecto y casa, construidos después, intactos.
"""

import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ESPACIO = ROOT / "godot" / "guion" / "espacio_3d.gd"
CONSUMIDORES = (
    ROOT / "godot" / "guion" / "modelos.gd",
    ROOT / "godot" / "guion" / "asset_cc0.gd",
    ROOT / "godot" / "guion" / "vestuario_humano_3d.gd",
    ROOT / "godot" / "guion" / "correccion_visual_npc_275.gd",
    ROOT / "godot" / "arte" / "vintage_wooden_drawer.gd",
)
PRUEBA_GODOT = "res://pruebas/pruebas_luz_pixel_muebles_789.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class LuzPixelMuebles789Test(unittest.TestCase):
    def test_el_sitio_expone_su_shader(self):
        self.assertIn("static func shader_del_sitio() -> String:", ESPACIO.read_text(encoding="utf-8"))

    def test_lo_que_se_monta_dentro_pide_el_shader_del_sitio(self):
        for ruta in CONSUMIDORES:
            with self.subTest(ruta=ruta.name):
                codigo = ruta.read_text(encoding="utf-8")
                self.assertIn("Espacio3D.shader_del_sitio()", codigo)
                self.assertNotIn("load(Espacio3D.SHADER_PSX)", codigo)

    def test_contrato_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=180,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 8, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
