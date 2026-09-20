"""Regresión del primer vertical ideológico fuera de Tarot (#924/#920)."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODELO = ROOT / "godot" / "guion" / "decision_ideologica_expediente.gd"
PRUEBA_GODOT = "res://pruebas/issue_924_smoke.gd"


class DecisionIdeologica924Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.codigo = MODELO.read_text(encoding="utf-8")

    def test_reutiliza_el_contrato_transversal(self) -> None:
        self.assertIn("Prometeo.registrar_eleccion_ideologica", self.codigo)
        self.assertIn("Prometeo.registrar_lectura_social", self.codigo)
        self.assertIn('"fuente"', self.codigo)
        self.assertIn('"expediente"', self.codigo)

    def test_no_fuerza_una_matriz_de_cuatro_ejes(self) -> None:
        self.assertIn('"comunismo"', self.codigo)
        self.assertIn('"socialdemocrata"', self.codigo)
        self.assertIn('"centrista"', self.codigo)
        self.assertNotIn('"neoliberal"', self.codigo)

    def test_no_reescribe_hechos_ni_accede_a_host(self) -> None:
        self.assertNotIn('estado["veredictos"] =', self.codigo)
        self.assertNotIn('estado["pistas_descubiertas"] =', self.codigo)
        for prohibido in (
            "FileAccess",
            "DirAccess",
            "HTTPRequest",
            "HTTPClient",
            "OS.execute(",
            "OS.create_process(",
        ):
            self.assertNotIn(prohibido, self.codigo)

    def test_la_lectura_social_exige_evento_y_observador(self) -> None:
        self.assertIn('actual.get("observadores", {})', self.codigo)
        self.assertIn("if _evento(estado, evento_id).is_empty()", self.codigo)
        self.assertIn("opcion_registrada", self.codigo)

    def test_regresion_runtime_standalone(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")

        with tempfile.TemporaryDirectory(prefix="ideologia-924-") as temporal:
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
        self.assertRegex(resultado.stdout, r"issue_924: \d+ pasadas, 0 fallos")
        self.assertNotIn("Parse Error:", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
