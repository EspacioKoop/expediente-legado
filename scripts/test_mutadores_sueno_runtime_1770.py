import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
DIA = ROOT / "godot" / "guion" / "dia_sueno_app.gd"
PRESENTADOR = ROOT / "godot" / "guion" / "sueno_mutador_presentacion_3d.gd"
PRUEBA = "res://pruebas/pruebas_mutadores_sueno_runtime_1770.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class MutadoresSuenoRuntime1770Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.presentador = PRESENTADOR.read_text(encoding="utf-8")

    def test_dia_aplica_seleccion_real_antes_del_montaje(self):
        tramo = self.dia.split("func _espacio_de", 1)[1].split("\n\nfunc ", 1)[0]
        self.assertIn("MutadoresSueno.seleccionar(", tramo)
        self.assertIn('int(jornada.get("raiz", 0))', tramo)
        self.assertIn("MutadoresSueno.aplicar(", tramo)
        self.assertIn('PreferenciasSiga.cargar().get("reduccion_movimiento", false)', tramo)

    def test_dia_monta_un_consumidor_generico(self):
        tramo = self.dia.split("func _entrar_en", 1)[1].split("\n\nfunc ", 1)[0]
        self.assertIn("SuenoMutadorPresentacion3D.montar(_mundo, _espacio_actual)", tramo)

    def test_presentador_no_crea_fisica_ni_estado_global(self):
        self.assertNotIn("CollisionShape3D.new", self.presentador)
        self.assertNotIn("StaticBody3D.new", self.presentador)
        self.assertNotIn("CharacterBody3D.new", self.presentador)
        self.assertNotIn('jornada[', self.presentador)
        self.assertNotIn("Partida.", self.presentador)
        self.assertNotIn("SuenoObjetivos", self.presentador)

    def test_cubre_los_cuatro_mutadores_sin_ifs_de_mitologia(self):
        for simbolo in ("HUMEDAD", "APAGONES", "REPETICION", "DESFASE"):
            self.assertIn(f"MutadoresSueno.{simbolo}", self.presentador)
        for mito in ("ryu", "mari", "yggdrasil", "anansi", "duat", "aquiles"):
            self.assertNotIn(mito, self.presentador.lower())

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
        self.assertGreaterEqual(int(resumen.group(1)), 30, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
