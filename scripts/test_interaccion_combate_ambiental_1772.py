import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "interaccion_combate_ambiental.gd"
PRUEBA = "res://pruebas/pruebas_interaccion_combate_ambiental_1772.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class InteraccionCombateAmbiental1772Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fuente = MODELO.read_text(encoding="utf-8")

    def test_tres_verbos_son_explicitos(self):
        for verbo in ("empujar", "volcar", "activar"):
            self.assertIn(f'"{verbo}"', self.fuente)
        self.assertIn('"verbos_combate"', self.fuente)
        self.assertIn("combate_permitido", self.fuente)

    def test_no_detecta_props_por_nombre_ni_toca_interaccion_normal(self):
        self.assertNotIn("find_child", self.fuente)
        self.assertNotIn("find_children", self.fuente)
        self.assertNotIn("get_node", self.fuente)
        self.assertNotIn("Interactuable3D", self.fuente)
        self.assertNotIn("nombre_objeto", self.fuente)

    def test_no_crea_consecuencias_o_progreso_paralelos(self):
        for simbolo in (
            "Partida.",
            "Jornada.",
            "SuenoCombate.",
            "Inventario.",
            "dinero",
            "pista",
            "veredicto",
            "experiencia",
            "recompensa",
            "loot",
            "dano",
        ):
            self.assertNotIn(simbolo, self.fuente.lower() if simbolo.islower() else self.fuente)

    def test_efectos_estan_acotados(self):
        self.assertIn("DESPLAZAMIENTO_EMPUJAR_MAX := 2.0", self.fuente)
        self.assertIn("OBSTACULO_VOLCAR_MAX := 4.0", self.fuente)
        self.assertIn('"interrumpe": true', self.fuente)
        self.assertIn('"solido_temporal": true', self.fuente)
        self.assertIn('"efecto_id": efecto_id', self.fuente)

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
        self.assertGreaterEqual(int(resumen.group(1)), 25, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
