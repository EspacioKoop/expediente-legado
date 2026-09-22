import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


RAIZ = Path(__file__).resolve().parents[1]
JUICIO = RAIZ / "godot/guion/juicio_combate_3d.gd"
SIMBOLICO = RAIZ / "godot/guion/juicio_combate_simbolico.gd"
PRUEBA = RAIZ / "godot/pruebas/issue_936_combate_smoke.gd"
PRUEBA_GODOT = "res://pruebas/issue_936_combate_smoke.gd"


class JuicioCombateReligion936Test(unittest.TestCase):
    def test_combate_no_modela_credos_como_matchups(self) -> None:
        juicio = JUICIO.read_text(encoding="utf-8")
        simbolico = SIMBOLICO.read_text(encoding="utf-8")

        self.assertNotRegex(
            juicio,
            re.compile(r'"(?:dano|daño|resistencia|debilidad|bonus)[^"]*"\s*:.*religion', re.I),
        )
        self.assertNotIn("tradicion", juicio)
        self.assertNotIn("tradicion", simbolico)

    def test_capa_simbolica_consume_solo_el_contrato_ya_catalogado(self) -> None:
        simbolico = SIMBOLICO.read_text(encoding="utf-8")

        self.assertIn("RELIGION_CONFLICTO.compromisos_disponibles", simbolico)
        self.assertIn("RELIGION_EVENTOS.CLAVE_ESTADO", simbolico)

    def test_combate_base_sigue_intacto_sin_compromisos(self) -> None:
        juicio = JUICIO.read_text(encoding="utf-8")

        self.assertIn("compromiso_religion_bloqueante", juicio)
        self.assertIn("_rival_inicio_agresion", juicio)

    def test_regresion_runtime_standalone(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")

        with tempfile.TemporaryDirectory(prefix="juicio-religion-936-") as temporal:
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
                timeout=60,
                check=False,
            )

        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertRegex(resultado.stdout, r"\d+ pasadas, 0 fallos")
        self.assertTrue(PRUEBA.exists())


if __name__ == "__main__":
    unittest.main()
