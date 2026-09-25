import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


RAIZ = Path(__file__).resolve().parents[1]
JUICIO = RAIZ / "godot/guion/juicio_combate_3d.gd"
ESTADO = RAIZ / "godot/guion/juicio_combate_estado_temporal.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_juicio_estado_temporal_1191.gd"


class JuicioEstadoTemporal1191Test(unittest.TestCase):
    def test_controlador_delega_el_estado_sin_romper_campos_historicos(self) -> None:
        juicio = JUICIO.read_text(encoding="utf-8")
        estado = ESTADO.read_text(encoding="utf-8")

        self.assertIn(
            'preload("res://guion/juicio_combate_estado_temporal.gd")',
            juicio,
        )
        self.assertIn("var _estado_temporal := ESTADO_TEMPORAL.new()", juicio)
        for nombre in ("_recarga_jugador", "_esquiva", "_enredo"):
            self.assertIn(f"var {nombre}: float:", juicio)

        for nombre in (
            "recarga_rival",
            "invulnerabilidad_jungiana",
            "sacudida_camara",
            "aviso_jungiano",
            "doctrina",
        ):
            self.assertIn(f"_estado_temporal.{nombre}", juicio)

        self.assertIn("func descontar(delta: float) -> Array:", estado)
        self.assertIn("REGLAS.descontar_temporizadores", estado.replace("\n", ""))

    def test_regresion_runtime_standalone(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")

        with tempfile.TemporaryDirectory(prefix="juicio-estado-1191-") as temporal:
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
        self.assertRegex(resultado.stdout, r"estado_temporal_1191: \d+ pasadas, 0 fallos")


if __name__ == "__main__":
    unittest.main()
