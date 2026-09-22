from pathlib import Path
import json
import os
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
EVENTOS = ROOT / "godot" / "guion" / "literatura_eventos.gd"
CATALOGO_GD = ROOT / "godot" / "guion" / "literatura_catalogo.gd"
LECTURA = ROOT / "godot" / "guion" / "literatura_lectura.gd"
CATALOGO_JSON = ROOT / "godot" / "datos" / "literatura_obras.json"
DOC = ROOT / "docs" / "literatura-vertical-1175.md"
TEST_GODOT = "res://pruebas/pruebas_literatura_1175.gd"


class Literatura1175Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.eventos = EVENTOS.read_text(encoding="utf-8")
        cls.catalogo_gd = CATALOGO_GD.read_text(encoding="utf-8")
        cls.lectura = LECTURA.read_text(encoding="utf-8")
        cls.catalogo = json.loads(CATALOGO_JSON.read_text(encoding="utf-8"))
        cls.doc = DOC.read_text(encoding="utf-8")

    def test_canales_no_colapsan_conocimiento_y_posesion(self) -> None:
        self.assertIn('CANAL_CONOCIMIENTO := "conocimiento"', self.eventos)
        self.assertIn('CANAL_POSESION := "posesion"', self.eventos)
        self.assertIn('CANAL_INSIGHT := "insight"', self.eventos)
        self.assertIn('CANAL_RITUAL := "ritual"', self.eventos)
        self.assertIn("for canal in CANALES", self.eventos)
        self.assertIn("obra_conocida", self.eventos)
        self.assertIn("obra_poseida", self.eventos)

    def test_catalogo_es_data_driven_y_declara_rom(self) -> None:
        self.assertEqual(self.catalogo["version"], 1)
        obra = self.catalogo["obras"][0]
        for key in (
            "id",
            "titulo",
            "autor",
            "epoca",
            "generos",
            "fuente_documental",
            "lectura",
            "rom",
            "efecto_juego",
        ):
            self.assertIn(key, obra)
        self.assertEqual(obra["rom"]["estado"], "propuesta")
        self.assertEqual(obra["rom"]["desbloqueo"], "conocimiento")
        self.assertTrue(obra["rom"]["handshake_requerido"])
        self.assertEqual(obra["efecto_juego"]["tipo"], "modificador_contextual")

    def test_catalogo_godot_valida_estructura(self) -> None:
        self.assertIn("JSON.parse_string", self.catalogo_gd)
        self.assertIn("FileAccess.get_file_as_string", self.catalogo_gd)
        self.assertIn("obra_valida", self.catalogo_gd)
        self.assertIn("umbral_conocimiento", self.catalogo_gd)
        self.assertIn("consumidores", self.catalogo_gd)

    def test_lectura_parcial_no_registra_y_relectura_es_idempotente(self) -> None:
        self.assertIn('resultado["motivo"] = "lectura_incompleta"', self.lectura)
        self.assertIn('"conocimiento:obra:%s"', self.lectura)
        self.assertIn('"insight:obra:%s:%s"', self.lectura)
        self.assertIn("CANAL_CONOCIMIENTO", self.lectura)
        self.assertIn("CANAL_INSIGHT", self.lectura)
        self.assertNotIn("CANAL_POSESION", self.lectura)

    def test_efecto_no_se_aplica_desde_el_catalogo(self) -> None:
        texto = json.dumps(self.catalogo, ensure_ascii=False)
        self.assertNotIn('"dinero"', texto)
        self.assertNotIn('"pista_siga"', texto)
        self.assertNotIn('"progreso_siga"', texto)
        self.assertIn("no aplica", self.catalogo["schema"]["nota"])
        self.assertIn("consumidor", self.catalogo["obras"][0]["efecto_juego"]["descripcion"])

    def test_documentacion_fija_fronteras(self) -> None:
        self.assertIn("conocimiento ≠ posesión", self.doc)
        self.assertIn("No escribe en `Partida`", self.doc)
        self.assertIn("Tarot/Prometeo", self.doc)
        self.assertIn("momentum", self.doc)
        self.assertIn("arquetipos", self.doc)
        self.assertIn("#1176", self.doc)

    def test_godot_contract(self) -> None:
        engine = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="literatura-1175-") as tmp:
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
