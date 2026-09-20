import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


RAIZ = Path(__file__).resolve().parents[1]
EVENTOS = RAIZ / "godot/guion/religion_eventos.gd"
CONFLICTO = RAIZ / "godot/guion/religion_conflicto.gd"
PRUEBA = RAIZ / "godot/pruebas/pruebas_religion_conflicto_936.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_religion_conflicto_936.gd"


class ReligionConflicto936Test(unittest.TestCase):
    def test_contrato_no_modela_credos_como_matchups(self) -> None:
        conflicto = CONFLICTO.read_text(encoding="utf-8")
        eventos = EVENTOS.read_text(encoding="utf-8")

        self.assertNotIn('get("tradicion"', conflicto)
        self.assertNotIn('["tradicion"]', conflicto)
        self.assertNotRegex(
            conflicto,
            re.compile(r'"(?:dano|daño|resistencia|debilidad|bonus)[^"]*"\s*:'),
        )
        self.assertNotIn('"fe":', eventos)
        self.assertNotIn('"religion":', eventos)

    def test_solo_practica_o_conviccion_pueden_crear_compromisos(self) -> None:
        conflicto = CONFLICTO.read_text(encoding="utf-8")

        self.assertIn("ReligionEventos.CANAL_PRACTICA", conflicto)
        self.assertIn("ReligionEventos.CANAL_CONVICCION", conflicto)
        self.assertNotIn("ReligionEventos.CANAL_EXPOSICION,", conflicto)
        self.assertNotIn("ReligionEventos.CANAL_VINCULO,", conflicto)
        self.assertIn('evento.get("publico", false)', conflicto)
        self.assertIn('evento.get("conocido_por", [])', conflicto)

    def test_corte_permanece_aislado_de_las_reservas_activas(self) -> None:
        prueba = PRUEBA.read_text(encoding="utf-8")
        conjunto = "\n".join(
            (
                EVENTOS.read_text(encoding="utf-8"),
                CONFLICTO.read_text(encoding="utf-8"),
                prueba,
            )
        )

        for simbolo in ("Prometeo", "JuicioCombate3D", "Historias.cargas"):
            self.assertNotIn(simbolo, conjunto)

    def test_regresion_runtime_standalone(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")

        with tempfile.TemporaryDirectory(prefix="religion-936-") as temporal:
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
