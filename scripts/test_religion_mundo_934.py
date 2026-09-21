import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


RAIZ = Path(__file__).resolve().parents[1]
MUNDO = RAIZ / "godot/guion/religion_mundo_934.gd"
MUNDO_3D = RAIZ / "godot/guion/religion_mundo_934_3d.gd"
PRUEBA = RAIZ / "godot/pruebas/pruebas_religion_mundo_934.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_religion_mundo_934.gd"


class ReligionMundo934Test(unittest.TestCase):
    def test_no_infiere_conviccion_ni_barra_de_fe(self) -> None:
        texto = MUNDO.read_text(encoding="utf-8")

        self.assertIn("ReligionEventos.CANAL_EXPOSICION", texto)
        self.assertIn("ReligionEventos.CANAL_PRACTICA", texto)
        self.assertNotIn("ReligionEventos.CANAL_CONVICCION", texto)
        self.assertNotIn('"fe":', texto)
        self.assertNotIn('"religion":', texto)

    def test_calendario_tiene_fuente_interna_y_no_usa_assets_externos(self) -> None:
        mundo = MUNDO.read_text(encoding="utf-8")
        escena = MUNDO_3D.read_text(encoding="utf-8")

        self.assertIn('"fuente": "calendario:tablon_comunitario_98"', mundo)
        self.assertIn("const DIA_ACTO_MEMORIA := 3", mundo)
        self.assertIn("BoxMesh.new()", escena)
        self.assertNotIn("res://assets/", escena)

    def test_practica_es_interaccion_3d_y_no_menu(self) -> None:
        escena = MUNDO_3D.read_text(encoding="utf-8")

        self.assertIn("Interactuable3D.Verbo.USAR", escena)
        self.assertIn("practica_interactuable", escena)
        for simbolo in ("CanvasLayer", "Popup", "Window", "Button.new()"):
            self.assertNotIn(simbolo, escena)

    def test_regresion_runtime_standalone(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")

        with tempfile.TemporaryDirectory(prefix="religion-934-") as temporal:
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
                    str(RAIZ / "godot"),
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
        self.assertRegex(resultado.stdout, r"\d+ pasadas, 0 fallos")


if __name__ == "__main__":
    unittest.main()
