import json
import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
ANIMACIONES = ROOT / "godot" / "guion" / "animaciones_ual.gd"
PROCEDENCIA = ROOT / "godot" / "assets" / "procedencia.json"
CARPETA = ROOT / "godot" / "assets" / "cc0" / "quaternius_ual"
PERSONA_IMPORT = ROOT / "godot" / "assets" / "modelos" / "persona.fbx.import"
PRUEBA_GODOT = "pruebas/pruebas_animaciones_ual.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")
PAQUETES = ("UAL1_Standard.glb", "UAL2_Standard.glb")


class AnimacionesUALTest(unittest.TestCase):
    def test_paquetes_son_quaternius_cc0_con_ficha_y_paquete(self):
        fichas = {
            ficha["ruta"]: ficha
            for ficha in json.loads(PROCEDENCIA.read_text(encoding="utf-8"))["assets"]
        }
        for paquete in PAQUETES:
            ficha = fichas.get(f"cc0/quaternius_ual/{paquete}")
            self.assertIsNotNone(ficha, paquete)
            self.assertEqual(ficha["autor"], "Quaternius")
            self.assertEqual(ficha["licencia"], "CC0-1.0")
            self.assertIn("paquete_sha256", ficha)

    def test_ual_se_importa_con_mapa_humanoide(self):
        for paquete in PAQUETES:
            texto = (CARPETA / f"{paquete}.import").read_text(encoding="utf-8")
            self.assertIn('"retarget/bone_map"', texto)
            self.assertIn("SkeletonProfileHumanoid", texto)
            self.assertIn('&"pelvis"', texto)

    def test_persona_no_se_reimporta_con_retarget(self):
        # Caras y vestuario dependen de los nombres Mixamo de persona.fbx.
        self.assertNotIn("bone_map", PERSONA_IMPORT.read_text(encoding="utf-8"))
        self.assertNotIn("motion_scale =", ANIMACIONES.read_text(encoding="utf-8"))

    def test_animaciones_en_godot_headless(self):
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
        self.assertIsNotNone(RESUMEN_GODOT.search(resultado.stdout), resultado.stdout)


if __name__ == "__main__":
    unittest.main()
