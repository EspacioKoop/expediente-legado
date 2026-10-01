import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
GUION = ROOT / "godot" / "guion"
PRUEBA = ROOT / "godot" / "pruebas" / "pruebas_bloqueador_host_1771.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_bloqueador_host_1771.gd"


class BloqueadorHost1771Test(unittest.TestCase):
    def test_prueba_versiona_su_uid(self) -> None:
        self.assertTrue(PRUEBA.with_name(PRUEBA.name + ".uid").is_file())

    def test_solo_el_host_contextual_asigna_arquetipo(self) -> None:
        # La ventanilla y cualquier otro JuicioCombate3D deben seguir clásicos:
        # el arquetipo llega únicamente desde el combate contextual del sueño.
        asignaciones = [
            ruta.name
            for ruta in GUION.rglob("*.gd")
            if re.search(r"\.arquetipo_onirico\s*=", ruta.read_text(encoding="utf-8"))
        ]
        self.assertEqual(asignaciones, ["dia_combate_contextual_app.gd"])

    def test_runtime_standalone(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")
        with tempfile.TemporaryDirectory(prefix="bloqueador-host-1771-") as temporal:
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
