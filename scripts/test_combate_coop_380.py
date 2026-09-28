import re
import unittest
from pathlib import Path

from scripts.godot_pruebas import ejecutar_script


PRUEBA_GODOT = "pruebas/pruebas_combate_coop_380.gd"
RESUMEN_GODOT = re.compile(r"(\d+) pasadas, 0 fallos")
ROOT = Path(__file__).resolve().parents[1]
ACCESO = ROOT / "godot" / "guion" / "ventanilla_coop_acceso.gd"
VENTANILLA = ROOT / "godot" / "guion" / "ventanilla_app.gd"


class CombateCoop380RuntimeTest(unittest.TestCase):
    """Ejecuta el vertical aislado de combate cooperativo con dos clientes fixture."""

    def test_combate_coop_en_godot_headless(self):
        resultado = ejecutar_script(PRUEBA_GODOT, timeout=60)
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        resumen = RESUMEN_GODOT.search(resultado.stdout)
        self.assertIsNotNone(resumen, resultado.stdout)
        self.assertGreaterEqual(int(resumen.group(1)), 20, resultado.stdout)

    def test_superficie_coop_no_conoce_partida(self):
        acceso = ACCESO.read_text(encoding="utf-8")
        codigo = "\n".join(
            linea for linea in acceso.splitlines()
            if not linea.lstrip().startswith("#")
        )
        self.assertNotIn("Partida", codigo)
        self.assertIn("IdentidadOnline", codigo)
        self.assertIn("CombateCoopServicio", codigo)

    def test_ventanilla_monta_acceso_opt_in(self):
        ventanilla = VENTANILLA.read_text(encoding="utf-8")
        self.assertIn('preload("res://guion/ventanilla_coop_acceso.gd")', ventanilla)
        self.assertIn('coop.name = "AbrirCoopVentanilla"', ventanilla)
        self.assertIn('_coop_panel.visible = false', ventanilla)


if __name__ == "__main__":
    unittest.main()
