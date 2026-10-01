import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "juicio_combate_arquetipos.gd"
PRUEBA = "res://pruebas/pruebas_juicio_arquetipos_1771.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class JuicioArquetipos1771Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = MODELO.read_text(encoding="utf-8")

    def test_cuatro_arquetipos_y_contrato_comun(self):
        for nombre in ("hostigador", "bloqueador", "enjambre", "embestidor"):
            self.assertIn(f'"{nombre}"', self.fuente)
        for campo in ("intencion", "telegraph", "ventana_respuesta", "cooldown"):
            self.assertIn(f'"{campo}"', self.fuente)
        self.assertIn('Azar.derivar(raiz, "combate", [1771, indice])', self.fuente)

    def test_ventanas_y_presupuesto_estan_acotados(self):
        self.assertIn("HOSTIGADOR_VENTANA := 0.90", self.fuente)
        self.assertIn("BLOQUEADOR_GUARDIA_MAX := 1.20", self.fuente)
        self.assertIn("ENJAMBRE_PRESUPUESTO_ATAQUES := 2", self.fuente)
        self.assertIn("EMBESTIDOR_TELEGRAFO := 0.70", self.fuente)
        self.assertIn("EMBESTIDOR_RECUPERACION := 1.00", self.fuente)
        self.assertIn('"carga_lineal"', self.fuente)
        self.assertIn("cuenta_presupuesto", self.fuente)
        self.assertIn("arena_tiene_ventana", self.fuente)

    def test_politica_no_toca_estado_global_ni_consecuencias(self):
        for simbolo in (
            "Partida.",
            "Jornada.",
            "SuenoCombate.",
            "Inventario",
            "Economia",
            "recompensa",
            "expediente",
        ):
            self.assertNotIn(simbolo, self.fuente)
        self.assertNotIn("randomize()", self.fuente)
        self.assertNotIn("randi()", self.fuente)
        self.assertNotIn("randf()", self.fuente)

    def test_reduccion_movimiento_es_solo_presentacion(self):
        bloque = self.fuente.split("static func presentacion(", 1)[1].split(
            "static func _resultado(", 1
        )[0]
        self.assertIn('"estilo": "corte" if reduccion_movimiento else "animado"', bloque)
        self.assertNotIn('unidad["estado"] =', bloque)
        self.assertNotIn('unidad["temporizador"] =', bloque)

    def test_contrato_godot(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        if shutil.which(motor) is None:
            self.skipTest(f"{motor} no disponible en este entorno")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
