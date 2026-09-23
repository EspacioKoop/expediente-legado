import os
from pathlib import Path
import re
import subprocess
import unittest

from scripts.godot_pruebas import importar_proyecto


ROOT = Path(__file__).resolve().parents[1]
DOMINIO = ROOT / "godot" / "guion" / "combinacion_objetos.gd"
INVENTARIO = ROOT / "godot" / "guion" / "inventario.gd"
PRUEBA_GODOT = "pruebas/pruebas_combinacion_objetos_955.gd"
RESUMEN = re.compile(r"(\d+) pasadas, 0 fallos")


class CombinacionObjetos955Test(unittest.TestCase):
    def setUp(self):
        self.dominio = DOMINIO.read_text(encoding="utf-8")
        self.inventario = INVENTARIO.read_text(encoding="utf-8")

    def test_reutiliza_inventario_y_no_crea_estado_paralelo(self):
        self.assertIn("class_name CombinacionObjetos", self.dominio)
        self.assertIn("Inventario.completar(inventario)", self.dominio)
        self.assertIn("Inventario.retirar(inventario", self.dominio)
        self.assertIn("Inventario.recoger(inventario, resultado)", self.dominio)
        self.assertNotIn("Partida.guardar", self.dominio)
        self.assertNotIn("FileAccess", self.dominio)

    def test_contrato_explicita_fallos_y_operacion_atomica(self):
        for motivo in (
            "slot_vacio",
            "mismo_objeto",
            "objeto_ausente",
            "sin_receta",
            "receta_invalida",
            "resultado_existente",
            "resultado_no_materializado",
        ):
            self.assertIn(motivo, self.dominio)
        self.assertIn("static func _restaurar(", self.dominio)
        self.assertIn("static func retirar(", self.inventario)

    def test_dominio_funciona_en_godot_headless(self):
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
        resumen = RESUMEN.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 16, resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
