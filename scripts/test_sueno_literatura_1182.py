from pathlib import Path
import json
import os
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SUENO_LITERATURA = ROOT / "godot" / "guion" / "sueno_literatura.gd"
DIA = ROOT / "godot" / "guion" / "dia_app.gd"
CATALOGO = ROOT / "godot" / "datos" / "literatura_obras.json"
TEST_GODOT = "res://pruebas/pruebas_sueno_literatura_1182.gd"


class SuenoLiteratura1182Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.modulo = SUENO_LITERATURA.read_text(encoding="utf-8")
        cls.dia = DIA.read_text(encoding="utf-8")
        cls.catalogo = json.loads(CATALOGO.read_text(encoding="utf-8"))

    def test_consumidor_usa_solo_insight_literario(self) -> None:
        self.assertIn("LiteraturaEventos.CANAL_INSIGHT", self.modulo)
        self.assertIn('insight_id != String(lectura.get("insight_id", ""))', self.modulo)
        for forbidden in ("pistas_descubiertas", "veredictos", "contenido.casos", "leido_hoy"):
            self.assertNotIn(forbidden, self.modulo)

    def test_no_reselecciona_la_noche(self) -> None:
        self.assertNotIn("Sueno.noche(", self.modulo)
        tramo = self.dia.split("func _espacio_de", 1)[1].split("\n\nfunc ", 1)[0]
        self.assertIn(". aplicar(", tramo)
        self.assertLess(tramo.index("Sueno.espacio("), tramo.index("SuenoLiteratura"))

    def test_catalogo_declara_motivos_no_hechos(self) -> None:
        obra = self.catalogo["obras"][0]
        sueno = obra["sueno"]
        self.assertEqual(sueno["consumidor"], "sueno_literario")
        self.assertEqual(set(sueno["motivos"]), {"umbral", "doble"})
        serializado = json.dumps(sueno, ensure_ascii=False)
        self.assertNotIn("pista", serializado.lower())
        self.assertNotIn("sospechoso", serializado.lower())
        self.assertNotIn("expediente", serializado.lower())

    def test_godot_contract(self) -> None:
        engine = os.environ.get("GODOT_BIN", "godot4")
        with tempfile.TemporaryDirectory(prefix="sueno-literatura-1182-") as tmp:
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
