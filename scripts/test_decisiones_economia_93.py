import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
COMIDA = ROOT / "godot" / "guion" / "comida_propia_interactiva_3d.gd"
CASA = ROOT / "godot" / "guion" / "dia_rutinas_casa_app.gd"
CAFE = ROOT / "godot" / "guion" / "dia_oficina_utileria_app.gd"
PRUEBA_GODOT = "pruebas/pruebas_comida_propia_3d.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")


class DecisionesEconomia93Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.comida = COMIDA.read_text(encoding="utf-8")
        cls.casa = CASA.read_text(encoding="utf-8")
        cls.cafe = CAFE.read_text(encoding="utf-8")

    def test_comida_es_fisica_y_sin_regla_economica_propia(self):
        self.assertIn("extends Interactuable3D", self.comida)
        self.assertIn('"PlatoCena"', self.comida)
        self.assertIn('"ComidaCena"', self.comida)
        self.assertIn("CollisionShape3D.new()", self.comida)
        self.assertIn("func consumir()", self.comida)
        self.assertIn("func marcar_saciado()", self.comida)
        self.assertIn("func marcar_sin_dinero()", self.comida)
        for token in ("Jornada", 'jornada["dinero"]', "Partida", "FileAccess"):
            self.assertNotIn(token, self.comida)

    def test_casa_conecta_comida_a_jornada_sin_doble_cobro(self):
        self.assertIn("ComidaPropiaInteractiva3D.new()", self.casa)
        self.assertIn("Jornada.PRECIO_COMIDA_PROPIA", self.casa)
        self.assertIn("Jornada.comer(dia.jornada, Jornada.PRECIO_COMIDA_PROPIA)", self.casa)
        self.assertIn('get("dias_sin_comer", 0)) <= 0', self.casa)
        self.assertIn("not comida.disponible()", self.casa)
        self.assertIn("comida.consumir()", self.casa)
        self.assertIn('dia._guardar_o_avisar("")', self.casa)
        self.assertNotIn('dia.jornada["dinero"] -=', self.casa)

    def test_cafe_reutiliza_tope_ya_calibrado(self):
        self.assertIn("Jornada.tomar_cafe(dia.jornada, Jornada.PRECIO_CAFE)", self.cafe)
        self.assertIn("Jornada.BONUS_ACCIONES_MAX_POR_DIA", self.cafe)
        self.assertIn("maquina.marcar_agotado()", self.cafe)
        self.assertIn("maquina.marcar_sin_dinero()", self.cafe)
        self.assertNotIn('dia.jornada["acciones"] +=', self.cafe)
        self.assertNotIn('dia.jornada["dinero"] -=', self.cafe)

    def test_comida_funciona_en_godot_headless(self):
        motor = os.environ.get("GODOT_BIN", "godot4")
        importar_proyecto()
        resultado = subprocess.run(
            [
                motor,
                "--headless",
                "--path",
                str(ROOT / "godot"),
                "--script",
                PRUEBA_GODOT,
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
            check=False,
        )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 12, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
