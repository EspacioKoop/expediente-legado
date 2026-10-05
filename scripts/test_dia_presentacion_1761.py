import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
PRESENTACION = ROOT / "godot" / "guion" / "dia_presentacion_app.gd"
PRUEBA = "res://pruebas/pruebas_dia_presentacion_1761.gd"
RESUMEN = re.compile(r"dia_presentacion_1761: (\d+) pasadas, 0 fallos")


class DiaPresentacion1761Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.dia_compacto = "".join(cls.dia.split())
        cls.presentacion = PRESENTACION.read_text(encoding="utf-8")

    def test_dia_delega_entorno_e_interfaz(self):
        self.assertIn("var_presentacion:=DiaPresentacionApp.new()", self.dia_compacto)
        self.assertIn("_presentacion.montar_entorno(", self.dia_compacto)
        self.assertIn("_presentacion.montar_interfaz(", self.dia_compacto)
        self.assertNotIn("WorldEnvironment.new()", self.dia)
        self.assertNotIn("DirectionalLight3D.new()", self.dia)

    def test_helper_es_solo_presentacion(self):
        for token in (
            "WorldEnvironment.new()",
            "DirectionalLight3D.new()",
            "AudioStreamPlayer.new()",
            "AudioStreamPlayer3D.new()",
            "CanvasLayer.new()",
            "EstiloSiga.tema()",
            "FiltroPantalla.aplicar(",
        ):
            self.assertIn(token, self.presentacion)
        for forbidden in ("Jornada.", "Partida.", "_entrar_en(", "_guardar_o_avisar("):
            self.assertNotIn(forbidden, self.presentacion)

    def test_wrappers_conservan_campos_historicos(self):
        for field in ("_ambiente", "_sol", "_caminante", "_voz", "_pisada"):
            self.assertIn(f'{field} = montado["{field[1:]}"]', self.dia)
        for field in ("_hud", "_rotulo", "_nomina", "_borrar"):
            self.assertIn(f'{field} = montado["{field[1:]}"]', self.dia)

    def test_dia_vuelve_a_tener_margen(self):
        self.assertLess(len(self.dia.splitlines()), 950)

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
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 15, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
