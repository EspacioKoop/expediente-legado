import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
HOST = ROOT / "godot" / "guion" / "juicio_combate_3d.gd"
RUNTIME = ROOT / "godot" / "guion" / "juicio_combate_enjambre_runtime_1771.gd"
PRUEBA = ROOT / "godot" / "pruebas" / "pruebas_enjambre_host_2067.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_enjambre_host_2067.gd"


class EnjambreHost2067Test(unittest.TestCase):
    def test_host_conserva_margen_del_linter(self) -> None:
        self.assertLessEqual(len(HOST.read_text(encoding="utf-8").splitlines()), 1000)

    def test_runtime_no_crea_autoridad_de_progreso(self) -> None:
        fuente = RUNTIME.read_text(encoding="utf-8")
        for simbolo in ("Partida.", "Jornada.", "SuenoCombate.", "loot", "experiencia"):
            self.assertNotIn(simbolo, fuente)

    def test_uid_runtime_y_prueba_versionados(self) -> None:
        self.assertTrue(RUNTIME.with_name(RUNTIME.name + ".uid").is_file())
        self.assertTrue(PRUEBA.with_name(PRUEBA.name + ".uid").is_file())

    def test_runtime_godot(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")
        with tempfile.TemporaryDirectory(prefix="enjambre-host-2067-") as temporal:
            entorno = os.environ.copy()
            for variable, carpeta in (
                ("XDG_DATA_HOME", "datos"),
                ("XDG_CONFIG_HOME", "config"),
                ("XDG_CACHE_HOME", "cache"),
            ):
                entorno[variable] = str(Path(temporal) / carpeta)
            resultado = subprocess.run(
                [motor, "--headless", "--path", str(ROOT / "godot"), "--script", PRUEBA_GODOT],
                env=entorno,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=90,
                check=False,
            )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn(" 0 fallos", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
