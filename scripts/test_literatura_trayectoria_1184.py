from pathlib import Path
import os
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
EVENTOS = ROOT / "godot" / "guion" / "literatura_eventos.gd"
TRAYECTORIA = ROOT / "godot" / "guion" / "literatura_trayectoria.gd"
PARTIDA = ROOT / "godot" / "guion" / "partida.gd"
GESTOR = ROOT / "godot" / "literatura" / "gestor_literatura.gd"
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
DOC = ROOT / "docs" / "literatura-trayectoria-1184.md"
TEST_GODOT = "res://pruebas/pruebas_literatura_trayectoria_1184.gd"


class LiteraturaTrayectoria1184Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.eventos = EVENTOS.read_text(encoding="utf-8")
        cls.trayectoria = TRAYECTORIA.read_text(encoding="utf-8")
        cls.partida = PARTIDA.read_text(encoding="utf-8")
        cls.gestor = GESTOR.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_persistencia_es_de_partida(self):
        self.assertIn('CLAVE_ESTADO := "literatura"', self.eventos)
        self.assertIn("LiteraturaEventos.CLAVE_ESTADO: LiteraturaEventos.nuevo()", self.partida)
        self.assertIn("LiteraturaEventos.validar", self.partida)
        self.assertIn("LiteraturaEventos.asegurar_en_estado(fusionado)", self.partida)
        self.assertIn("vincular_a_estado", self.gestor)
        self.assertIn("_vincular_literatura_partida()", self.dia)

    def test_epilogo_no_crea_alignment(self):
        self.assertIn('"bloquea_final_base": false', self.trayectoria)
        self.assertIn('"final_base": final_base', self.trayectoria)
        self.assertNotIn("ganador", self.trayectoria)
        self.assertNotIn("puntuacion", self.trayectoria)
        self.assertNotIn("alignment", self.trayectoria.lower())

    def test_documenta_reset_y_pluralidad(self):
        self.assertIn("reasignación", self.doc)
        self.assertIn("partida nueva", self.doc)
        self.assertIn("pluralidad", self.doc)
        self.assertIn("procedencia", self.doc)
        self.assertIn("no bloquea", self.doc)

    def test_godot_contract(self):
        engine = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="literatura-1184-") as tmp:
            env = os.environ.copy()
            env["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for key in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                env[key] = str(Path(tmp) / key)
            result = subprocess.run(
                [engine, "--headless", "--language", "es", "--path", str(ROOT / "godot"), "--script", TEST_GODOT],
                env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=240, check=False,
            )
            self.assertEqual(result.returncode, 0, result.stdout)
            self.assertIn("0 fallos", result.stdout)


if __name__ == "__main__":
    unittest.main()
