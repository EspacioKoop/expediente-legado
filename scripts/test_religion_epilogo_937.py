from pathlib import Path
import os
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
TRAYECTORIA = ROOT / "godot" / "guion" / "religion_trayectoria.gd"
EVENTOS = ROOT / "godot" / "guion" / "religion_eventos.gd"
DOC = ROOT / "docs" / "religion-epilogo-937.md"
TEST_GODOT = "res://pruebas/pruebas_religion_epilogo_937.gd"


class ReligionEpilogo937Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.trayectoria = TRAYECTORIA.read_text(encoding="utf-8")
        cls.eventos = EVENTOS.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_reutiliza_snapshot_canonico(self):
        self.assertIn('CLAVE_HISTORIAL := "historial_trayectorias_religiosas"', self.eventos)
        self.assertIn("ReligionEventos.CANAL_CONVICCION", self.trayectoria)
        self.assertIn("ReligionEventos.CANAL_PRACTICA", self.trayectoria)
        self.assertIn("ReligionEventos.CANAL_EXPOSICION", self.trayectoria)
        self.assertIn("ReligionEventos.CANAL_VINCULO", self.trayectoria)

    def test_epilogo_no_decide_ni_puntua(self):
        self.assertIn('"final_base": final_base', self.trayectoria)
        self.assertIn('"bloquea_final_base": false', self.trayectoria)
        self.assertIn('"requiere_citar_hechos": true', self.trayectoria)
        codigo = self.trayectoria.lower()
        for clave_prohibida in (
            '"puntuacion":',
            '"ranking":',
            '"ganador":',
            '"religion_dominante":',
        ):
            self.assertNotIn(clave_prohibida, codigo)

    def test_maximo_tres_modulos_y_procedencia(self):
        self.assertIn('MODULO_DECLARACIONES := "declaraciones"', self.trayectoria)
        self.assertIn(
            'MODULO_PRACTICAS_EXPOSICIONES := "practicas_exposiciones"',
            self.trayectoria,
        )
        self.assertIn('MODULO_VINCULOS := "vinculos"', self.trayectoria)
        self.assertIn('"hechos": hechos.duplicate(true)', self.trayectoria)
        self.assertIn("procedencia", self.doc.lower())
        self.assertIn("tres módulos", self.doc.lower())

    def test_documenta_ausencia_y_contradiccion(self):
        texto = self.doc.lower()
        self.assertIn("sin declaración", texto)
        self.assertIn("contradic", texto)
        self.assertIn("no bloquea", texto)
        self.assertIn("final base", texto)

    def test_godot_contract(self):
        engine = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="religion-epilogo-937-") as tmp:
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
