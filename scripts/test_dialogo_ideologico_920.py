"""Regresión del diálogo ideológico declarativo (#920)."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "dialogo_ideologico.gd"
DIA = ROOT / "godot" / "guion" / "dia_clima_app.gd"
CAREO = ROOT / "godot" / "guion" / "careo_contexto_app.gd"
PRUEBA_GODOT = "res://pruebas/issue_920_smoke.gd"


class DialogoIdeologico920Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.modelo = MODELO.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.careo = CAREO.read_text(encoding="utf-8")

    def test_condiciones_declarativas_estan_separadas_del_hud(self) -> None:
        for contrato in (
            "requiere_evento",
            "requiere_eleccion",
            "requiere_exposicion",
            "actor_recuerda",
            "respuesta_registra",
        ):
            self.assertIn(contrato, self.modelo)
        self.assertNotIn("CanvasLayer", self.modelo)
        self.assertNotIn("Button.new", self.modelo)

    def test_oficina_reutiliza_el_dialogo_existente(self) -> None:
        self.assertIn("DialogoIdeologico.resolver(", self.dia)
        self.assertIn("DialogoDiegetico.mostrar(", self.dia)
        self.assertIn("DialogoIdeologico.registrar_respuesta(", self.dia)

    def test_careo_solo_presenta_contexto_y_no_muta_combate(self) -> None:
        self.assertIn("SUPERFICIE_CAREO_EXPOSICION", self.careo)
        self.assertIn("DialogoIdeologico.resolver(", self.careo)
        self.assertNotIn("Combate.jugar", self.careo)
        self.assertNotIn('estado["veredictos"] =', self.careo)
        self.assertNotIn('estado["pistas_descubiertas"] =', self.careo)

    def test_runtime_standalone(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")

        with tempfile.TemporaryDirectory(prefix="ideologia-920-") as temporal:
            entorno = os.environ.copy()
            for variable, carpeta in (
                ("XDG_DATA_HOME", "datos"),
                ("XDG_CONFIG_HOME", "config"),
                ("XDG_CACHE_HOME", "cache"),
            ):
                entorno[variable] = str(Path(temporal) / carpeta)

            resultado = subprocess.run(
                [
                    motor,
                    "--headless",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    PRUEBA_GODOT,
                ],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=30,
                check=False,
            )

        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"issue_920: \d+ pasadas, 0 fallos")
        self.assertNotIn("Parse Error:", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
