"""Contrato de integración runtime del lote administrativo Styloo (#223)."""
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "godot/guion/oficina_styloo_cc0.gd"
FALLBACK = ROOT / "godot/guion/oficina_assets_cc0.gd"
MANIFEST = ROOT / "docs/assets/school-classrooms-styloo.manifest.json"


class OficinaStylooCc0Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.runtime = RUNTIME.read_text(encoding="utf-8")
        cls.fallback = FALLBACK.read_text(encoding="utf-8")
        cls.manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))

    def test_runtime_cubre_exactamente_lote_administrativo(self):
        por_id = {asset["id"]: asset for asset in self.manifest["assets"]}
        lote = self.manifest["lotes"]["administrativo"]
        self.assertEqual(
            lote,
            ["desk", "principal_chair", "shelf", "telephone", "old_pc", "printer"],
        )
        for asset_id in lote:
            stem = Path(por_id[asset_id]["destino_sugerido"]).stem
            self.assertIn(f'"styloo_school/{stem}"', self.runtime)

    def test_entrada_es_atomica_y_conserva_fallback(self):
        self.assertIn("static func disponible() -> bool:", self.runtime)
        self.assertIn("for nombre in MODELOS.values():", self.runtime)
        self.assertIn("if not Modelos.hay(String(nombre)):", self.runtime)
        self.assertIn("if not disponible():", self.runtime)
        self.assertLess(
            self.fallback.index("OficinaStylooCc0.montar(mundo)"),
            self.fallback.index("for bulto in EspaciosCatalogo.OFICINA.bultos:"),
        )
        self.assertIn('"oficina_psx/" + modelo', self.fallback)

    def test_no_crea_fisica_paralela(self):
        self.assertNotIn("StaticBody3D.new()", self.runtime)
        self.assertNotIn("CollisionShape3D.new()", self.runtime)
        self.assertIn("AssetCc0.sustituir", self.runtime)

    def test_seis_piezas_tienen_uso_concreto(self):
        self.assertIn('"TorrePcStyloo"', self.runtime)
        self.assertIn('"PrinterStyloo"', self.runtime)
        self.assertIn('"TelefonoBase"', self.runtime)
        self.assertIn('_bulto_prioritario("desk")', self.runtime)
        self.assertIn('_bulto_prioritario("chairDesk")', self.runtime)
        self.assertIn('_bulto_prioritario("bookcaseClosed")', self.runtime)
        self.assertIn("sustituciones != MODELOS.size()", self.runtime)
        preflight = self.runtime.index("if escritorio == null")
        primera_sustitucion = self.runtime.index("AssetCc0.sustituir(escritorio")
        self.assertLess(preflight, primera_sustitucion)

    def test_no_depende_de_binarios_en_tiempo_de_parseo(self):
        self.assertNotIn("preload(\"res://assets/modelos/styloo_school", self.runtime)
        self.assertNotIn("load(\"res://assets/modelos/styloo_school", self.runtime)
        self.assertIn("Modelos.hay", self.runtime)

    def test_regresion_godot_sobre_escena_real(self):
        with tempfile.TemporaryDirectory(prefix="styloo-qa-") as temporal:
            env = os.environ.copy()
            env["LEGADO_PRUEBAS_AISLADAS"] = "1"
            for var in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
                env[var] = str(Path(temporal) / var)
            motor = env.get("GODOT_BIN", "godot4")
            for args in (
                ["--editor", "--import", "--quit"],
                ["--script", "res://pruebas/pruebas_oficina_styloo_cc0.gd"],
            ):
                resultado = subprocess.run(
                    [motor, "--headless", "--path", str(ROOT / "godot"), *args],
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    timeout=120,
                    check=False,
                )
                self.assertEqual(resultado.returncode, 0, resultado.stdout)
                self.assertNotRegex(resultado.stdout, r"SCRIPT ERROR:|Parse Error:")
            self.assertNotIn("ERROR:", resultado.stdout)
            self.assertRegex(resultado.stdout, re.compile(r"\\d+ pasadas, 0 fallos"))


if __name__ == "__main__":
    unittest.main()
