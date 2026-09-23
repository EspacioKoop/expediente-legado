from pathlib import Path
import os
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONFLICTO = ROOT / "godot" / "guion" / "literatura_conflicto.gd"
TEST_GODOT = "res://pruebas/pruebas_literatura_conflicto_1175.gd"


class LiteraturaConflicto1175Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.conflicto = CONFLICTO.read_text(encoding="utf-8")

    def test_consumidor_es_explicito_y_no_muta_autoloads(self) -> None:
        self.assertIn('CONSUMIDOR := "conflicto_literario"', self.conflicto)
        self.assertIn("COSTO_CITA_MOMENTUM := 30.0", self.conflicto)
        self.assertIn("CANAL_INSIGHT", self.conflicto)
        self.assertIn("CANAL_RITUAL", self.conflicto)
        self.assertIn('"duracion": "encuentro_actual"', self.conflicto)
        self.assertIn('"estado": "miedo"', self.conflicto)
        self.assertNotIn("GestorMomentum", self.conflicto)
        self.assertNotIn("GestorArquetipos", self.conflicto)
        self.assertNotIn("Partida", self.conflicto)

    def test_godot_ritual_contract(self) -> None:
        engine = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="literatura-conflicto-1175-") as tmp:
            env = os.environ.copy()
            env["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for key in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                env[key] = str(Path(tmp) / key)
            result = subprocess.run(
                [
                    engine,
                    "--headless",
                    "--language",
                    "es",
                    "--path",
                    str(ROOT / "godot"),
                    "--script",
                    TEST_GODOT,
                ],
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=240,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertIn("0 fallos", result.stdout)


if __name__ == "__main__":
    unittest.main()
