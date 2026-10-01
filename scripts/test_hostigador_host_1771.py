import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
PRUEBA = ROOT / "godot" / "pruebas" / "pruebas_hostigador_host_1771.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_hostigador_host_1771.gd"


class HostigadorHost1771Test(unittest.TestCase):
    def test_prueba_versiona_su_uid(self) -> None:
        self.assertTrue(PRUEBA.with_name(PRUEBA.name + ".uid").is_file())

    def test_runtime_standalone(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")
        with tempfile.TemporaryDirectory(prefix="hostigador-host-1771-") as temporal:
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
