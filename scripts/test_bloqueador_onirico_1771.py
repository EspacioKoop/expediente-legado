import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
ADAPTADOR = ROOT / "godot" / "guion" / "juicio_combate_arquetipo_host.gd"
PRUEBA_GODOT = "res://pruebas/pruebas_bloqueador_onirico_1771.gd"


class BloqueadorOnirico1771Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.adaptador = ADAPTADOR.read_text(encoding="utf-8")

    def test_guion_versiona_su_uid(self) -> None:
        self.assertTrue(ADAPTADOR.with_name(ADAPTADOR.name + ".uid").is_file())

    def test_traduce_la_politica_existente_sin_duplicarla(self) -> None:
        self.assertIn('preload("res://guion/juicio_combate_arquetipos.gd")', self.adaptador)
        # Los estados y duraciones siguen siendo de la política de #1820.
        self.assertNotRegex(self.adaptador, r"const\s+(GUARDIA|APERTURA|RECUPERAR)\b")
        self.assertNotIn("BLOQUEADOR_GUARDIA_MAX", self.adaptador)

    def test_es_puro_y_no_resuelve_consecuencias(self) -> None:
        for termino in (
            "Partida",
            "Jornada",
            "SuenoCombate",
            "determinacion",
            "add_child",
            "Sonido.",
            "Input.",
        ):
            self.assertNotIn(termino, self.adaptador)

    def test_solo_el_sueno_recibe_arquetipo(self) -> None:
        self.assertRegex(
            self.adaptador,
            r"plano\s*!=\s*CombateContextual\.PLANO_SUENO",
        )
        self.assertNotIn("PLANO_REALIDAD", self.adaptador)

    def test_declara_los_dos_cuerpos_soportados(self) -> None:
        soportados = re.search(r"const SOPORTADOS := \[(.*?)\]", self.adaptador, re.S)
        self.assertIsNotNone(soportados)
        declarados = {parte.strip() for parte in soportados.group(1).split(",")}
        self.assertEqual(
            declarados,
            {"ARQUETIPOS.BLOQUEADOR", "ARQUETIPOS.HOSTIGADOR"},
        )
        self.assertNotIn("ARQUETIPOS.ENJAMBRE", declarados)

    def test_runtime_standalone(self) -> None:
        motor = os.environ.get("GODOT_BIN") or shutil.which("godot4")
        if not motor:
            self.skipTest("Godot no disponible en este entorno")
        with tempfile.TemporaryDirectory(prefix="bloqueador-1771-") as temporal:
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
                timeout=60,
                check=False,
            )
        self.assertEqual(resultado.returncode, 0, resultado.stdout)
        self.assertIn(" 0 fallos", resultado.stdout)
        self.assertNotIn("SCRIPT ERROR:", resultado.stdout)
        self.assertNotIn("Parse Error:", resultado.stdout)


if __name__ == "__main__":
    unittest.main()
