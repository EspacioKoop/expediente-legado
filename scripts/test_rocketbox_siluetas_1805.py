import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MODULO = ROOT / "godot" / "guion" / "rocketbox_siluetas_modulares.gd"
MODELOS = ROOT / "godot" / "guion" / "modelos.gd"
PRUEBA = "res://pruebas/pruebas_rocketbox_siluetas_1805.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class RocketboxSiluetas1805Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.modulo = MODULO.read_text(encoding="utf-8")
        cls.modelos = MODELOS.read_text(encoding="utf-8")

    def test_muestra_es_exactamente_tres_historicos(self):
        for npc in ("emperador", "aduanero_ny", "correspondencia"):
            self.assertIn(f'"{npc}"', self.modulo)
        self.assertIn("OBJETIVOS", self.modulo)

    def test_reutiliza_rig_y_vocabulario_existentes(self):
        self.assertIn('preload("res://guion/vestuario_humano_3d.gd")', self.modulo)
        self.assertIn("VESTUARIO.PERFILES_PERSONAJE", self.modulo)
        self.assertRegex(self.modulo, r"vestidor\s*\.\s*vestir\(")
        self.assertNotIn("Skeleton3D.new()", self.modulo)
        self.assertNotIn("Skin.new()", self.modulo)

    def test_runtime_se_conecta_solo_a_rocketbox_historico(self):
        self.assertIn("ROCKETBOX_SILUETAS.aplicar(pieza, retrato)", self.modelos)
        self.assertIn("if es_realista(nombre):", self.modelos)

    def test_presupuesto_prohibe_texturas_y_rigs_extra(self):
        self.assertIn('"skeletons_extra": 0', self.modulo)
        self.assertIn('"texturas_extra": 0', self.modulo)
        self.assertIn("dentro_de_presupuesto", self.modulo)
        self.assertIn("firma_silueta", self.modulo)

    def test_contrato_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        if shutil.which(motor) is None:
            self.skipTest(f"{motor} no disponible en este entorno")
        importar_proyecto()
        resultado = subprocess.run(
            [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=45,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 40, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
